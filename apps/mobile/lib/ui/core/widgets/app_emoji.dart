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

/// Catalog emoji (longest first, so ZWJ sequences win) or any stray emoji
/// block glyph; arrows and symbols in copy (↑ ↓ × ²) are left alone.
final _emojiRun = RegExp(
  [
    for (final e in [
      for (final c in emojiCatalog) c.emoji,
    ]..sort((a, b) => b.length.compareTo(a.length)))
      RegExp.escape(e),
    r'[\u{1F000}-\u{1FAFF}](?:\u{FE0F}|\u{200D}[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}]\u{FE0F}?)*',
  ].join('|'),
  unicode: true,
);

/// [text] with every emoji drawn as [AppEmoji] of [size], for copy like
/// "pakai 🍜 makan" or "🐶 60%".
List<InlineSpan> emojiSpans(String text, {required double size}) {
  final out = <InlineSpan>[];
  var at = 0;
  for (final m in _emojiRun.allMatches(text)) {
    if (m.start > at) out.add(TextSpan(text: text.substring(at, m.start)));
    out.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: AppEmoji(m[0]!, size: size),
      ),
    );
    at = m.end;
  }
  if (at < text.length) out.add(TextSpan(text: text.substring(at)));
  return out;
}

/// Inline emoji size for text of [fontSize] (board: 15 → 20, 17 → 24).
double inlineEmojiSize(double fontSize) => (fontSize * 1.35).roundToDouble();

/// [Text] whose emoji are [AppEmoji]; [emojiSize] defaults to
/// [inlineEmojiSize] of the style's font size.
class EmojiText extends StatelessWidget {
  const EmojiText(
    this.text, {
    super.key,
    this.style,
    this.emojiSize,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final double? emojiSize;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final size =
        emojiSize ??
        inlineEmojiSize(
          (style?.fontSize ?? DefaultTextStyle.of(context).style.fontSize) ??
              14,
        );
    return Text.rich(
      TextSpan(children: emojiSpans(text, size: size)),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      semanticsLabel: text,
    );
  }
}

/// Fluent Emoji is MIT: list it on the licenses page.
void registerEmojiLicense() => LicenseRegistry.addLicense(() async* {
  yield LicenseEntryWithLineBreaks(const [
    'Fluent Emoji',
  ], await rootBundle.loadString('assets/emoji/LICENSE'));
});
