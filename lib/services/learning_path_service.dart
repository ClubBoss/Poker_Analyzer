import 'dart:math';
import 'package:poker_analyzer/services/preferences_service.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../models/game_type.dart';
import '../core/training/engine/training_type_engine.dart';
import '../services/training_pack_template_service.dart';
import 'smart_recommender_engine.dart';
import 'tag_mastery_service.dart';
import '../models/stage_id.dart';

class LearningPathService {
  LearningPathService._();
  static final instance = LearningPathService._();

  /// When enabled, [getNextStage] uses [SmartRecommenderEngine] to choose
  /// the next pack instead of the default sequential order.
  bool smartMode = false;

  static const _progressKey = 'starter_path_progress';

  Future<int> getStarterPathProgress() async {
    final prefs = await PreferencesService.getInstance();
    return prefs.getInt(_progressKey) ?? 0;
  }

  Future<void> _setProgress(int step) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setInt(_progressKey, step);
  }

  Future<void> resetStarterPath() => _setProgress(0);

  Future<void> advance(String packId) async {
    final list = buildStarterPath();
    final progress = await getStarterPathProgress();
    if (progress >= list.length) return;
    if (list[progress].id == packId) {
      await _setProgress(progress + 1);
    }
  }

  List<TrainingPackTemplateV2> buildStarterPath() {
    final pack1 = TrainingPackTemplateV2.fromTemplate(
      TrainingPackTemplateService.starterPushfold10bb(),
      type: TrainingType.pushFold,
    )
      ..name = 'Простейшие ситуации'
      ..description = 'BTN push/fold 10bb, без ICM'
      ..tags.addAll(['starterPath', 'step1'])
      ..gameType = GameType.tournament
      ..bb = 10
      ..positions = ['btn'];

    final pack2 = TrainingPackTemplateV2.fromTemplate(
      TrainingPackTemplateService.starterPushfold15bb(),
      type: TrainingType.pushFold,
    )
      ..name = 'Сложные решения'
      ..description = 'SB push/fold 15bb, edge-case споты'
      ..tags.addAll(['starterPath', 'step2'])
      ..gameType = GameType.tournament
      ..bb = 15
      ..positions = ['sb'];

    final pack3 = TrainingPackTemplateV2.fromTemplate(
      TrainingPackTemplateService.starterPushfold12bb(),
      type: TrainingType.pushFold,
    )
      ..name = 'ICM под давлением'
      ..description = '8-10bb SB/BTN vs BB, разные стеки'
      ..tags.addAll(['starterPath', 'step3'])
      ..gameType = GameType.tournament
      ..bb = 10
      ..positions = ['sb', 'btn'];

    final pack4 = TrainingPackTemplateV2.fromTemplate(
      TrainingPackTemplateService.starterPushfold20bb(),
      type: TrainingType.pushFold,
    )
      ..name = 'Ошибки новичков'
      ..description = 'Часто ошибаемые споты'
      ..tags.addAll(['starterPath', 'step4'])
      ..gameType = GameType.tournament
      ..bb = 20
      ..positions = ['sb'];

    final mixSpots = [
      ...pack1.spots,
      ...pack2.spots,
      ...pack3.spots,
      ...pack4.spots,
    ]..shuffle(Random());
    final pack5 = TrainingPackTemplateV2(
      id: 'starter_path_test',
      name: 'Финальный тест',
      description: 'Рандомный микс из предыдущих ситуаций',
      trainingType: TrainingType.pushFold,
      spots: mixSpots.take(10).toList(),
      spotCount: min(10, mixSpots.length),
      gameType: GameType.tournament,
      bb: 10,
      positions: const ['sb', 'btn'],
      tags: const ['starterPath', 'step5'],
    );

    return [pack1, pack2, pack3, pack4, pack5];
  }

  /// Returns the next training pack for the starter path.
  /// When [smartMode] is enabled, stages are recommended based on the player's
  /// weaknesses using [SmartRecommenderEngine].
  Future<TrainingPackTemplateV2?> getNextStage({
    required UserProgress progress,
    required TagMasteryService masteryService,
  }) async {
    final list = buildStarterPath();
    final step = await getStarterPathProgress();
    final remaining = list.skip(step).toList();
    if (remaining.isEmpty) return null;

    if (smartMode && remaining.length > 1) {
      final stages = [
        for (final p in remaining) StageID(p.id, tags: p.tags)
      ];
      final engine = SmartRecommenderEngine(
        masteryService: masteryService,
      );
      final next = await engine.suggestNextStage(
        progress: progress,
        availableStages: stages,
      );
      final found =
          remaining.firstWhere((e) => e.id == next?.id, orElse: () => remaining.first);
      return found;
    }

    return remaining.first;
  }
}
