import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/v2/training_pack_template.dart';
import 'template_storage_service.dart';
import 'training_pack_stats_service.dart';

class AdaptiveTrainingService extends ChangeNotifier {
  final TemplateStorageService templates;
  AdaptiveTrainingService({required this.templates}) {
    refresh();
    templates.addListener(refresh);
  }

  List<TrainingPackTemplate> _recommended = [];
  Map<String, TrainingPackStat?> _stats = {};

  List<TrainingPackTemplate> get recommended => List.unmodifiable(_recommended);
  TrainingPackStat? statFor(String id) => _stats[id];

  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = <MapEntry<TrainingPackTemplate, double>>[];
    final stats = <String, TrainingPackStat?>{};
    for (final t in templates.templates) {
      if (!t.isBuiltIn) continue;
      if (prefs.getBool('completed_tpl_${t.id}') ?? false) continue;
      final stat = await TrainingPackStatsService.getStats(t.id);
      stats[t.id] = stat;
      entries.add(MapEntry(t, stat?.accuracy ?? 0));
    }
    entries.sort((a, b) => a.value.compareTo(b.value));
    _recommended = [for (final e in entries.take(3)) e.key];
    _stats = stats;
    notifyListeners();
  }
}
