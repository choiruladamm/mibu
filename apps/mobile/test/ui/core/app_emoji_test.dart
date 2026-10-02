import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/ui/core/widgets/app_emoji.dart';

void main() {
  // Same scan as tool/emoji/fetch.py: every emoji literal in lib/.
  final emoji = <String>{
    for (final f in Directory('lib').listSync(recursive: true))
      if (f is File && f.path.endsWith('.dart') && !f.path.contains('/l10n/'))
        for (final m in RegExp(
          r"'([^'\n]{1,8})'",
        ).allMatches(f.readAsStringSync()))
          if (m[1]!.runes.any(
                (r) =>
                    (r >= 0x1F000 && r <= 0x1FAFF) ||
                    (r >= 0x2600 && r <= 0x27BF),
              ) &&
              !RegExp('[A-Za-z0-9 ]').hasMatch(m[1]!))
            m[1]!,
  };

  test('every emoji the app uses has bundled Fluent 3D art', () {
    expect(emoji, isNotEmpty);
    final missing = [
      for (final e in emoji)
        if (!File(AppEmoji.asset(e)).existsSync()) e,
    ];
    expect(missing, isEmpty, reason: 'run python3 tool/emoji/fetch.py');
  });

  test('asset key drops the FE0F variation selector', () {
    expect(AppEmoji.asset('✈️'), 'assets/emoji/2708.png');
    expect(AppEmoji.asset('🐶'), 'assets/emoji/1f436.png');
  });

  testWidgets('unknown emoji falls back to the platform font', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AppEmoji('🦖', size: 30),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('🦖'), findsOneWidget);
  });
}
