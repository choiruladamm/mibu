import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/add_entry/views/add_entry_view.dart';

import '../../../meta.dart';

void main() {
  testWidgets('03.3 from the picker: usage and the income note', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final now = DateTime(2026, 10, 14, 14, 50);
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
      () => now,
    );
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
          home: const AddEntryView(),
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
    await tester.tap(find.text('buat apa?'));
    await settle();
    await tester.tap(find.text('atur'));
    await settle();

    expect(find.text('buat apa aja'), findsOneWidget);
    expect(find.text('4 catatan'), findsOneWidget); // belanja, no limit
    expect(find.text('limit Rp1jt'), findsOneWidget); // anabul
    expect(find.text('3 catatan'), findsOneWidget); // gajian
    expect(
      find.text(
        'yang ada limit jadi toples di tab kantong. '
        'gajian itu pemasukan, nggak pernah dikasih limit.',
        findRichText: true,
      ),
      findsOneWidget,
    );

    expect(
      findMeta(['tap ikon = ganti ikon', 'tap nama = edit', 'tahan = geser']),
      findsOneWidget,
    );

    // Tap ikon → IconSheet → saved right away, toast batalin puts it back.
    Future<String> ngopi() async => (await (db.select(
      db.categories,
    )..where((c) => c.name.equals('ngopi'))).getSingle()).emoji;
    await tester.tap(find.bySemanticsLabel('ganti ikon ngopi'));
    await settle();
    await tester.tap(find.bySemanticsLabel('boba').first);
    await settle();
    await tester.tap(findEmojiText('pakai 🧋 boba'));
    await settle();
    expect(find.text('ikon ngopi diganti'), findsOneWidget);
    expect(find.text('buat apa aja'), findsOneWidget); // 03.3 stays open
    expect(await tester.runAsync(ngopi), '🧋');
    await tester.tap(find.text('batalin'));
    await settle();
    expect(await tester.runAsync(ngopi), '☕');

    // lain-lain: entries without a buat apa, locked in both modes.
    final loose = (await tester.runAsync(
      () => (db.select(
        db.transactions,
      )..where((t) => t.categoryId.isNull() & t.deletedAt.isNull())).get(),
    ))!.length;
    expect(find.text('lain-lain'), findsOneWidget);
    expect(
      find.text(loose == 0 ? 'belum kepake' : '$loose catatan'),
      findsWidgets,
    );
    expect(find.bySemanticsLabel('dikunci'), findsOneWidget);

    // Mode hapus 03.3d: − on each, gajian + lain-lain locked, no baru.
    await tester.tap(find.bySemanticsLabel('hapus buat apa'));
    await settle();
    expect(find.text('hapus yang mana?'), findsOneWidget);
    expect(
      findMeta(['tap − buat hapus', 'catatannya dipindahin dulu, nggak ilang']),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('hapus anabul'), findsOneWidget);
    expect(find.bySemanticsLabel('hapus gajian'), findsNothing);
    expect(find.bySemanticsLabel('dikunci'), findsNWidgets(2));
    expect(find.bySemanticsLabel('ganti ikon anabul'), findsNothing);
    expect(find.text('baru'), findsOneWidget); // only 03.2's, behind 03.3
    expect(
      find.textContaining('lain-lain & gajian nggak bisa dihapus'),
      findsOneWidget,
    );

    // tap − → 03.6, which stays open on top of 03.3.
    await tester.tap(find.bySemanticsLabel('hapus anabul'));
    await settle();
    expect(find.bySemanticsLabel('tahan buat hapus anabul'), findsOneWidget);
    await tester.tapAt(const Offset(195, 40)); // scrim: back to 03.3d
    await settle();
    expect(find.text('hapus yang mana?'), findsOneWidget);

    await tester.tap(find.text('selesai'));
    await settle();
    expect(find.text('buat apa aja'), findsOneWidget);
    expect(find.bySemanticsLabel('ganti ikon anabul'), findsOneWidget);
    expect(find.text('baru'), findsNWidgets(2)); // 03.3's + 03.2's

    // ponytail: tahan & geser is checked by hand on device; after a
    // simulated drag the next frame never returns under flutter_test.
    // Cover reorderCategories in the repo test; revisit the widget drag.

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
