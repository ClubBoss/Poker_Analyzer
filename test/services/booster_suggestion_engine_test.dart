import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/booster_suggestion_engine.dart';
import 'package:poker_analyzer/models/mistake_insight.dart';
import 'package:poker_analyzer/models/mistake_tag.dart';
import 'package:poker_analyzer/models/mistake_tag_cluster.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

TrainingPackTemplateV2 booster(
    {required String id, required MistakeTagCluster c}) {
  return TrainingPackTemplateV2(
    id: id,
    name: id,
    trainingType: TrainingType.pushFold,
    gameType: GameType.tournament,
    tags: [c.label],
    spots: const [],
    spotCount: 0,
    created: DateTime.now(),
    positions: const [],
    meta: {'type': 'booster', 'tag': c.label},
  );
}

MistakeInsight insight(MistakeTag tag, double loss) {
  return MistakeInsight(
    tag: tag,
    count: 1,
    evLoss: loss,
    shortExplanation: '',
    examples: [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns booster id for low improvement tag', () async {
    final library = [
      booster(id: 'a', c: MistakeTagCluster.looseCallBlind),
      booster(id: 'b', c: MistakeTagCluster.missedEvOpportunities),
    ];
    final improvement = {
      MistakeTagCluster.looseCallBlind.label.toLowerCase(): 0.01,
      MistakeTagCluster.missedEvOpportunities.label.toLowerCase(): 0.2,
    };
    final insights = [
      insight(MistakeTag.looseCallBb, 20),
      insight(MistakeTag.missedEvPush, 50),
    ];
    final result = await const BoosterSuggestionEngine().suggestBooster(
      library: library,
      improvement: improvement,
      insights: insights,
      history: const [],
    );
    expect(result, 'a');
  });

  test('falls back to highest ev loss', () async {
    final library = [
      booster(id: 'a', c: MistakeTagCluster.looseCallBlind),
      booster(id: 'b', c: MistakeTagCluster.missedEvOpportunities),
    ];
    final improvement = {
      MistakeTagCluster.looseCallBlind.label.toLowerCase(): 0.2,
      MistakeTagCluster.missedEvOpportunities.label.toLowerCase(): 0.2,
    };
    final insights = [
      insight(MistakeTag.looseCallBb, 20),
      insight(MistakeTag.missedEvPush, 50),
    ];
    final result = await const BoosterSuggestionEngine().suggestBooster(
      library: library,
      improvement: improvement,
      insights: insights,
      history: const [],
    );
    expect(result, 'b');
  });
}
