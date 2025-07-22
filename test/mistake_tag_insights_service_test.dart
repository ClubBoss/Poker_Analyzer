import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/mistake_tag.dart';
import 'package:poker_analyzer/models/training_spot_attempt.dart';
import 'package:poker_analyzer/models/evaluation_result.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/mistake_tag_history_service.dart';
import 'package:poker_analyzer/services/mistake_tag_insights_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TrainingSpotAttempt attempt({
    required String user,
    required String correct,
    double ev = 1.0,
    HeroPosition pos = HeroPosition.btn,
  }) {
    final spot = TrainingPackSpot(
      id: 's',
      hand: HandData(position: pos, stacks: {'0': 15}),
      evalResult: EvaluationResult(
        correct: false,
        expectedAction: correct,
        userEquity: 0,
        expectedEquity: 0,
      ),
    );
    return TrainingSpotAttempt(
      spot: spot,
      userAction: user,
      correctAction: correct,
      evDiff: ev,
    );
  }

  test('insights sorted by frequency', () async {
    SharedPreferences.setMockInitialValues({});
    final history = MistakeTagHistoryService();
    await history.load();
    await history.record([
      MistakeTag.overfoldBtn,
    ], attempt(user: 'fold', correct: 'push', ev: 2));
    await history.record([
      MistakeTag.overfoldBtn,
    ], attempt(user: 'fold', correct: 'push', ev: 1));
    await history.record([
      MistakeTag.looseCallBb,
    ], attempt(user: 'call', correct: 'fold', ev: -1));

    final service = MistakeTagInsightsService(history: history);
    final result = await service.generate();
    expect(result.first.tag, MistakeTag.overfoldBtn);
    expect(result.first.count, 2);
  });

  test('insights sorted by ev loss', () async {
    SharedPreferences.setMockInitialValues({});
    final history = MistakeTagHistoryService();
    await history.load();
    await history.record([
      MistakeTag.overfoldBtn,
    ], attempt(user: 'fold', correct: 'push', ev: 1));
    await history.record([
      MistakeTag.looseCallBb,
    ], attempt(user: 'call', correct: 'fold', ev: -5));

    final service = MistakeTagInsightsService(history: history);
    final result = await service.generate(sortByEvLoss: true);
    expect(result.first.tag, MistakeTag.looseCallBb);
  });
}
