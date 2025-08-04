import 'package:test/test.dart';
import 'package:poker_analyzer/services/room_hand_history_importer.dart';

void main() {
  group('RoomHandHistoryImporter', () {
    test('parses pokerstars text into hands', () async {
      final importer = await RoomHandHistoryImporter.create();
      final text = [
        "PokerStars Hand #1: Hold'em No Limit (\$0.01/\$0.02 USD) - 2023/01/01 00:00:00 ET",
        "Table 'Alpha' 6-max Seat #1 is the button",
        'Seat 1: Player1 (\$1 in chips)',
        'Seat 2: Player2 (\$1 in chips)',
        '*** HOLE CARDS ***',
        'Dealt to Player1 [Ah Kh]',
        'Player1: raises 2 to 2',
        'Player2: folds',
        '*** SUMMARY ***',
        '',
        "PokerStars Hand #2: Hold'em No Limit (\$0.01/\$0.02 USD) - 2023/01/01 00:01:00 ET",
        "Table 'Beta' 6-max Seat #1 is the button",
        'Seat 1: Hero (\$1 in chips)',
        'Seat 2: Villain (\$1 in chips)',
        '*** HOLE CARDS ***',
        'Dealt to Hero [Qs Qd]',
        'Hero: raises 4 to 4',
        'Villain: folds',
        '*** SUMMARY ***',
      ].join('\n');

      final hands = importer.parse(text);
      expect(hands, hasLength(2));
      expect(hands.first.name, '1');
      expect(hands.first.comment, 'Alpha');
      expect(hands.last.name, '2');
      expect(hands.last.comment, 'Beta');
    });
  });
}
