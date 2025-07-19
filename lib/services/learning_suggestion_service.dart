import '../services/learning_path_progress_service.dart';

enum LearningTipAction { continuePack, startStage, repeatStage, exploreNextStage }

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

class LearningSuggestionService {
  const LearningSuggestionService();

  Future<LearningTip?> getTip() async {
    final stages = await LearningPathProgressService.instance.getCurrentStageState();

    for (final stage in stages) {
      for (final item in stage.items) {
        if (item.status == LearningItemStatus.inProgress && item.templateId != null) {
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
      final remaining = stage.items.where((i) => i.status != LearningItemStatus.completed).toList();
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

    final allDone = await LearningPathProgressService.instance.isAllStagesCompleted();
    if (allDone && stages.isNotEmpty) {
      final first = stages.first.items.first.templateId;
      return LearningTip(
        title: '🎉 Путь завершен — отличная работа!',
        description: 'Можно повторить этапы для закрепления.',
        action: LearningTipAction.repeatStage,
        targetId: first ?? '',
      );
    }

    return null;
  }
}
