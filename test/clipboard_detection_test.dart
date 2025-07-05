import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/utils/clipboard_hh_detector.dart';

void main() {
  group('Clipboard HH detection', () {
    test('Detects English marker', () {
      expect(containsPokerHistoryMarkers('*** HOLE CARDS ***'), isTrue);
    });

    test('Detects PokerStars header', () {
      expect(containsPokerHistoryMarkers('PokerStars Hand #123456'), isTrue);
    });

    test('Detects Russian marker', () {
      expect(containsPokerHistoryMarkers('*** Карманные карты ***'), isTrue);
    });

    test('Ignores random text', () {
      expect(containsPokerHistoryMarkers('Hello world'), isFalse);
    });
  });
}
