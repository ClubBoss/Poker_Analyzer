/// Aggregated learning progress stats used for recommendations.
class LearningStats {
  final int completedPacks;
  final double accuracy;
  final double ev;
  final double icm;
  final bool starterPathCompleted;
  final bool customPathStarted;
  final bool customPathCompleted;
  final bool hasWeakTags;
  final bool hasMistakes;

  LearningStats({
    required this.completedPacks,
    required this.accuracy,
    required this.ev,
    required this.icm,
    required this.starterPathCompleted,
    required this.customPathStarted,
    required this.customPathCompleted,
    required this.hasWeakTags,
    required this.hasMistakes,
  });
}

/// Suggested next step for the player.
class NextStepAdvice {
  final String title;
  final String description;
  final String action;

  NextStepAdvice({
    required this.title,
    required this.description,
    required this.action,
  });
}

/// Simple rule-based advisor for what to do next.
class NextStepAdvisorService {
  NextStepAdvisorService();

  NextStepAdvice recommend({required LearningStats stats}) {
    if (stats.hasMistakes && (stats.ev < 0 || stats.icm < 0)) {
      return const NextStepAdvice(
        title: 'Повторить ошибки',
        description:
            'Разберите допущенные ошибки, чтобы улучшить EV и ICM показатели.',
        action: 'repeat_errors',
      );
    }
    if (stats.hasWeakTags) {
      return const NextStepAdvice(
        title: 'Прокачать слабые места',
        description: 'Мы обнаружили слабые теги. Улучшите их на тренировке.',
        action: 'train_weak_tags',
      );
    }
    if (!stats.starterPathCompleted) {
      return const NextStepAdvice(
        title: 'Завершить Starter Path',
        description: 'Доведите базовый путь обучения до конца.',
        action: 'finish_starter_path',
      );
    }
    if (stats.starterPathCompleted && !stats.customPathStarted) {
      return const NextStepAdvice(
        title: 'Начать новый путь',
        description: 'Вы готовы приступить к следующему обучающему пути.',
        action: 'start_new_path',
      );
    }
    if (stats.customPathStarted && !stats.customPathCompleted) {
      return const NextStepAdvice(
        title: 'Завершить кастомный путь',
        description: 'Вы почти у цели. Доведите кастомный путь до конца.',
        action: 'finish_custom_path',
      );
    }
    return const NextStepAdvice(
      title: 'Сыграть рекомендованный пак',
      description: 'Поддерживайте форму тренировкой в подходящем паке.',
      action: 'play_recommended_pack',
    );
  }
}
