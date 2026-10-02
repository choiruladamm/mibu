import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/ui/core/widgets/app_emoji.dart';
import 'package:mibu/ui/core/widgets/meta_line.dart';

/// A MetaLine showing exactly [parts] (dots between them).
Finder findMeta(List<String> parts) => find.byWidgetPredicate(
  (w) =>
      w is MetaLine &&
      w.spans.map((s) => s.toPlainText()).join('|') == parts.join('|'),
  description: 'MetaLine $parts',
);

/// An [EmojiText] showing exactly [text] (its emoji drawn as AppEmoji).
Finder findEmojiText(String text) => find.byWidgetPredicate(
  (w) => w is EmojiText && w.text == text,
  description: 'EmojiText "$text"',
);
