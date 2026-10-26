import 'package:flutter_test/flutter_test.dart';
import 'package:folio/helpers/celebration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => NameDay.load());

  test('finds a name day from the second name part', () {
    expect(NameDay.isNameDay(['Botond'], DateTime(2026, 5, 16)), isTrue);
    expect(NameDay.isNameDay(['Botond'], DateTime(2026, 5, 17)), isFalse);
    expect(NameDay.isNameDay(['Hanna', 'Zoé'], DateTime(2026, 5, 2)), isTrue);
    // Only the main name day counts (Botond: May 16, not Jul 28).
    expect(NameDay.isNameDay(['Botond'], DateTime(2026, 7, 28)), isFalse);
  });

  test('leap year shifts Feb 24-28 name days by one', () {
    expect(NameDay.isNameDay(['Mátyás'], DateTime(2026, 2, 24)), isTrue);
    expect(NameDay.isNameDay(['Mátyás'], DateTime(2028, 2, 24)), isFalse);
    expect(NameDay.isNameDay(['Mátyás'], DateTime(2028, 2, 25)), isTrue);
  });

  test('unknown name is never a name day', () {
    expect(NameDay.isNameDay(['Xyzzy'], DateTime(2026, 5, 16)), isFalse);
  });
}
