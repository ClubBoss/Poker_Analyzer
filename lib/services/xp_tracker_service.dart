import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'streak_tracker_service.dart';
import 'xp_level_engine.dart';
import 'level_up_celebration_engine.dart';

import '../models/xp_entry.dart';
import 'cloud_sync_service.dart';
import 'goal_engine.dart';
import 'achievements_engine.dart';

class XPTrackerService extends ChangeNotifier {
  XPTrackerService({this.cloud});

  static const _xpKey = 'xp_total';
  static const _boxKey = 'xp_history';
  static const targetXp = 10;
  static const achievementXp = 50;
  static const _timeKey = 'xp_updated';
  static const _tagXpPrefix = 'tag_xp_';

  final CloudSyncService? cloud;

  int _xp = 0;
  Box<dynamic>? _box;
  final List<XPEntry> _history = [];

  void _trim() {
    _history.sort((a, b) => b.date.compareTo(a.date));
    while (_history.length > 100) {
      _history.removeLast();
    }
  }

  Future<void> _persistHistory() async {
    await _box!.clear();
    for (final e in _history) {
      await _box!.put(e.id, e.toJson());
    }
  }

  Map<String, dynamic> _toMap() => {
    'xp': _xp,
    'entries': [for (final e in _history) e.toJson()],
    'updatedAt': DateTime.now().toIso8601String(),
  };

  Future<void> _persist(DateTime ts) async {
    await _saveXp();
    await _persistHistory();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timeKey, ts.toIso8601String());
  }

  Future<void> _save() async {
    await _persist(DateTime.now());
    if (cloud != null) {
      await cloud!.uploadXp(_toMap());
    }
  }

  int get xp => _xp;
  int getTotalXP() => _xp;
  int get level => XPLevelEngine.instance.getLevel(_xp);
  int get nextLevelXp => XPLevelEngine.instance.xpForLevel(level + 1);
  double get progress => XPLevelEngine.instance.getProgressToNextLevel(_xp);
  List<XPEntry> get history => List.unmodifiable(_history);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!Hive.isBoxOpen(_boxKey)) {
      await Hive.initFlutter();
      _box = await Hive.openBox(_boxKey);
    } else {
      _box = Hive.box(_boxKey);
    }
    _history
      ..clear()
      ..addAll(
        _box!.toMap().entries.where((e) => e.value is Map).map((e) {
          final map = Map<String, dynamic>.from(e.value as Map);
          return XPEntry.fromJson({'id': e.key.toString(), ...map});
        }),
      );
    _xp = prefs.getInt(_xpKey) ?? 0;
    if (cloud != null) {
      final remote = await cloud!.downloadXp();
      if (remote != null) {
        final remoteAt =
            DateTime.tryParse(remote['updatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final localAt =
            DateTime.tryParse(prefs.getString(_timeKey) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        if (remoteAt.isAfter(localAt)) {
          final list = remote['entries'];
          if (list is List) {
            _history
              ..clear()
              ..addAll(
                list.map(
                  (e) => XPEntry.fromJson(Map<String, dynamic>.from(e as Map)),
                ),
              );
            _trim();
            _xp =
                (remote['xp'] as num?)?.toInt() ??
                _history.fold(0, (p, e) => p + e.xp);
            await _persist(remoteAt);
          }
        } else if (localAt.isAfter(remoteAt)) {
          await cloud!.uploadXp(_toMap());
        }
      }
    }
    _xp = _history.fold(0, (p, e) => p + e.xp);
    await _persist(DateTime.now());
    notifyListeners();
  }

  Future<void> _saveXp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_xpKey, _xp);
  }

  Future<void> add({
    required int xp,
    required String source,
    int? streak,
  }) async {
    final entry = XPEntry(
      date: DateTime.now(),
      xp: xp,
      source: source,
      streak: streak ?? 0,
    );
    _history.insert(0, entry);
    _trim();
    final oldXp = _xp;
    _xp += xp;
    unawaited(LevelUpCelebrationEngine.instance.checkAndCelebrate(oldXp, _xp));
    unawaited(GoalEngine.instance.updateXP(xp));
    await _box!.put(entry.id, entry.toJson());
    await _save();
    notifyListeners();
    unawaited(AchievementsEngine.instance.checkAll());
  }

  /// Returns XP multiplier based on the current training streak.
  Future<double> getStreakMultiplier() async {
    final streak = await StreakTrackerService.instance.getCurrentStreak();
    if (streak >= 30) return 1.25;
    if (streak >= 14) return 1.15;
    if (streak >= 7) return 1.10;
    if (streak >= 3) return 1.05;
    return 1.0;
  }

  Future<void> addPerTagXP(
    Map<String, int> tagXp, {
    required String source,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    for (final entry in tagXp.entries) {
      final tag = entry.key.toLowerCase();
      final key = '$_tagXpPrefix$tag';
      Map<String, dynamic> data = {};
      final raw = prefs.getString(key);
      if (raw != null) {
        try {
          data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        } catch (_) {
          data = {};
        }
      }
      final history = List<Map<String, dynamic>>.from(
        data['history'] as List? ?? [],
      );
      history.insert(0, {
        'date': now.toIso8601String(),
        'xp': entry.value,
        'source': source,
      });
      while (history.length > 100) {
        history.removeLast();
      }
      final total = (data['total'] as num?)?.toInt() ?? 0;
      await prefs.setString(
        key,
        jsonEncode({'total': total + entry.value, 'history': history}),
      );
    }
  }

  Future<Map<String, int>> getTotalXpPerTag() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, int>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_tagXpPrefix)) continue;
      final tag = key.substring(_tagXpPrefix.length);
      final raw = prefs.getString(key);
      if (raw == null) continue;
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        result[tag] = (data['total'] as num?)?.toInt() ?? 0;
      } catch (_) {}
    }
    return result;
  }
}
