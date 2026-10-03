import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/core/widgets/toast.dart';

void main() {
  // Regression: moving to another screen rebuilt the toast in the new
  // Scaffold and replayed its entrance, a visible blink.
  testWidgets('toast keeps showing, no replayed entrance, on a new screen', (
    tester,
  ) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        theme: AppTheme.light,
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showToast(
                context,
                icon: ToastIcon.check,
                title: 'budget Rp8jt kesimpen',
                sub: 'budget di-track ulang',
              ),
              child: const Text('simpan'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('simpan'));
    await tester.pumpAndSettle();
    // The entrance is timed from when it showed (wall clock).
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );

    nav.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Scaffold()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final toast = find.text('budget Rp8jt kesimpen');
    expect(toast, findsOneWidget);
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: toast, matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, 1.0);
  });

  // Regression: the sub was one line + "…", so on a phone "berlaku mulai
  // jum 23 okt, periode ini selesai dulu" lost its end next to "batalin".
  testWidgets('toast sub wraps, never trails off', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const sub = 'berlaku mulai jum 23 okt, periode ini selesai dulu';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showToast(
                context,
                icon: ToastIcon.check,
                title: 'gajian jadi tgl 10',
                sub: sub,
                onUndo: () {},
              ),
              child: const Text('simpan'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('simpan'));
    await tester.pump(const Duration(milliseconds: 300));

    final p = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text(sub), matching: find.byType(RichText)),
    );
    expect(p.didExceedMaxLines, isFalse);
  });
}
