import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/v2/training_pack_template.dart';
import 'template_storage_service.dart';
import 'training_pack_stats_service.dart';
import 'mistake_review_pack_service.dart';
import 'xp_tracker_service.dart';

class AdaptiveTrainingService extends ChangeNotifier {
  final TemplateStorageService templates;
  final MistakeReviewPackService mistakes;
  final XPTrackerService xp;
  AdaptiveTrainingService({
    required this.templates,
    required this.mistakes,
    required this.xp,
  }) {
    refresh();
    templates.addListener(refresh);
    mistakes.addListener(refresh);
    xp.addListener(refresh);
  }

  List<TrainingPackTemplate> _recommended = [];
  Map<String, TrainingPackStat?> _stats = {};

  List<TrainingPackTemplate> get recommended => List.unmodifiable(_recommended);
  TrainingPackStat? statFor(String id) => _stats[id];

  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final level = xp.level;
    final entries = <MapEntry<TrainingPackTemplate, double>>[];
    final stats = <String, TrainingPackStat?>{};
    for (final t in templates.templates) {
      if (!t.isBuiltIn) continue;
      if (prefs.getBool('completed_tpl_${t.id}') ?? false) continue;
      final stat = await TrainingPackStatsService.getStats(t.id);
      stats[t.id] = stat;
      var score = 1 - (stat?.accuracy ?? 0);
      score += 1 - (stat?.postEvPct ?? 0) / 100;
      score += 1 - (stat?.postIcmPct ?? 0) / 100;
      if (mistakes.hasMistakes(t.id)) score += 1;
      final diff = (t.difficultyLevel - level).abs();
      score += diff * 0.3;
      entries.add(MapEntry(t, score));
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    _recommended = [for (final e in entries.take(5)) e.key];
    _stats = stats;
    notifyListeners();
  }
}
