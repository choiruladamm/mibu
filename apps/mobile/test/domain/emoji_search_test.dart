import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/domain/emoji_search.dart';

void main() {
  List<String> top(String q, [int n = 3]) =>
      searchEmoji(q).take(n).map((c) => c.emoji).toList();

  test('search: exact keyword first, then prefix, slang included', () {
    expect(top('kopi').first, '☕');
    expect(top('ojol').first, '🛵');
    expect(top('bensin').first, '⛽');
    expect(top('KOS').first, '🏢');
    expect(top('celeng').first, '🐷'); // celengan, by prefix
    expect(top('cel'), containsAll(['👖', '🐷'])); // celana, celengan
    expect(
      searchEmoji('motor').map((c) => c.emoji),
      containsAll(['🛵', '🏍️']),
    );
  });

  test('search: every word has to fit; retry suggests the one that does', () {
    expect(searchEmoji('mobil listrik'), isEmpty);
    expect(emojiRetry('mobil listrik'), 'mobil');
    expect(emojiRetry('zzz qqq'), isNull);
    expect(emojiRetry('mobil'), isNull); // one word: nothing to drop
    expect(searchEmoji('es teh').first.emoji, '🧋');
    expect(searchEmoji('  '), isEmpty);
  });

  test('suggest: any word of the name counts; padded to 3', () {
    expect(suggestEmoji('Kopi Susu').first, '☕');
    expect(suggestEmoji('makan siang').first, '🍜');
    expect(suggestEmoji('zakat').first, '🤲');
    expect(suggestEmoji('qwerty'), ['✨', '🧾', '📦']);
    expect(suggestEmoji('kucing'), hasLength(3));
  });
}
