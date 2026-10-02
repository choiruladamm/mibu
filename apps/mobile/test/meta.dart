import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/ui/core/widgets/meta_line.dart';

/// A MetaLine showing exactly [parts] (dots between them).
Finder findMeta(List<String> parts) => find.byWidgetPredicate(
  (w) =>
      w is MetaLine &&
      w.spans.map((s) => s.toPlainText()).join('|') == parts.join('|'),
  description: 'MetaLine $parts',
);
