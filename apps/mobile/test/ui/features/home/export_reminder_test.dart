import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mibu/data/repositories/app_lock_repository.dart';
import 'package:mibu/data/repositories/finance_repository.dart';
import 'package:mibu/domain/models/finance.dart';
import 'package:mibu/ui/core/clock.dart';

import '../../../lock_store.dart';

import 'package:mibu/ui/features/home/view_models/export_reminder.dart';

void main() {
  final start = DateTime(2026, 1, 1);
  test('14 day boundary', () {
    expect(
      exportReminderDue(
        start,
        start.add(const Duration(days: 14, seconds: -1)),
      ),
      false,
    );
    expect(exportReminderDue(start, start.add(const Duration(days: 14))), true);
    expect(exportReminderDue(start, start.add(const Duration(days: 15))), true);
  });
  test('empty data does not create a baseline', () async {
    final store = MemoryLockStore();
    final container = ProviderContainer(
      overrides: [
        lockStoreProvider.overrideWithValue(store),
        nowProvider.overrideWithValue(start),
        allTransactionsProvider.overrideWith((ref) => Stream.value([])),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(exportReminderProvider, (_, _) {});
    addTearDown(subscription.close);
    expect(await container.read(exportReminderProvider.future), false);
    expect(store.values, isEmpty);
  });

  test(
    'baseline survives restart and dismissal lasts only one session',
    () async {
      final store = MemoryLockStore();
      final entry = Transaction(
        id: '1',
        emoji: '',
        category: null,
        place: '',
        at: start,
        amount: 1,
      );
      ProviderContainer session(DateTime now) => ProviderContainer(
        overrides: [
          lockStoreProvider.overrideWithValue(store),
          nowProvider.overrideWithValue(now),
          allTransactionsProvider.overrideWith((ref) => Stream.value([entry])),
        ],
      );
      final first = session(start);
      final firstListener = first.listen(exportReminderProvider, (_, _) {});
      expect(await first.read(exportReminderProvider.future), false);
      expect(store.values[exportReminderKey], start.toIso8601String());
      firstListener.close();
      first.dispose();
      final second = session(start.add(const Duration(days: 14)));
      final secondListener = second.listen(exportReminderProvider, (_, _) {});
      expect(await second.read(exportReminderProvider.future), true);
      second.read(exportReminderDismissedProvider.notifier).dismiss();
      expect(await second.read(exportReminderProvider.future), false);
      secondListener.close();
      second.dispose();
      final third = session(start.add(const Duration(days: 14)));
      final thirdListener = third.listen(exportReminderProvider, (_, _) {});
      expect(await third.read(exportReminderProvider.future), true);
      thirdListener.close();
      third.dispose();
    },
  );
}
