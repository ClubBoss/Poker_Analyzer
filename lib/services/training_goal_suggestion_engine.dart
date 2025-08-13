import 'package:collection/collection.dart';
import '../models/training_goal.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'smart_pack_recommendation_engine.dart';

class TrainingGoalSuggestionEngine {
  const TrainingGoalSuggestionEngine();

  List<TrainingGoal> suggest(
      UserProfile user, List<TrainingPackTemplateV2> packs) {
    final goals = <TrainingGoal>[];
    final sbTotal = packs.where((p) => p.positions.contains('SB')).length;
    final sbDone = user.completedPackIds.where((id) {
      final tpl = packs.firstWhereOrNull((e) => e.id == id);
      return tpl != null && tpl.positions.contains('SB');
    }).length;
    if (sbTotal - sbDone >= 3) {
      goals.add(const TrainingGoal('🎯 Заверши 3 пака по позиции SB'));
    }
    var lowEv = 0;
    for (final p in packs) {
      final ev = (p.meta['evScore'] as num?)?.toDouble();
      if (ev != null && ev < 90) lowEv += p.spotCount;
    }
    if (lowEv >= 50) {
      goals.add(const TrainingGoal('📚 Пройди 50 спотов с EV < 90%'));
    }
    if (user.completedPackIds.isNotEmpty) {
      goals.add(const TrainingGoal('🔁 Повтори паки с ошибками'));
    }
    goals.add(const TrainingGoal(
        '🔥 Заверши 1 тренировку каждый день в течение 3 дней'));
    return goals;
  }
}
