@TestOn('vm')
import 'package:test/test.dart';
import 'package:poker_analyzer/utils/math_utils.dart'; // любая pure-функция

void main() {
  test('clampInt works (smoke)', () {
    expect(clampInt(12, min: 0, max: 10), 10); // замените на вашу функцию
  });
}
