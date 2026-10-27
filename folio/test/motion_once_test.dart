import 'package:flutter_test/flutter_test.dart';
import 'package:folio/helpers/motion_once.dart';

void main() {
  setUp(MotionOnce.reset);

  test('plays only the first time per key', () {
    expect(MotionOnce.shouldPlay('a'), isTrue);
    expect(MotionOnce.shouldPlay('a'), isFalse);
    expect(MotionOnce.shouldPlay('b'), isTrue);
  });

  test('reset allows playing again', () {
    MotionOnce.shouldPlay('a');
    MotionOnce.reset();
    expect(MotionOnce.shouldPlay('a'), isTrue);
  });
}
