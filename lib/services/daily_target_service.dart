import 'package:flutter/foundation.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'training_stats_service.dart';

class DailyTargetService extends ChangeNotifier {
  static const _key = 'daily_hands_target';
  int _target = 10;
  int get target => _target;

  int get progress {
    final stats = TrainingStatsService.instance;
    if (stats == null) return 0;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return stats.handsPerDay[today] ?? 0;
  }

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    _target = prefs.getInt(_key) ?? 10;
    notifyListeners();
  }

  Future<void> setTarget(int value) async {
    if (_target == value) return;
    _target = value;
    final prefs = await PreferencesService.getInstance();
    await prefs.setInt(_key, value);
    notifyListeners();
  }
}
