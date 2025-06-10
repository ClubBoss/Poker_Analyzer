import 'package:flutter_test/flutter_test.dart';
import 'package:poker_ai_analyzer/helpers/date_utils.dart';

void main() {
  test('formatDateTime formats correctly', () {
    final d = DateTime(2023, 1, 2, 15, 30);
    expect(formatDateTime(d), '02.01.2023 15:30');
  });

  test('formatDate formats correctly', () {
    final d = DateTime(2023, 1, 2);
    expect(formatDate(d), '02.01.2023');
  });
}
