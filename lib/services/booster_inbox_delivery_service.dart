import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';


import '../models/scheduled_booster_entry.dart';
import 'smart_recall_booster_scheduler.dart';

/// Delivers top priority booster tags while respecting cooldown and
/// avoiding recent repeats.
class BoosterInboxDeliveryService {
  final SmartRecallBoosterScheduler scheduler;
  final Duration cooldown;

  BoosterInboxDeliveryService({
    SmartRecallBoosterScheduler? scheduler,
    this.cooldown = const Duration(hours: 12),
  }) : scheduler = scheduler ?? SmartRecallBoosterScheduler();

  static final BoosterInboxDeliveryService instance =
      BoosterInboxDeliveryService();

  static const String _prefsKey = 'delivered_booster_tags';

  Map<String, DateTime> _history = {};
  bool _loaded = false;

  /// Loads cached delivery history.
  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) {
          _history = {
            for (final e in data.entries)
              if (e.value is String)
                e.key.toString():
                    DateTime.tryParse(e.value as String) ?? DateTime.now()
          };
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({for (final e in _history.entries) e.key: e.value.toIso8601String()}),
    );
  }

  /// Returns the next tag that can be delivered, or null if none.
  Future<String?> getNextDeliverableTag({int maxCandidates = 5}) async {
    await _load();
    final list = await scheduler.getNextBoosters(max: maxCandidates);
    if (list.isEmpty) return null;
    final now = DateTime.now();
    for (final ScheduledBoosterEntry e in list) {
      final ts = _history[e.tag];
      if (ts == null || now.difference(ts) >= cooldown) {
        return e.tag;
      }
    }
    return null;
  }

  /// Records that [tag] was delivered now.
  Future<void> markDelivered(String tag) async {
    await _load();
    _history[tag] = DateTime.now();
    await _save();
  }

  /// Clears cached state for testing.
  void resetForTest() {
    _loaded = false;
    _history = {};
  }
}
