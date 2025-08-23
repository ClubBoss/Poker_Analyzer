import 'package:test/test.dart';
import 'package:poker_analyzer/utils/stack_range_filter.dart';

void main() {
  group('StackRangeFilter', () {
    test('null matches all', () {
      final filter = StackRangeFilter(null);
      expect(filter.matches(0), isTrue);
      expect(filter.matches(100), isTrue);
    });

    test('parses plus notation', () {
      final filter = StackRangeFilter('15+');
      expect(filter.matches(14), isFalse);
      expect(filter.matches(15), isTrue);
      expect(filter.matches(30), isTrue);
    });

    test('parses range notation', () {
      final filter = StackRangeFilter('10-20');
      expect(filter.matches(9), isFalse);
      expect(filter.matches(10), isTrue);
      expect(filter.matches(20), isTrue);
      expect(filter.matches(21), isFalse);
    });

    test('invalid range ignored', () {
      final filter = StackRangeFilter('20-10');
      expect(filter.matches(5), isTrue);
    });

    test('negative range ignored', () {
      final filter = StackRangeFilter('-5-10');
      expect(filter.matches(7), isTrue);
    });
  });
}

