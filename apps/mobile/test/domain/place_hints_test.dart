import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/domain/place_hints.dart';

void main() {
  test('own places first, latest 2 distinct', () {
    expect(placeExamples('☕', ['fore', 'fore', 'janji jiwa', 'tuku']), [
      'fore',
      'janji jiwa',
    ]);
  });

  test('no history → icon defaults, variation selector ignored', () {
    expect(placeExamples('🛵', []), ['gojek', 'grab']);
    expect(placeExamples('✈', []), placeExamples('✈️', []));
    expect(placeExamples('✈', []), isNotNull);
  });

  test('unknown icon or no category → null (generic hint)', () {
    expect(placeExamples('🦑', []), isNull);
    expect(placeExamples(null, []), isNull);
  });
}
