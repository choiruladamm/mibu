import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/core/widgets/pin_pad.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('id'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  late List<String> keys;
  var backspaces = 0, bios = 0;

  setUp(() {
    keys = [];
    backspaces = 0;
    bios = 0;
  });

  PinPad pad({
    int filled = 0,
    String message = '',
    bool error = false,
    PinPadState state = PinPadState.normal,
    PinBio bio = PinBio.none,
  }) => PinPad(
    filled: filled,
    message: message,
    error: error,
    state: state,
    bio: bio,
    onKey: keys.add,
    onBackspace: () => backspaces++,
    onBio: () => bios++,
  );

  Finder dots(bool on) => find.byWidgetPredicate((w) {
    final k = w.key;
    return k is ValueKey<String> && k.value.endsWith(on ? '-on' : '-off');
  });

  testWidgets('6 dots, filled ones follow the digits typed', (tester) async {
    await tester.pumpWidget(_app(pad(filled: 2)));
    expect(dots(true), findsNWidgets(2));
    expect(dots(false), findsNWidgets(4));

    await tester.pumpWidget(_app(pad(filled: 6)));
    expect(dots(true), findsNWidgets(6));
    expect(dots(false), findsNothing);
  });

  testWidgets('digits and backspace report to the parent', (tester) async {
    await tester.pumpWidget(_app(pad()));
    for (final d in ['4', '8', '0']) {
      await tester.tap(find.text(d));
    }
    expect(keys, ['4', '8', '0']);

    final handle = tester.ensureSemantics();
    await tester.tap(find.bySemanticsLabel('hapus satu angka'));
    expect(backspaces, 1);
    handle.dispose();
  });

  testWidgets('the message shows under the dots', (tester) async {
    await tester.pumpWidget(
      _app(pad(message: 'pin salah · 2× lagi sebelum ditahan sebentar')),
    );
    expect(find.text('pin salah · 2× lagi sebelum ditahan sebentar'), findsOne);
  });

  testWidgets('the pad is announced with how many digits are in', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(pad(filled: 3)));
    expect(find.bySemanticsLabel('masukin pin, 3 dari 6 angka'), findsOne);
    handle.dispose();
  });

  testWidgets('an error shakes the dots and settles', (tester) async {
    await tester.pumpWidget(_app(pad(filled: 6)));
    await tester.pumpWidget(_app(pad(error: true, message: 'pin salah')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('pin salah'), findsOne);
  });

  group('biometric key', () {
    testWidgets('face id: shown and wired', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(pad(bio: PinBio.face)));
      await tester.tap(find.bySemanticsLabel('pakai face id'));
      expect(bios, 1);
      handle.dispose();
    });

    testWidgets('sidik jari: its own label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(pad(bio: PinBio.finger)));
      expect(find.bySemanticsLabel('pakai sidik jari'), findsOne);
      expect(find.bySemanticsLabel('pakai face id'), findsNothing);
      handle.dispose();
    });

    testWidgets('none and bioHidden leave the slot empty', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(pad()));
      expect(find.bySemanticsLabel('pakai face id'), findsNothing);
      await tester.pumpWidget(
        _app(pad(bio: PinBio.face, state: PinPadState.bioHidden)),
      );
      expect(find.bySemanticsLabel('pakai face id'), findsNothing);
      handle.dispose();
    });
  });

  testWidgets('locked: digits and backspace dead, biometric still works', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(pad(state: PinPadState.locked, bio: PinBio.face)),
    );
    await tester.tap(find.text('5'));
    await tester.tap(find.bySemanticsLabel('hapus satu angka'));
    expect(keys, isEmpty);
    expect(backspaces, 0);

    await tester.tap(find.bySemanticsLabel('pakai face id'));
    expect(bios, 1);

    final opacity = tester.widget<Opacity>(
      find.ancestor(of: find.text('5'), matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, 0.35);
    handle.dispose();
  });
}
