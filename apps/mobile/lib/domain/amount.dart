// Rupiah keypad input (00.17 AmountKeypad) and spelled-out amounts.

/// What's typed so far: finished [parts] (via "+") and the [digits] being
/// typed. Whole rupiah.
typedef AmountDraft = ({List<int> parts, String digits});

const AmountDraft emptyDraft = (parts: [], digits: '');

int draftTotal(AmountDraft d) =>
    d.parts.fold(0, (a, b) => a + b) + (int.tryParse(d.digits) ?? 0);

bool draftIsEmpty(AmountDraft d) => d.parts.isEmpty && d.digits.isEmpty;

/// [key] is '0'–'9', '00', '000' or '+'. Digits only, no leading zeros, and
/// the total stays within [maxDigits]; a key that would break that is a no-op.
/// '+' parks the current amount as a part (nothing typed = no-op).
AmountDraft draftPress(AmountDraft d, String key, {int maxDigits = 10}) {
  if (key == '+') {
    final v = int.tryParse(d.digits) ?? 0;
    return v == 0 ? d : (parts: [...d.parts, v], digits: '');
  }
  final next = '${d.digits}$key'.replaceFirst(RegExp('^0+'), '');
  final draft = (parts: d.parts, digits: next);
  return '${draftTotal(draft)}'.length > maxDigits ? d : draft;
}

/// ⌫: drops a digit; with nothing typed, reopens the last part.
AmountDraft draftBack(AmountDraft d) {
  if (d.digits.isNotEmpty) {
    return (parts: d.parts, digits: d.digits.substring(0, d.digits.length - 1));
  }
  if (d.parts.isEmpty) return d;
  return (
    parts: d.parts.sublist(0, d.parts.length - 1),
    digits: '${d.parts.last}',
  );
}

const _ones = [
  '',
  'satu',
  'dua',
  'tiga',
  'empat',
  'lima',
  'enam',
  'tujuh',
  'delapan',
  'sembilan',
  'sepuluh',
  'sebelas',
];

/// 1250000 → "satu juta dua ratus lima puluh ribu". 0 → "nol".
String terbilang(int n) {
  if (n == 0) return 'nol';
  String say(int n) {
    String join(String head, int rest) =>
        rest == 0 ? head : '$head ${say(rest)}';
    if (n < 12) return _ones[n];
    if (n < 20) return '${say(n - 10)} belas';
    if (n < 100) return join('${say(n ~/ 10)} puluh', n % 10);
    if (n < 200) return join('seratus', n - 100);
    if (n < 1000) return join('${say(n ~/ 100)} ratus', n % 100);
    if (n < 2000) return join('seribu', n - 1000);
    if (n < 1000000) return join('${say(n ~/ 1000)} ribu', n % 1000);
    if (n < 1000000000) return join('${say(n ~/ 1000000)} juta', n % 1000000);
    if (n < 1000000000000) {
      return join('${say(n ~/ 1000000000)} miliar', n % 1000000000);
    }
    return join('${say(n ~/ 1000000000000)} triliun', n % 1000000000000);
  }

  return n < 0 ? 'minus ${say(-n)}' : say(n);
}
