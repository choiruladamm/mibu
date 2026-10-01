import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/ui/core/money.dart';

void main() {
  test('rupiah: titik ribuan, tanpa desimal', () {
    expect(rupiah(4530000), 'Rp4.530.000');
    expect(rupiah(50000), 'Rp50.000');
    expect(rupiah(0), 'Rp0');
    expect(rupiah(-450000), '-Rp450.000');
  });

  test('rupiahCompact: K / jt sesuai contoh board', () {
    expect(rupiahCompact(500), 'Rp500');
    expect(rupiahCompact(6700), 'Rp6,7K');
    expect(rupiahCompact(28000), 'Rp28K');
    expect(rupiahCompact(186000), 'Rp186K');
    expect(rupiahCompact(580000), 'Rp580K');
    expect(rupiahCompact(387272), 'Rp387K'); // whole K from 100K
    expect(rupiahCompact(99960), 'Rp100K');
    expect(rupiahCompact(12340), 'Rp12,3K');
    expect(rupiahCompact(-450000), '-Rp450K');
    expect(rupiahCompact(999960), 'Rp1jt');
    expect(rupiahCompact(1000000), 'Rp1jt');
    expect(rupiahCompact(1640000), 'Rp1,64jt');
    expect(rupiahCompact(4530000), 'Rp4,53jt');
    expect(rupiahCompact(8500000), 'Rp8,5jt');
    expect(rupiahCompact(42370000), 'Rp42,37jt');
  });
}
