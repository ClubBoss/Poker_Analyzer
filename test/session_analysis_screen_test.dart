import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/screens/session_analysis_screen.dart';
import 'package:poker_analyzer/screens/training_session_screen.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/mistake_review_pack_service.dart';
import 'package:poker_analyzer/services/template_storage_service.dart';
import 'package:poker_analyzer/services/session_note_service.dart';
import 'package:poker_analyzer/services/saved_hand_storage_service.dart';
import 'package:poker_analyzer/services/saved_hand_manager_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/saved_hand.dart';
import 'package:poker_analyzer/models/player_model.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/services/evaluation_executor_service.dart';

class _FakeExecutor extends EvaluationExecutorService {
  @override
  Future<void> evaluateSingle(
    BuildContext context,
    TrainingPackSpot spot, {
    TrainingPackTemplate? template,
    int anteBb = 0,
    EvaluationMode mode = EvaluationMode.ev,
    SavedHand? hand,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mistake pack button launches training and keeps note', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final templateService = TemplateStorageService();
    final manager = SavedHandManagerService(storage: SavedHandStorageService());
    final review = MistakeReviewPackService(hands: manager);
    final training = TrainingSessionService();
    final notes = SessionNoteService();
    final spot = TrainingPackSpot(
      id: 's1',
      hand: HandData.fromSimpleInput('AA', HeroPosition.sb, 10),
    );
    final tpl = TrainingPackTemplate(id: 't1', name: 't1', spots: [spot]);
    templateService.addTemplate(tpl);
    await review.addPack([spot.id], templateId: tpl.id);
    final hand = SavedHand(
      name: 'h1',
      heroIndex: 0,
      heroPosition: 'BTN',
      numberOfPlayers: 2,
      playerCards: const [[], []],
      boardCards: const [],
      boardStreet: 0,
      actions: const [],
      stackSizes: const {0: 100, 1: 100},
      playerPositions: const {0: 'BTN', 1: 'BB'},
      playerTypes: const {0: PlayerType.unknown, 1: PlayerType.unknown},
      sessionId: 1,
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: templateService),
          ChangeNotifierProvider.value(value: review),
          ChangeNotifierProvider.value(value: training),
          ChangeNotifierProvider.value(value: notes),
          ChangeNotifierProvider.value(value: manager),
          Provider<EvaluationExecutorService>(create: (_) => _FakeExecutor()),
        ],
        child: MaterialApp(home: SessionAnalysisScreen(hands: [hand])),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'note');
    await tester.pump();
    await tester.tap(find.text('Train Mistakes'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingSessionScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('note'), findsOneWidget);
  });
}
