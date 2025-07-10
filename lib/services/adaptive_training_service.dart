import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/v2/training_pack_template.dart';
import 'template_storage_service.dart';
import 'training_pack_stats_service.dart';
import 'mistake_review_pack_service.dart';
import 'xp_tracker_service.dart';
import 'hand_analysis_history_service.dart';

class AdaptiveTrainingService extends ChangeNotifier {
  final TemplateStorageService templates;
  final MistakeReviewPackService mistakes;
  final XPTrackerService xp;
  final HandAnalysisHistoryService history;
  AdaptiveTrainingService({
    required this.templates,
    required this.mistakes,
    required this.xp,
    required this.history,
  }) {
    refresh();
    templates.addListener(refresh);
    mistakes.addListener(refresh);
    xp.addListener(refresh);
    history.addListener(refresh);
  }

  List<TrainingPackTemplate> _recommended = [];
  Map<String, TrainingPackStat?> _stats = {};

  List<TrainingPackTemplate> get recommended => List.unmodifiable(_recommended);
  TrainingPackStat? statFor(String id) => _stats[id];

  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final level = xp.level;
    final last = history.records.take(20).toList();
    final avgEv =
        last.isEmpty ? 0.0 : last.map((e) => e.ev).reduce((a, b) => a + b) / last.length;
    final avgIcm =
        last.isEmpty ? 0.0 : last.map((e) => e.icm).reduce((a, b) => a + b) / last.length;
    final penalty = ((avgEv < 0 ? -avgEv : 0) + (avgIcm < 0 ? -avgIcm : 0)) * 0.1;
    final entries = <MapEntry<TrainingPackTemplate, double>>[];
    final stats = <String, TrainingPackStat?>{};
    for (final t in templates.templates) {
      if (!t.isBuiltIn) continue;
      if (prefs.getBool('completed_tpl_${t.id}') ?? false) continue;
      final stat = await TrainingPackStatsService.getStats(t.id);
      stats[t.id] = stat;
      final miss = mistakes.mistakeCount(t.id);
      var score = 1 - (stat?.accuracy ?? 0);
      score += 1 - (stat?.postEvPct ?? 0) / 100;
      score += 1 - (stat?.postIcmPct ?? 0) / 100;
      if (miss > 0) score += 1 + miss * .2;
      final diff = (t.difficultyLevel - level).abs();
      score += diff * 0.3;
      score += penalty;
      entries.add(MapEntry(t, score));
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    _recommended = [for (final e in entries.take(5)) e.key];
    _stats = stats;
    notifyListeners();
  }
}
