import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/amount.dart';
import '../../../../domain/models/finance.dart';
import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../core/widgets/note_sheet.dart';
import '../../../core/finance_providers.dart';

class AddEntryState {
  const AddEntryState({
    required this.kind,
    required this.day,
    this.draft = emptyDraft,
    this.category,
    this.place = '',
    this.note = (text: '', tags: const []),
    this.suggested = false,
  });

  final CategoryKind kind;
  final DateTime day; // date-only
  final AmountDraft draft; // keypad input, "+" parts included
  final Category? category; // null = tanpa kategori
  final String place;
  final Note note;

  /// The amount is a suggestion (last gajian), not typed: shown muted, and
  /// the first key replaces it.
  final bool suggested;

  int get amount => draftTotal(draft);
  bool get canSave => amount > 0;

  AddEntryState copyWith({
    CategoryKind? kind,
    DateTime? day,
    AmountDraft? draft,
    Category? Function()? category,
    String? place,
    Note? note,
    bool? suggested,
  }) => AddEntryState(
    kind: kind ?? this.kind,
    day: day ?? this.day,
    draft: draft ?? this.draft,
    category: category != null ? category() : this.category,
    place: place ?? this.place,
    note: note ?? this.note,
    suggested: suggested ?? this.suggested,
  );
}

/// 03.1 catat.
class AddEntry extends Notifier<AddEntryState> {
  @override
  AddEntryState build() => AddEntryState(
    kind: CategoryKind.expense,
    day: dateOnly(ref.read(clockProvider)()),
  );

  void setKind(CategoryKind kind) => state = state.copyWith(
    kind: kind,
    // Income categories only show for income and vice versa.
    category: state.category?.kind == kind ? null : () => null,
    // A gajian suggestion makes no sense under the other kind.
    draft: state.suggested && kind != state.kind ? emptyDraft : null,
    suggested: state.suggested && kind == state.kind,
  );

  void press(String key) => state = state.copyWith(
    // A suggestion is replaced by the first digit; "+" builds on it.
    draft: draftPress(
      state.suggested && key != '+' ? emptyDraft : state.draft,
      key,
    ),
    suggested: false,
  );

  void backspace() =>
      state = state.copyWith(draft: draftBack(state.draft), suggested: false);

  void clear() => state = state.copyWith(draft: emptyDraft, suggested: false);

  /// Beranda "catat gajian": a pemasukan under the gajian category, the last
  /// salary as the amount to change.
  Future<void> startSalary() async {
    final repo = ref.read(financeRepositoryProvider);
    final cats = await repo
        .watchCategories(ref.read(currentPeriodProvider))
        .first;
    final last = await repo.lastSalary();
    state = state.copyWith(
      kind: CategoryKind.income,
      category: () => cats.where((c) => c.isPayday).firstOrNull,
      draft: last == null ? emptyDraft : (parts: const [], digits: '$last'),
      suggested: last != null,
    );
  }

  void pickDay(DateTime day) => state = state.copyWith(day: dateOnly(day));

  void pick(RecentPick p) =>
      state = state.copyWith(category: () => p.category, place: p.place);

  void setNote(Note note) => state = state.copyWith(note: note);

  /// "catat lagi": same kind, category and place; amount and day stay fresh.
  Future<void> again(Transaction t) async {
    final cats = await ref
        .read(financeRepositoryProvider)
        .watchCategories(ref.read(currentPeriodProvider))
        .first;
    state = state.copyWith(
      kind: t.kind,
      category: () => cats.where((c) => c.id == t.categoryId).firstOrNull,
      place: t.place,
    );
  }

  Future<void> save() async {
    final s = state;
    if (!s.canSave) return;
    final now = ref.read(clockProvider)();
    // Past day: keep the time of day so entries stay in logging order.
    final at = DateTime(
      s.day.year,
      s.day.month,
      s.day.day,
      now.hour,
      now.minute,
      now.second,
    );
    await ref
        .read(financeRepositoryProvider)
        .addTransaction(
          amount: s.kind == CategoryKind.expense ? -s.amount : s.amount,
          categoryId: s.category?.id,
          place: s.place,
          note: s.note.text,
          tags: s.note.tags,
          at: at,
        );
  }
}

final addEntryProvider = NotifierProvider.autoDispose<AddEntry, AddEntryState>(
  AddEntry.new,
);
