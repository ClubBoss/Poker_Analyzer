import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/saved_hand_storage_service.dart';
import 'package:poker_analyzer/models/saved_hand.dart';
import 'package:poker_analyzer/models/card_model.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/player_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saved hand service persists hands', () async {
    SharedPreferences.setMockInitialValues({});
    final service = SavedHandStorageService();
    await service.load();
    final hand = SavedHand(
      name: 'Test',
      heroIndex: 0,
      heroPosition: 'BTN',
      numberOfPlayers: 2,
      playerCards: [
        [CardModel(rank: 'A', suit: '♠'), CardModel(rank: 'K', suit: '♦')],
        [],
      ],
      boardCards: [],
      boardStreet: 0,
      actions: [ActionEntry(0, 0, 'call')],
      stackSizes: {0: 100, 1: 100},
      playerPositions: {0: 'BTN', 1: 'BB'},
      playerTypes: {0: PlayerType.unknown, 1: PlayerType.unknown},
    );
    await service.add(hand);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('saved_hands');
    expect(raw, isNotNull);
    final loadedService = SavedHandStorageService();
    await loadedService.load();
    expect(loadedService.hands.length, 1);
    expect(loadedService.hands.first.name, 'Test');
  });
}
