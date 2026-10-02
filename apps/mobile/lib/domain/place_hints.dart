/// Example places per category icon, for users with no history yet. Keyed by
/// emoji: names are typed freely, icons come from the catalog.
const _byEmoji = <String, List<String>>{
  '☕': ['kopi kenangan', 'fore'],
  '🍵': ['angkringan', 'warkop'],
  '🧋': ['chatime', 'mixue'],
  '🍚': ['warteg', 'warung padang'],
  '🍛': ['warung padang', 'warteg'],
  '🍜': ['warteg', 'gofood'],
  '🍽️': ['warteg', 'gofood'],
  '🍔': ['mcd', 'gofood'],
  '🍗': ['kfc', 'geprek bensu'],
  '🛵': ['gojek', 'grab'],
  '🚗': ['grab', 'parkiran'],
  '🚕': ['bluebird', 'grab'],
  '🚌': ['transjakarta', 'damri'],
  '🚆': ['krl', 'mrt'],
  '🚇': ['mrt', 'krl'],
  '✈️': ['traveloka', 'tiket.com'],
  '⛽': ['pertamina', 'shell'],
  '🅿️': ['parkiran mall', 'jukir'],
  '🛒': ['indomaret', 'alfamart'],
  '🛍️': ['shopee', 'tokopedia'],
  '📦': ['shopee', 'tokopedia'],
  '👕': ['uniqlo', 'shopee'],
  '🏠': ['kos', 'kontrakan'],
  '💡': ['pln', 'token listrik'],
  '💧': ['pdam', 'galon'],
  '📶': ['indihome', 'biznet'],
  '📱': ['telkomsel', 'xl'],
  '🎬': ['xxi', 'cgv'],
  '🎮': ['steam', 'playstation store'],
  '🎵': ['spotify', 'youtube music'],
  '🐱': ['petshop', 'dokter hewan'],
  '🐶': ['petshop', 'dokter hewan'],
  '🐾': ['petshop', 'dokter hewan'],
  '💊': ['apotek k24', 'kimia farma'],
  '🏥': ['klinik', 'rumah sakit'],
  '💇': ['barbershop', 'salon'],
  '🏋️': ['gym', 'fitness first'],
  '📚': ['gramedia', 'shopee'],
  '🎁': ['shopee', 'tokopedia'],
  '🤲': ['masjid', 'kitabisa'],
  '💼': ['kantor', 'klien'],
  '💰': ['kantor', 'klien'],
  '💻': ['klien', 'upwork'],
};

/// Examples for the "di mana" hint (03.2 / 04.4): the user's own latest
/// places for this category first, then the icon's defaults; null = generic.
List<String>? placeExamples(String? emoji, Iterable<String> recent) {
  final own = recent.toSet().take(2).toList();
  if (own.isNotEmpty) return own;
  return emoji == null ? null : _byNorm[_norm(emoji)];
}

String _norm(String e) => e.replaceAll('\u{FE0F}', '');

final _byNorm = {for (final e in _byEmoji.entries) _norm(e.key): e.value};
