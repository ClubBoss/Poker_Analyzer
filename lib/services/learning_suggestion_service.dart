import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/learning_path_progress_service.dart';
import '../services/training_pack_template_service.dart';
import '../services/training_progress_service.dart';
import '../services/training_pack_stats_service.dart';
import '../services/tag_mastery_service.dart';

enum LearningTipAction {
  continuePack,
  startStage,
  repeatStage,
  exploreNextStage,
}

class LearningTip {
  final String title;
  final String description;
  final LearningTipAction action;
  final String targetId;

  const LearningTip({
    required this.title,
    required this.description,
    required this.action,
    required this.targetId,
  });
}

class LearningPackSuggestion {
  final String templateId;
  final String suggestionReason;

  const LearningPackSuggestion({
    required this.templateId,
    required this.suggestionReason,
  });
}

class LearningSuggestionService {
  const LearningSuggestionService();

  /// Suggests the next best pack to train based on progress and weak spots.
  Future<LearningPackSuggestion?> nextSuggestedPack(
    BuildContext context,
  ) async {
    final list = await getSuggestions(context);
    return list.isNotEmpty ? list.first : null;
  }

  /// Returns extended suggestions for the learning path.
  /// The list is ordered by priority.
  Future<List<LearningPackSuggestion>> getSuggestions(
    BuildContext context,
  ) async {
    final mastery = context.read<TagMasteryService>();
    final weakTags = await mastery.topWeakTags(5);

    final stages = await LearningPathProgressService.instance
        .getCurrentStageState();
    final result = <LearningPackSuggestion>[];

    for (final stage in stages) {
      if (stage.isLocked) continue;
      for (final item in stage.items) {
        final id = item.templateId;
        if (id == null) continue;
        final progress = await TrainingProgressService.instance.getProgress(id);
        if (progress >= 1.0) continue;

        String? reason;
        final stat = await TrainingPackStatsService.getStats(id);
        if (stat != null && (stat.accuracy < 0.8 || stat.evSum < 0)) {
          reason = 'Низкий результат в предыдущих сессиях';
        } else if (progress > 0) {
          reason = 'Уровень завершён частично';
        }

        final tpl = TrainingPackTemplateService.getById(id, context);
        final match = tpl == null
            ? null
            : weakTags.firstWhereOrNull((t) => tpl.tags.contains(t));
        if (match != null) {
          reason = 'Слабая зона: $match';
        }

        result.add(
          LearningPackSuggestion(
            templateId: id,
            suggestionReason: reason ?? 'Непройденный пак',
          ),
        );
      }
    }

    return result;
  }

  Future<LearningTip?> getTip() async {
    final stages = await LearningPathProgressService.instance
        .getCurrentStageState();

    for (final stage in stages) {
      for (final item in stage.items) {
        if (item.status == LearningItemStatus.inProgress &&
            item.templateId != null) {
          return LearningTip(
            title: '🏃 Продолжите пак "${item.title}"',
            description: 'Вы остановились на паке из стадии "${stage.title}".',
            action: LearningTipAction.continuePack,
            targetId: item.templateId!,
          );
        }
      }
    }

    for (final stage in stages) {
      if (stage.isLocked) continue;
      final remaining = stage.items
          .where((i) => i.status != LearningItemStatus.completed)
          .toList();
      if (remaining.isEmpty) continue;
      final title = stage.title;
      final count = remaining.length;
      final first = remaining.first.templateId;
      if (first != null) {
        return LearningTip(
          title: '🏁 Завершите стадию "$title"',
          description: count == 1
              ? 'Остался всего 1 пак. Отличный момент, чтобы завершить начальный этап!'
              : 'Осталось $count паков. Продвиньтесь дальше прямо сейчас!',
          action: LearningTipAction.startStage,
          targetId: first,
        );
      }
    }

    final allDone = await LearningPathProgressService.instance
        .isAllStagesCompleted();
    if (allDone && stages.isNotEmpty) {
      final first = stages.first.items.first.templateId;
      return LearningTip(
        title: '🎉 Путь завершен - отличная работа!',
        description: 'Можно повторить этапы для закрепления.',
        action: LearningTipAction.repeatStage,
        targetId: first ?? '',
      );
    }

    return null;
  }
}
