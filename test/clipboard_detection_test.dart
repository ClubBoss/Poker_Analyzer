import 'package:flutter_test/flutter_test.dart';
import 'package:poker_ai_analyzer/screens/pack_editor_screen.dart';

void main() {
  group('Clipboard HH detection', () {
    test('Detects English marker', () {
      expect(_containsPokerHistoryMarkers('*** HOLE CARDS ***'), isTrue);
    });

    test('Detects PokerStars header', () {
      expect(_containsPokerHistoryMarkers('PokerStars Hand #123456'), isTrue);
    });

    test('Detects Russian marker', () {
      expect(_containsPokerHistoryMarkers('*** Карманные карты ***'), isTrue);
    });

    test('Ignores random text', () {
      expect(_containsPokerHistoryMarkers('Hello world'), isFalse);
    });
  });
}
