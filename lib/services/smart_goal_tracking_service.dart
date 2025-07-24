import '../models/goal_progress.dart';
import 'pack_library_loader_service.dart';
import 'session_log_service.dart';

class SmartGoalTrackingService {
  final SessionLogService logs;

  SmartGoalTrackingService({required this.logs});

  final Map<String, GoalProgress> _cache = {};

  Future<GoalProgress> getGoalProgress(String tag) async {
    final key = tag.trim().toLowerCase();
    final cached = _cache[key];
    if (cached != null) return cached;

    await logs.load();
    await PackLibraryLoaderService.instance.loadLibrary();
    final library = {
      for (final t in PackLibraryLoaderService.instance.library) t.id: t,
    };

    var completed = 0;
    var accuracySum = 0.0;

    for (final log in logs.logs) {
      final tpl = library[log.templateId];
      if (tpl == null) continue;
      if (!tpl.tags.contains(key)) continue;
      final total = log.correctCount + log.mistakeCount;
      if (total == 0) continue;
      completed += 1;
      accuracySum += log.correctCount / total * 100;
    }

    final progress = GoalProgress(
      tag: key,
      stagesCompleted: completed,
      averageAccuracy: completed == 0 ? 0.0 : accuracySum / completed,
    );
    _cache[key] = progress;
    return progress;
  }
}
