import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/ui/core/money.dart';

void main() {
  test('maskAmount keeps sign and Rp, hides digits, K and jt', () {
    expect(maskAmount('Rp4.530.000'), 'Rp•••');
    expect(maskAmount('Rp4,53jt'), 'Rp•••');
    expect(maskAmount('-Rp450K'), '-Rp•••');
    expect(maskAmount('+Rp6,7K'), '+Rp•••');
  });

  testWidgets('context formatters follow AmountMask, plain without one', (
    tester,
  ) async {
    Widget probe(bool? hidden) {
      final text = Builder(
        builder: (c) => Text(
          '${c.rpCompact(-450000)}|${c.rp(4530000)}',
          textDirection: TextDirection.ltr,
        ),
      );
      return hidden == null ? text : AmountMask(hidden: hidden, child: text);
    }

    await tester.pumpWidget(probe(null));
    expect(find.text('-Rp450K|Rp4.530.000'), findsOneWidget);
    await tester.pumpWidget(probe(false));
    expect(find.text('-Rp450K|Rp4.530.000'), findsOneWidget);
    await tester.pumpWidget(probe(true));
    expect(find.text('-Rp•••|Rp•••'), findsOneWidget);
  });
}
