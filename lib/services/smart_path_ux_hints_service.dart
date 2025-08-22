import '../app_config.dart';

class LearningContext {
  final String stageTitle;
  final double stageProgress;
  final Map<String, int> errorCounts;
  final List<double> recentEv;
  final bool afterPackCompleted;

  LearningContext({
    required this.stageTitle,
    required this.stageProgress,
    this.errorCounts = const {},
    this.recentEv = const [],
    this.afterPackCompleted = false,
  });

  bool get stagnating {
    if (recentEv.length < 3) return false;
    final last = recentEv.sublist(recentEv.length - 3);
    return last.every((e) => e < 0);
  }
}

class SmartPathUXHintsService {
  SmartPathUXHintsService();

  Future<String?> getHint(LearningContext ctx) async {
    if (!appConfig.showSmartPathHints) return null;

    if (ctx.afterPackCompleted && ctx.stageProgress >= 0.8) {
      return 'Продолжай в том же духе - ты почти закрыл эту стадию!';
    }

    if (ctx.errorCounts.isNotEmpty) {
      final entry = ctx.errorCounts.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      if (entry.value >= 3) {
        return 'Ты часто ошибаешься в позиции ${entry.key}. Хочешь попрактиковаться?';
      }
    }

    if (ctx.stagnating) {
      return 'Застопорился? Попробуй «Пак дня» или Повторы ошибок';
    }

    return null;
  }
}
