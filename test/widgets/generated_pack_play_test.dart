import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/screens/v2/training_pack_template_list_screen.dart';
import 'package:poker_analyzer/services/training_spot_storage_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/screens/training_session_screen.dart';
import 'package:poker_analyzer/models/training_spot.dart';
import 'package:poker_analyzer/models/card_model.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/player_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTrainingSpotService extends TrainingSpotStorageService {
  _FakeTrainingSpotService(this.spots) : super();
  final List<TrainingSpot> spots;
  @override
  Future<List<TrainingSpot>> load() async => spots;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('history play opens training session', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final spot = TrainingSpot(
      playerCards: [
        [CardModel(rank: 'A', suit: '♠'), CardModel(rank: 'K', suit: '♦')],
        [CardModel(rank: 'Q', suit: '♠'), CardModel(rank: 'J', suit: '♣')],
      ],
      boardCards: const [],
      actions: const [ActionEntry(0, 0, 'push')],
      heroIndex: 0,
      numberOfPlayers: 2,
      playerTypes: const [PlayerType.unknown, PlayerType.unknown],
      positions: const ['SB', 'BB'],
      stacks: const [10, 10],
      tags: const ['favorite'],
    );
    final service = _FakeTrainingSpotService([spot]);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TrainingSpotStorageService>.value(
              value: service),
          ChangeNotifierProvider(create: (_) => TrainingSessionService()),
        ],
        child: const MaterialApp(home: TrainingPackTemplateListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorites Pack'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recent Generated Packs'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingSessionScreen), findsOneWidget);
  });
}
