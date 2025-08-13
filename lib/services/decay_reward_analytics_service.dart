import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reward_analytics_entry.dart';

class DecayRewardAnalyticsService {
  DecayRewardAnalyticsService._();
  static final DecayRewardAnalyticsService instance =
      DecayRewardAnalyticsService._();

  static const _prefsKey = 'reward_analytics_log';

  final List<RewardAnalyticsEntry> _log = [];
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is List) {
          _log.addAll(data.whereType<Map>().map((e) =>
              RewardAnalyticsEntry.fromJson(Map<String, dynamic>.from(e))));
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode([for (final e in _log) e.toJson()]),
    );
  }

  Future<void> logReward(String tag, String type) async {
    await _load();
    _log.insert(
      0,
      RewardAnalyticsEntry(
        tag: tag.toLowerCase(),
        rewardType: type,
        timestamp: DateTime.now(),
      ),
    );
    if (_log.length > 500) _log.removeRange(500, _log.length);
    await _save();
  }

  Future<List<RewardAnalyticsEntry>> getRecent({String? tag}) async {
    await _load();
    if (tag == null) return List.unmodifiable(_log);
    final key = tag.toLowerCase();
    return [
      for (final e in _log)
        if (e.tag == key) e
    ];
  }

  Future<Map<String, int>> getMostCommonRewards({String? tag}) async {
    final list = await getRecent(tag: tag);
    final map = <String, int>{};
    for (final e in list) {
      map[e.rewardType] = (map[e.rewardType] ?? 0) + 1;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sorted) e.key: e.value};
  }
}
