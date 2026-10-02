import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/domain/emoji_catalog.dart';
import 'package:mibu/ui/core/widgets/app_emoji.dart';

void main() {
  String norm(String e) => e.replaceAll('\u{FE0F}', '');
  final catalog = {for (final c in emojiCatalog) norm(c.emoji)};

  test('every catalog icon has bundled Fluent 3D art, and nothing else is', () {
    final missing = [
      for (final c in emojiCatalog)
        if (!File(AppEmoji.asset(c.emoji)).existsSync()) c.emoji,
    ];
    expect(missing, isEmpty, reason: 'run python3 tool/emoji/fetch.py');
    final bundled = Directory('assets/emoji')
        .listSync()
        .where((f) => f.path.endsWith('.webp'))
        .length;
    expect(bundled, emojiCatalog.length);
  });

  test('catalog has no duplicates', () {
    expect(catalog, hasLength(emojiCatalog.length));
  });

  test('every emoji literal in lib/ is a catalog icon', () {
    final stray = <String>{
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            !f.path.contains('/l10n/') &&
            !f.path.endsWith('emoji_catalog.dart'))
          for (final m in RegExp(
            r"'([^'\n]{1,8})'",
          ).allMatches(f.readAsStringSync()))
            if (m[1]!.runes.any(
                  (r) =>
                      (r >= 0x1F000 && r <= 0x1FAFF) ||
                      (r >= 0x2600 && r <= 0x27BF),
                ) &&
                !RegExp('[A-Za-z0-9 ]').hasMatch(m[1]!) &&
                !catalog.contains(norm(m[1]!)))
              m[1]!,
    };
    expect(stray, isEmpty, reason: 'add them to emoji_catalog.dart');
  });

  test('asset key drops the FE0F variation selector', () {
    expect(AppEmoji.asset('✈️'), 'assets/emoji/2708.webp');
    expect(catalogEmoji('✈️'), '✈️');
    expect(catalogEmoji('🦖'), fallbackEmoji); // not in the catalog
  });

  testWidgets('outside the catalog shows the fallback art, not a font glyph', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AppEmoji('🦖', size: 30),
      ),
    );
    final img = tester.widget<Image>(find.byType(Image));
    expect((img.image as AssetImage).assetName, AppEmoji.asset(fallbackEmoji));
    expect(find.text('🦖'), findsNothing);
  });
}
