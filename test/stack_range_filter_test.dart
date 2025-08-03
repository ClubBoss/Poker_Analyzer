import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/utils/stack_range_filter.dart';

void main() {
  group('StackRangeFilter', () {
    test('handles plus notation', () {
      final filter = StackRangeFilter('10+');
      expect(filter.matches(9), isFalse);
      expect(filter.matches(10), isTrue);
      expect(filter.matches(20), isTrue);
    });

    test('handles range notation', () {
      final filter = StackRangeFilter('5-10');
      expect(filter.matches(4), isFalse);
      expect(filter.matches(5), isTrue);
      expect(filter.matches(10), isTrue);
      expect(filter.matches(11), isFalse);
    });

    test('invalid ranges are ignored', () {
      expect(StackRangeFilter('-5+').matches(0), isTrue);
      expect(StackRangeFilter('10-5').matches(7), isTrue);
      expect(StackRangeFilter('5--10').matches(7), isTrue);
    });
  });
}
