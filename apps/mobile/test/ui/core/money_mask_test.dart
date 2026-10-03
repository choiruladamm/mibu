import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/domain/models/finance.dart';
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
    Widget probe(AmountMask Function(Widget)? mask) {
      final text = Builder(
        builder: (c) => Text(
          '${c.rpCompact(-450000)}|${c.rp(4530000, income: true)}',
          textDirection: TextDirection.ltr,
        ),
      );
      return mask == null ? text : mask(text);
    }

    AmountMask Function(Widget) mask(HideAmounts h, {bool peek = false}) =>
        (child) => AmountMask(hide: h, peek: peek, child: child);

    await tester.pumpWidget(probe(null));
    expect(find.text('-Rp450K|Rp4.530.000'), findsOneWidget);
    await tester.pumpWidget(probe(mask(HideAmounts.none)));
    expect(find.text('-Rp450K|Rp4.530.000'), findsOneWidget);
    // 99.5 pemasukan aja: only figures flagged income.
    await tester.pumpWidget(probe(mask(HideAmounts.income)));
    expect(find.text('-Rp450K|Rp•••'), findsOneWidget);
    await tester.pumpWidget(probe(mask(HideAmounts.all)));
    expect(find.text('-Rp•••|Rp•••'), findsOneWidget);
    await tester.pumpWidget(probe(mask(HideAmounts.all, peek: true)));
    expect(find.text('-Rp450K|Rp4.530.000'), findsOneWidget);
  });
}
