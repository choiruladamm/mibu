import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/domain/models/finance.dart';
import 'package:mibu/ui/features/transactions/view_models/transactions_view_model.dart';

void main() {
  test('drill filters exact identity, half-open span and actual expenses', () {
    Transaction tx(
      String id,
      DateTime at,
      String? categoryId, [
      int amount = -1,
    ]) => Transaction(
      id: id,
      emoji: '',
      category: 'same',
      categoryId: categoryId,
      place: '',
      at: at,
      amount: amount,
    );
    final rows = [
      tx('before', DateTime(2025, 12, 24), null),
      tx('start', DateTime(2025, 12, 25), null),
      tx('other', DateTime(2026, 1, 1), 'other'),
      tx('today', DateTime(2026, 1, 3, 23), null),
      tx('future', DateTime(2026, 1, 4), null),
      tx('end', DateTime(2026, 1, 25), null),
      tx('income', DateTime(2026, 1, 2), null, 1),
    ];
    final drill = (
      start: DateTime(2025, 12, 25),
      end: DateTime(2026, 1, 25),
      today: DateTime(2026, 1, 3),
      categoryOnly: true,
      categoryId: null,
      label: '',
    );
    expect(drillTransactions(rows, drill).map((t) => t.id), ['start', 'today']);
    expect(
      drillTransactions(rows, (
        start: drill.start,
        end: drill.end,
        today: drill.today,
        categoryOnly: true,
        categoryId: 'other',
        label: '',
      )).map((t) => t.id),
      ['other'],
    );
  });
}
