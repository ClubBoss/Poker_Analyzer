import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/helpers/hand_history_parsing.dart';
import 'package:poker_analyzer/models/card_model.dart';

void main() {
  group('parseCard', () {
    test('parses valid tokens', () {
      expect(parseCard('Ah'), isA<CardModel>());
      expect(parseCard('Td')?.rank, 'T');
      expect(parseCard('7c')?.suit, '♣');
    });

    test('returns null for invalid tokens', () {
      expect(parseCard(''), isNull);
      expect(parseCard('Xx'), isNull);
    });
  });
}
