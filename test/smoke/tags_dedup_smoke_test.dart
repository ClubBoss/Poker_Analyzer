@TestOn('vm')
import 'package:test/test.dart';
import 'package:poker_analyzer/utils/tag_utils.dart'; // утилита без Flutter

void main() {
  test('Dedup tags keeps order (smoke)', () {
    final out = dedupTags([
      'icm',
      'preflop',
      'icm',
      'pushfold',
    ]); // замените на вашу функцию
    expect(out, ['icm', 'preflop', 'pushfold']);
  });
}
