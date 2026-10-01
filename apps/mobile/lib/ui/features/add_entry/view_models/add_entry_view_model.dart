import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../core/widgets/note_sheet.dart';

const amountMaxDigits = 10;

/// Keypad input: digits only, no leading zeros, at most [amountMaxDigits].
/// [key] is '0'–'9' or '000'; an over-long result keeps [digits] unchanged.
String pressKey(String digits, String key) {
  final next = '$digits$key'.replaceFirst(RegExp('^0+'), '');
  return next.length > amountMaxDigits ? digits : next;
}

class AddEntryState {
  const AddEntryState({
    required this.kind,
    required this.day,
    this.digits = '',
    this.category,
    this.place = '',
    this.note = (text: '', tags: const []),
  });

  final CategoryKind kind;
  final DateTime day; // date-only
  final String digits;
  final Category? category; // null = tanpa kategori
  final String place;
  final Note note;

  int get amount => int.tryParse(digits) ?? 0;
  bool get canSave => amount > 0;

  AddEntryState copyWith({
    CategoryKind? kind,
    DateTime? day,
    String? digits,
    Category? Function()? category,
    String? place,
    Note? note,
  }) => AddEntryState(
    kind: kind ?? this.kind,
    day: day ?? this.day,
    digits: digits ?? this.digits,
    category: category != null ? category() : this.category,
    place: place ?? this.place,
    note: note ?? this.note,
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
  );

  void press(String key) =>
      state = state.copyWith(digits: pressKey(state.digits, key));

  void backspace() => state = state.copyWith(
    digits: state.digits.isEmpty
        ? ''
        : state.digits.substring(0, state.digits.length - 1),
  );

  void pickDay(DateTime day) => state = state.copyWith(day: dateOnly(day));

  void pick(RecentPick p) =>
      state = state.copyWith(category: () => p.category, place: p.place);

  void setNote(Note note) => state = state.copyWith(note: note);

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
