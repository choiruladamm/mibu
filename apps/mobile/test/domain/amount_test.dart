import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/domain/amount.dart';

void main() {
  AmountDraft type(List<String> keys, {int maxDigits = 10}) {
    var d = emptyDraft;
    for (final k in keys) {
      d = draftPress(d, k, maxDigits: maxDigits);
    }
    return d;
  }

  test('digits: no leading zeros, 000 / 00, max digits on the total', () {
    expect(type(['0', '000']).digits, '');
    expect(type(['5', '000']).digits, '5000');
    expect(type(['5', '00'], maxDigits: 12).digits, '500');
    expect(
      type(['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']).digits,
      '1234567890',
    );
    expect(type([...'1234567890'.split(''), '1']).digits, '1234567890');
    expect(
      type(['1', '2', '3', '4', '5', '6', '7', '8', '000']).digits,
      '12345678',
    ); // would be 11 digits
    // 9.000.000.000 + 2.000.000.000 = 11 digits → last key ignored
    final big = type(['9', '000', '000', '000', '+', '2', '000', '000', '00']);
    expect(draftTotal(big), 9000000000 + 200000000);
  });

  test('+ parks the amount; ⌫ reopens the last part; total sums', () {
    var d = type(['5', '000', '+', '+', '2', '000']);
    expect(d.parts, [5000]); // second + with nothing typed is a no-op
    expect(draftTotal(d), 7000);

    d = draftBack(draftBack(draftBack(draftBack(d)))); // clears "2000"
    expect(d.parts, [5000]);
    expect(d.digits, '');
    d = draftBack(d);
    expect(d.parts, isEmpty);
    expect(d.digits, '5000');
    expect(draftIsEmpty(draftBack(emptyDraft)), isTrue);
  });

  test('terbilang', () {
    expect(terbilang(0), 'nol');
    expect(terbilang(11), 'sebelas');
    expect(terbilang(15), 'lima belas');
    expect(terbilang(100), 'seratus');
    expect(terbilang(1000), 'seribu');
    expect(terbilang(50000), 'lima puluh ribu');
    expect(terbilang(1250000), 'satu juta dua ratus lima puluh ribu');
    expect(terbilang(111111), 'seratus sebelas ribu seratus sebelas');
    expect(terbilang(2000000000), 'dua miliar');
    expect(terbilang(999999999999).startsWith('sembilan ratus'), isTrue);
  });
}
