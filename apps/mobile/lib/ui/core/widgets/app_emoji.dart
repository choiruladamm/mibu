import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Emoji drawn from the bundled Microsoft Fluent Emoji 3D set, so Android and
/// iOS look the same. Anything not bundled (an emoji from before a palette
/// change) falls back to the platform font. New palette / emojiIdeas emoji:
/// run `python3 tool/emoji/fetch.py`.
class AppEmoji extends StatelessWidget {
  const AppEmoji(this.emoji, {super.key, required this.size});

  final String emoji;
  final double size;

  /// `assets/emoji/<hex codepoints, no FE0F, "_"-joined>.png`
  static String asset(String emoji) =>
      'assets/emoji/${emoji.runes.where((r) => r != 0xFE0F).map((r) => r.toRadixString(16)).join('_')}.png';

  @override
  Widget build(BuildContext context) => Semantics(
    label: emoji,
    child: Image.asset(
      asset(emoji),
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => SizedBox.square(
        dimension: size,
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(fontSize: size * 0.85, height: 1),
          ),
        ),
      ),
    ),
  );
}

/// Fluent Emoji is MIT: list it on the licenses page.
void registerEmojiLicense() => LicenseRegistry.addLicense(() async* {
  yield LicenseEntryWithLineBreaks(const [
    'Fluent Emoji',
  ], await rootBundle.loadString('assets/emoji/LICENSE'));
});
