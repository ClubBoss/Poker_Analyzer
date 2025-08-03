import 'package:flutter_test/flutter_test.dart';

import 'package:poker_analyzer/helpers/action_utils.dart';
import 'package:poker_analyzer/models/action_entry.dart';

void main() {
  test('ActionEntryX identifies hero and opponent', () {
    final action = ActionEntry(0, 1, 'call');

    expect(action.isHero(1), isTrue);
    expect(action.isHero(0), isFalse);
    expect(action.isOpponent(1), isFalse);
    expect(action.isOpponent(0), isTrue);
  });

  test('ActionEntryListX filters opponent actions', () {
    final actions = [
      ActionEntry(0, 0, 'fold'),
      ActionEntry(0, 1, 'call'),
      ActionEntry(0, 2, 'raise'),
    ];

    final filtered = actions.againstHero(1);

    expect(filtered.length, 2);
    expect(filtered.every((a) => a.playerIndex != 1), isTrue);
  });
}

