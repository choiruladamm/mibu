import 'package:flutter/material.dart';

import '../tokens.dart';
import 'app_emoji.dart';

/// 00.19 MetaLine — a 1-line metadata row ("petshop • 14:32") whose parts
/// are split by 3px round dots, never the "·" character. Screen readers
/// hear the parts joined by commas, not the dots. Section titles don't use
/// it (title left, info right).
class MetaLine extends StatelessWidget {
  /// Plain parts; empty ones are dropped.
  MetaLine(
    List<String> parts, {
    super.key,
    this.style,
    this.onInk = false,
    this.tight = false,
    this.textAlign,
    this.maxLines = 1,
  }) : spans = [
         for (final p in parts)
           if (p.isNotEmpty) TextSpan(text: p),
       ];

  /// Styled parts, e.g. a bold amount.
  const MetaLine.rich(
    this.spans, {
    super.key,
    this.style,
    this.onInk = false,
    this.tight = false,
    this.textAlign,
    this.maxLines = 1,
  });

  final List<InlineSpan> spans;
  final TextStyle? style;
  final bool onInk; // dot #737373 instead of #BDBDBD
  final bool tight; // 5 around the dot instead of 7
  final TextAlign? textAlign;
  final int? maxLines; // null = wraps (a toast's sub); 1 line + … otherwise

  /// [parts] with dots between, for a caller's own Text.rich.
  static List<InlineSpan> join(
    List<InlineSpan> parts, {
    bool onInk = false,
    bool tight = false,
  }) => [
    for (final (i, p) in parts.indexed) ...[
      if (i > 0) dot(onInk: onInk, tight: tight),
      p,
    ],
  ];

  static InlineSpan dot({bool onInk = false, bool tight = false}) => WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: ExcludeSemantics(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tight ? 5 : 7),
        child: Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: onInk ? AppColors.subtle : AppColors.onInkMuted,
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final size = inlineEmojiSize(
      (style?.fontSize ?? DefaultTextStyle.of(context).style.fontSize) ?? 14,
    );
    return Text.rich(
      TextSpan(
        children: join(
          [
            // Plain parts can carry a category emoji ("🍜 warteg").
            for (final s in spans)
              s is TextSpan && s.children == null && s.text != null
                  ? TextSpan(
                      style: s.style,
                      children: emojiSpans(s.text!, size: size),
                    )
                  : s,
          ],
          onInk: onInk,
          tight: tight,
        ),
      ),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      semanticsLabel: spans.map((s) => s.toPlainText()).join(', '),
    );
  }
}
