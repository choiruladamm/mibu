import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../domain/emoji_catalog.dart';

/// Every emoji in mibu: Microsoft Fluent Emoji 3D art bundled from
/// [emojiCatalog], so Android and iOS look the same. Never the phone's emoji
/// font; an emoji outside the catalog shows [fallbackEmoji]. After editing
/// the catalog run `python3 tool/emoji/fetch.py`.
class AppEmoji extends StatelessWidget {
  const AppEmoji(this.emoji, {super.key, required this.size});

  final String emoji;
  final double size;

  /// `assets/emoji/<hex codepoints, no FE0F, "_"-joined>.webp`
  static String asset(String emoji) =>
      'assets/emoji/${emoji.runes.where((r) => r != 0xFE0F).map((r) => r.toRadixString(16)).join('_')}.webp';

  @override
  Widget build(BuildContext context) => Semantics(
    label: emoji,
    child: Image.asset(
      asset(catalogEmoji(emoji)),
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    ),
  );
}

/// Fluent Emoji is MIT: list it on the licenses page.
void registerEmojiLicense() => LicenseRegistry.addLicense(() async* {
  yield LicenseEntryWithLineBreaks(const [
    'Fluent Emoji',
  ], await rootBundle.loadString('assets/emoji/LICENSE'));
});
