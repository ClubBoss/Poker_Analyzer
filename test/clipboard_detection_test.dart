import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/utils/clipboard_hh_detector.dart';

void main() {
  test('detect EN',
      () => expect(containsPokerHistoryMarkers('*** HOLE CARDS ***'), isTrue));
  test(
      'detect RU',
      () => expect(
          containsPokerHistoryMarkers('*** Карманные карты ***'), isTrue));
  test('ignore junk',
      () => expect(containsPokerHistoryMarkers('hello'), isFalse));
}
