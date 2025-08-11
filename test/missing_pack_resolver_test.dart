import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/missing_pack_resolver.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  test('resolver returns pack', () async {
    final resolver = MissingPackResolver(
      generator: (id, {presetId}) async => TrainingPackTemplateV2(
        id: id,
        name: 'p',
        trainingType: TrainingType.cash,
        spots: const [],
        spotCount: 0,
        gameType: GameType.cash,
        bb: 0,
        positions: const [],
        meta: const {},
        tags: const [],
      ),
    );
    final stage = LearningPathStageModel(
      id: 's',
      title: 's',
      description: '',
      packId: 'p',
      requiredAccuracy: 0,
      requiredHands: 0,
    );
    final pack = await resolver.resolve(stage);
    expect(pack, isNotNull);
  });

  test('resolver returns null on error', () async {
    final resolver = MissingPackResolver(
      generator: (id, {presetId}) => Future.error('fail'),
    );
    final stage = LearningPathStageModel(
      id: 's',
      title: 's',
      description: '',
      packId: 'p',
      requiredAccuracy: 0,
      requiredHands: 0,
    );
    final pack = await resolver.resolve(stage);
    expect(pack, isNull);
  });
}

