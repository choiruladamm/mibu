import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/ui/core/clock.dart';

void main() {
  testWidgets('now refreshes at midnight while app remains open', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 14, 23, 59, 59);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clockProvider.overrideWithValue(() => now)],
        child: Consumer(
          builder: (context, ref, child) => Text(
            '${ref.watch(nowProvider).day}',
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
    expect(find.text('14'), findsOneWidget);
    now = DateTime(2026, 10, 15);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('15'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
