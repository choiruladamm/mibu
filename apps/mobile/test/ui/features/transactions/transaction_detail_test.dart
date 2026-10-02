import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/repositories/finance_repository.dart';
import 'package:mibu/domain/models/finance.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/add_entry/view_models/add_entry_view_model.dart';
import 'package:mibu/ui/features/transactions/views/transaction_detail_view.dart';

import '../../../meta.dart';

void main() {
  final now = DateTime(2026, 10, 14, 14, 50);
  late AppDatabase db;

  setUp(
    () => db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
      () => now,
    ),
  );

  Future<TransactionRow> petshop() => (db.select(
    db.transactions,
  )..where((t) => t.place.equals('petshop'))).getSingle();

  testWidgets('04.3: struk, pocket impact, hapus → dihapus → batalin', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final id = (await tester.runAsync(petshop))!.id;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TransactionDetailView(id: id),
        ),
      ),
    );
    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await settle();
    expect(find.text('petshop'), findsOneWidget);
    expect(find.text('sel 13 okt'), findsOneWidget);
    expect(findMeta(['sel 13 okt', '14.32']), findsOneWidget);
    expect(find.text('tambahin catatan'), findsOneWidget);
    expect(find.text('🐶 anabul'), findsOneWidget);
    expect(find.text('jatah sisa Rp100K dari limit Rp1jt'), findsOneWidget);
    expect(
      find.text('transaksi ini aja udah makan 45% jatah anabul.'),
      findsOneWidget,
    );

    // Cancel keeps it.
    await tester.tap(find.bySemanticsLabel('hapus catatan'));
    await settle();
    expect(
      find.text(
        '-Rp450.000 di petshop, sel 13 okt. tenang, abis ini masih bisa '
        'dibatalin.',
      ),
      findsOneWidget,
    );
    expect(find.text('balik jadi sisa Rp550K'), findsOneWidget);
    expect(find.text('sekarang 90% kepake'), findsOneWidget);
    expect(find.text('abis ini 45%'), findsOneWidget);
    await tester.tap(find.text('nggak jadi'));
    await settle();
    expect((await tester.runAsync(petshop))!.deletedAt, isNull);

    await tester.tap(find.bySemanticsLabel('hapus catatan'));
    await settle();
    await tester.tap(find.text('hapus'));
    await settle();
    expect((await tester.runAsync(petshop))!.deletedAt, isNotNull);
    expect(find.text('dihapus'), findsOneWidget);
    expect(find.text('balik ke transaksi'), findsOneWidget);
    expect(find.text('catatan dihapus'), findsOneWidget);
    expect(find.text('jatah anabul balik jadi sisa Rp550K'), findsOneWidget);

    await tester.tap(find.text('batalin'));
    await settle();
    expect((await tester.runAsync(petshop))!.deletedAt, isNull);
    expect(find.text('dihapus'), findsNothing);
    expect(find.text('catat lagi'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  test('catat lagi keeps kind, category and place', () async {
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await db.close();
    });
    final t = (await FinanceRepository(db)
        .watchTransaction((await petshop()).id)
        .first)!;
    c.listen(addEntryProvider, (_, _) {});
    await c.read(addEntryProvider.notifier).again(t);
    final s = c.read(addEntryProvider);
    expect(
      (s.kind, s.category?.name, s.place, s.amount),
      (CategoryKind.expense, 'anabul', 'petshop', 0),
    );
  });
}
