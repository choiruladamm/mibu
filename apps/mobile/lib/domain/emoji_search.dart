import 'emoji_catalog.dart';

List<String> _words(String s) => s
    .trim()
    .toLowerCase()
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .toList();

/// How well one typed word fits [c]: 3 = a keyword, 2 = starts a keyword,
/// 1 = inside one (3+ letters), 0 = no.
int _fit(CatalogEmoji c, String w) {
  var best = 0;
  for (final k in c.keywords) {
    final s = k == w
        ? 3
        : k.startsWith(w)
        ? 2
        : w.length >= 3 && k.contains(w)
        ? 1
        : 0;
    if (s > best) best = s;
  }
  return best;
}

List<CatalogEmoji> _ranked(Map<CatalogEmoji, int> score) {
  final order = {for (final (i, c) in emojiCatalog.indexed) c.emoji: i};
  return score.keys.toList()..sort(
    (a, b) => score[b] != score[a]
        ? score[b]!.compareTo(score[a]!)
        : order[a.emoji]!.compareTo(order[b.emoji]!),
  );
}

/// 00.20 cari ikon: icons whose keywords fit every typed word, best first.
List<CatalogEmoji> searchEmoji(String query) {
  final words = _words(query);
  if (words.isEmpty) return const [];
  final score = <CatalogEmoji, int>{};
  for (final c in emojiCatalog) {
    var total = 0;
    for (final w in words) {
      final f = _fit(c, w);
      if (f == 0) {
        total = 0;
        break;
      }
      total += f;
    }
    if (total > 0) score[c] = total;
  }
  return _ranked(score);
}

/// 00.20 nothing found: the first typed word that alone finds icons
/// ("mobil listrik" → "mobil"); null = none does.
String? emojiRetry(String query) {
  final words = _words(query);
  if (words.length < 2) return null;
  for (final w in words) {
    if (searchEmoji(w).isNotEmpty) return w;
  }
  return null;
}

/// 03.4 saran: [n] icons for a category name, any word counting
/// ("makan siang" → 🍜 …); padded with ✨ 🧾 📦.
List<String> suggestEmoji(String name, {int n = 3}) {
  final score = <CatalogEmoji, int>{};
  for (final w in _words(name)) {
    for (final c in emojiCatalog) {
      final f = _fit(c, w);
      if (f > 0) score[c] = (score[c] ?? 0) + f;
    }
  }
  final out = [for (final c in _ranked(score)) c.emoji];
  for (final e in const ['✨', '🧾', '📦']) {
    if (out.length >= n) break;
    if (!out.contains(e)) out.add(e);
  }
  return out.take(n).toList();
}
