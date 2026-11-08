import 'package:flutter_test/flutter_test.dart';
import 'package:folio/database/query.dart';

void main() {
  test('blank names saved by older versions mean "not renamed"', () {
    expect(
        decodeRenames('{"MAT":"Matek","T1":"","T2":"  "}'), {"MAT": "Matek"});
  });

  test('names are trimmed', () {
    expect(decodeRenames('{"MAT":"  Matek "}'), {"MAT": "Matek"});
  });

  test('nothing saved', () {
    expect(decodeRenames(null), isEmpty);
    expect(decodeRenames('{}'), isEmpty);
  });
}
