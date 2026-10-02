import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/ui/core/tokens.dart';
import 'package:mibu/ui/core/widgets/meta_line.dart';

void main() {
  Iterable<Color?> dots(WidgetTester tester) => tester
      .widgetList<Container>(find.byType(Container))
      .map((c) => (c.decoration as BoxDecoration?)?.color);

  testWidgets('dots between parts, empties dropped, read as commas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: MetaLine(['petshop', '', '14:32'])),
    );
    expect(dots(tester), [AppColors.onInkMuted]); // one dot, two parts
    expect(find.bySemanticsLabel('petshop, 14:32'), findsOneWidget);
    expect(find.textContaining('·'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(home: MetaLine(['a', 'b', 'c'], onInk: true)),
    );
    expect(dots(tester), [AppColors.subtle, AppColors.subtle]);
  });
}
