import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/database/seed.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/finance_providers.dart';
import 'package:mibu/ui/features/home/view_models/home_view_model.dart';

void main() {
  test('beranda chart moves to the new period once now is refreshed', () async {
    var clock = DateTime(2026, 10, 31, 9);
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
      () => clock,
      (_, _) async {},
    );
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => clock),
      ],
    );
    c.listen(homeMonthProvider, (_, _) {});

    // User browsed back to august.
    c.read(homeMonthProvider.notifier).select(DateTime(2026, 8));
    expect(c.read(homeMonthProvider).selected, DateTime(2026, 8));

    // The app stays open past the period; nothing changes until "now" does.
    clock = DateTime(2026, 11, 1, 9);
    expect(c.read(homeMonthProvider).selected, DateTime(2026, 8));

    c.invalidate(nowProvider);
    final pick = c.read(homeMonthProvider);
    expect(pick.selected, DateTime(2026, 11));
    expect(pick.start, DateTime(2026, 6)); // 6-period window ends on it

    c.dispose();
    await db.close();
  });

  test('payday 25 (weekend → Fri 23): new period starts on gajian', () async {
    var clock = DateTime(2026, 10, 22, 9);
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
      () => clock,
      seedDemo, // has the payday rule: gajian tgl 25
    );
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => clock),
      ],
    );
    c.listen(homeMonthProvider, (_, _) {});
    c.listen(profileProvider, (_, _) {});
    c.listen(periodRulesProvider, (_, _) {});
    await c.read(profileProvider.future);
    await c.read(periodRulesProvider.future);

    expect(c.read(homeMonthProvider).selected, DateTime(2026, 10));
    clock = DateTime(2026, 10, 23, 9);
    c.invalidate(nowProvider);
    expect(c.read(homeMonthProvider).selected, DateTime(2026, 11));

    c.dispose();
    await db.close();
  });
}
