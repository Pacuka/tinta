import 'package:flutter_test/flutter_test.dart';
import 'package:folio/utils/format.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('hu_HU'));

  final now = DateTime(2026, 10, 25, 23, 49); // vasárnap
  String label(DateTime d) => dateHeaderLabel(d, now, 'hu_HU',
      today: 'Ma', tomorrow: 'Holnap', yesterday: 'Tegnap');

  test('relative days keep their short names', () {
    expect(label(DateTime(2026, 10, 25)), 'Ma');
    expect(label(DateTime(2026, 10, 26)), 'Holnap');
    expect(label(DateTime(2026, 10, 24)), 'Tegnap');
  });

  test('other dates in the same year show weekday and date', () {
    expect(label(DateTime(2026, 11, 2)), 'Hétfő, nov. 2.');
    expect(label(DateTime(2026, 10, 17)), 'Szombat, okt. 17.');
  });

  test('month boundary: Oct 31 -> Nov 1 is tomorrow', () {
    final n = DateTime(2026, 10, 31, 12);
    expect(
        dateHeaderLabel(DateTime(2026, 11, 1), n, 'hu_HU',
            today: 'Ma', tomorrow: 'Holnap', yesterday: 'Tegnap'),
        'Holnap');
  });

  test('DST start night (Mar 28 -> Mar 29) is still tomorrow', () {
    expect(
        dateHeaderLabel(DateTime(2026, 3, 29), DateTime(2026, 3, 28, 22),
            'hu_HU',
            today: 'Ma', tomorrow: 'Holnap', yesterday: 'Tegnap'),
        'Holnap');
  });

  test('other year shows full date', () {
    expect(label(DateTime(2025, 3, 4)), '2025. márc. 4.');
  });
}
