import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'progress_export_service.dart';
import 'cloud_sync_service.dart';
import '../models/training_stats.dart';
import '../models/saved_hand.dart';
import '../models/skill_stat.dart';
import '../models/session_log.dart';
import '../services/template_storage_service.dart';
import '../services/training_pack_stats_service.dart';
import '../services/streak_service.dart';

class PackPlayStats {
  final int launches;
  final int totalTrained;
  final int mistakes;
  PackPlayStats({
    this.launches = 0,
    this.totalTrained = 0,
    this.mistakes = 0,
  });
}

class TrainingStatsService extends ChangeNotifier {
  static TrainingStatsService? _instance;
  static TrainingStatsService? get instance => _instance;

  TrainingStatsService({this.cloud}) {
    _instance = this;
  }

  final CloudSyncService? cloud;
  static const _sessionsKey = 'stats_sessions';
  static const _handsKey = 'stats_hands';
  static const _mistakesKey = 'stats_mistakes';
  static const _sessionsHistKey = 'stats_sessions_hist';
  static const _handsHistKey = 'stats_hands_hist';
  static const _mistakesHistKey = 'stats_mistakes_hist';
  static const _currentStreakKey = 'stats_current_streak';
  static const _bestStreakKey = 'stats_best_streak';
  static const _evalTotalKey = 'stats_eval_total';
  static const _evalCorrectKey = 'stats_eval_correct';
  static const _evalHistoryKey = 'stats_eval_history';
  static const _skillStatsKey = 'stats_skill_stats';
  static const _mistakeCountsKey = 'stats_mistake_counts';
  static const _timeKey = 'stats_updated';

  int _sessions = 0;
  int _hands = 0;
  int _mistakes = 0;

  int _currentStreak = 0;
  int _bestStreak = 0;

  int _evalTotal = 0;
  int _evalCorrect = 0;
  List<double> _evalHistory = [];

  Map<String, int> _sessionsPerDay = {};
  Map<String, int> _handsPerDay = {};
  Map<String, int> _mistakesPerDay = {};
  Map<String, SkillStat> _skillStats = {};
  Map<String, int> _mistakeCounts = {};

  Map<DateTime, int> get handsPerDay => {
    for (final e in _handsPerDay.entries) DateTime.parse(e.key): e.value,
  };

  final _sessionController = StreamController<int>.broadcast();
  final _handsController = StreamController<int>.broadcast();
  final _mistakeController = StreamController<int>.broadcast();

  int get sessionsCompleted => _sessions;
  int get handsReviewed => _hands;
  int get mistakesFixed => _mistakes;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  int get evalTotal => _evalTotal;
  int get evalCorrect => _evalCorrect;
  double get evalAccuracy => _evalTotal > 0 ? _evalCorrect / _evalTotal : 0.0;
  List<double> get evalHistory => List.unmodifiable(_evalHistory);
  Map<String, SkillStat> get skillStats => _skillStats;
  Map<String, int> get mistakeCounts => Map.unmodifiable(_mistakeCounts);

  /// Date of the most recent training activity.
  DateTime? get lastTrainingDate {
    if (_handsPerDay.isEmpty) return null;
    final list = _handsPerDay.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();
    if (list.isEmpty) return null;
    list.sort();
    return DateTime.parse(list.last);
  }

  Stream<int> get sessionsStream => _sessionController.stream;
  Stream<int> get handsStream => _handsController.stream;
  Stream<int> get mistakesStream => _mistakeController.stream;

  List<MapEntry<DateTime, int>> _entries(Map<String, int> map) {
    return map.entries
        .map((e) => MapEntry(DateTime.parse(e.key), e.value))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  List<MapEntry<DateTime, int>> handsDaily([int days = 7]) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    return [
      for (final e in _entries(_handsPerDay))
        if (!e.key.isBefore(start)) e,
    ];
  }

  List<MapEntry<DateTime, int>> sessionsDaily([int days = 7]) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    return [
      for (final e in _entries(_sessionsPerDay))
        if (!e.key.isBefore(start)) e,
    ];
  }

  List<MapEntry<DateTime, int>> mistakesDaily([int days = 7]) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    return [
      for (final e in _entries(_mistakesPerDay))
        if (!e.key.isBefore(start)) e,
    ];
  }

  List<MapEntry<DateTime, double>> evDaily(
    List<SavedHand> hands, [
    int days = 7,
  ]) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    final Map<DateTime, List<double>> map = {};
    for (final h in hands) {
      final v = h.heroEv;
      if (v == null) continue;
      final d = DateTime(h.date.year, h.date.month, h.date.day);
      if (d.isBefore(start)) continue;
      map.putIfAbsent(d, () => []).add(v);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return [
      for (final e in entries)
        MapEntry(e.key, e.value.reduce((a, b) => a + b) / e.value.length),
    ];
  }

  List<MapEntry<DateTime, double>> icmDaily(
    List<SavedHand> hands, [
    int days = 7,
  ]) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    final Map<DateTime, List<double>> map = {};
    for (final h in hands) {
      final v = h.heroIcmEv;
      if (v == null) continue;
      final d = DateTime(h.date.year, h.date.month, h.date.day);
      if (d.isBefore(start)) continue;
      map.putIfAbsent(d, () => []).add(v);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return [
      for (final e in entries)
        MapEntry(e.key, e.value.reduce((a, b) => a + b) / e.value.length),
    ];
  }

  List<MapEntry<DateTime, double>> getDailyEvLossData(List<SavedHand> hands) {
    final map = <DateTime, double>{};
    for (final h in hands) {
      final loss = h.evLoss;
      if (loss == null) continue;
      final d = DateTime(h.savedAt.year, h.savedAt.month, h.savedAt.day);
      map.update(d, (v) => v + loss, ifAbsent: () => loss);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return [for (final e in entries) MapEntry(e.key, e.value)];
  }

  List<MapEntry<DateTime, double>> _groupWeeklyAvg(
    List<MapEntry<DateTime, double>> daily,
  ) {
    final Map<DateTime, List<double>> grouped = {};
    for (final e in daily) {
      final w = e.key.subtract(Duration(days: e.key.weekday - 1));
      grouped.putIfAbsent(w, () => []).add(e.value);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return [
      for (final e in entries)
        MapEntry(e.key, e.value.reduce((a, b) => a + b) / e.value.length),
    ];
  }

  List<MapEntry<DateTime, double>> evWeekly(
    List<SavedHand> hands, [
    int weeks = 4,
  ]) {
    final daily = evDaily(hands, weeks * 7);
    return _groupWeeklyAvg(daily);
  }

  List<MapEntry<DateTime, double>> icmWeekly(
    List<SavedHand> hands, [
    int weeks = 4,
  ]) {
    final daily = icmDaily(hands, weeks * 7);
    return _groupWeeklyAvg(daily);
  }

  List<MapEntry<DateTime, double>> _groupMonthlyAvg(
    List<MapEntry<DateTime, double>> daily,
  ) {
    final Map<DateTime, List<double>> grouped = {};
    for (final e in daily) {
      final m = DateTime(e.key.year, e.key.month);
      grouped.putIfAbsent(m, () => []).add(e.value);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return [
      for (final e in entries)
        MapEntry(e.key, e.value.reduce((a, b) => a + b) / e.value.length),
    ];
  }

  List<MapEntry<DateTime, double>> evMonthly(
    List<SavedHand> hands, [
    int months = 12,
  ]) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - months + 1);
    final daily = [
      for (final e in evDaily(hands, months * 31))
        if (!e.key.isBefore(start)) e,
    ];
    return _groupMonthlyAvg(daily);
  }

  List<MapEntry<DateTime, double>> icmMonthly(
    List<SavedHand> hands, [
    int months = 12,
  ]) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - months + 1);
    final daily = [
      for (final e in icmDaily(hands, months * 31))
        if (!e.key.isBefore(start)) e,
    ];
    return _groupMonthlyAvg(daily);
  }

  List<MapEntry<DateTime, double>> categoryEvSeries(
    List<SavedHand> hands,
    String cat,
  ) {
    final Map<DateTime, List<double>> map = {};
    for (final h in hands) {
      if (h.category != cat) continue;
      final ev = h.heroEv;
      if (ev == null) continue;
      final d = DateTime(h.date.year, h.date.month, h.date.day);
      map.putIfAbsent(d, () => []).add(ev);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return [
      for (final e in entries)
        MapEntry(e.key, e.value.reduce((a, b) => a + b) / e.value.length),
    ];
  }

  List<MapEntry<DateTime, double>> categoryIcmSeries(
    List<SavedHand> hands,
    String cat,
  ) {
    final Map<DateTime, List<double>> map = {};
    for (final h in hands) {
      if (h.category != cat) continue;
      final v = h.heroIcmEv;
      if (v == null) continue;
      final d = DateTime(h.date.year, h.date.month, h.date.day);
      map.putIfAbsent(d, () => []).add(v);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return [
      for (final e in entries)
        MapEntry(e.key, e.value.reduce((a, b) => a + b) / e.value.length),
    ];
  }

  MapEntry<double, double> sessionEvIcmAvg(Iterable<SavedHand> hands) {
    double evSum = 0;
    int evCount = 0;
    double icmSum = 0;
    int icmCount = 0;
    for (final h in hands) {
      final ev = h.heroEv;
      if (ev != null) {
        evSum += ev;
        evCount++;
      }
      final icm = h.heroIcmEv;
      if (icm != null) {
        icmSum += icm;
        icmCount++;
      }
    }
    final evAvg = evCount > 0 ? evSum / evCount : 0.0;
    final icmAvg = icmCount > 0 ? icmSum / icmCount : 0.0;
    return MapEntry(evAvg, icmAvg);
  }

  List<MapEntry<DateTime, int>> _groupWeekly(
    List<MapEntry<DateTime, int>> daily,
  ) {
    final Map<DateTime, int> grouped = {};
    for (final e in daily) {
      final w = e.key.subtract(Duration(days: e.key.weekday - 1));
      grouped.update(w, (v) => v + e.value, ifAbsent: () => e.value);
    }
    final list = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return list;
  }

  List<MapEntry<DateTime, int>> handsWeekly([int weeks = 4]) {
    final daily = handsDaily(weeks * 7);
    return _groupWeekly(daily);
  }

  List<MapEntry<DateTime, int>> sessionsWeekly([int weeks = 4]) {
    final daily = sessionsDaily(weeks * 7);
    return _groupWeekly(daily);
  }

  List<MapEntry<DateTime, int>> mistakesWeekly([int weeks = 4]) {
    final daily = mistakesDaily(weeks * 7);
    return _groupWeekly(daily);
  }

  List<MapEntry<DateTime, int>> _groupMonthly(
    List<MapEntry<DateTime, int>> daily,
  ) {
    final Map<DateTime, int> grouped = {};
    for (final e in daily) {
      final m = DateTime(e.key.year, e.key.month);
      grouped.update(m, (v) => v + e.value, ifAbsent: () => e.value);
    }
    final list = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return list;
  }

  List<MapEntry<DateTime, int>> handsMonthly([int months = 12]) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - months + 1);
    final daily = [
      for (final e in _entries(_handsPerDay))
        if (!e.key.isBefore(start)) e,
    ];
    return _groupMonthly(daily);
  }

  List<MapEntry<DateTime, int>> sessionsMonthly([int months = 12]) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - months + 1);
    final daily = [
      for (final e in _entries(_sessionsPerDay))
        if (!e.key.isBefore(start)) e,
    ];
    return _groupMonthly(daily);
  }

  List<MapEntry<DateTime, int>> mistakesMonthly([int months = 12]) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - months + 1);
    final daily = [
      for (final e in _entries(_mistakesPerDay))
        if (!e.key.isBefore(start)) e,
    ];
    return _groupMonthly(daily);
  }

  List<DateTime> sessionHistory(List<SavedHand> hands, [int limit = 30]) {
    final Map<int, DateTime> map = {};
    for (final h in hands) {
      final saved = map[h.sessionId];
      if (saved == null || h.savedAt.isAfter(saved)) {
        map[h.sessionId] = h.savedAt;
      }
    }
    final list = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final dates = [for (final e in list) e.value];
    if (dates.length > limit) dates.removeRange(0, dates.length - limit);
    return dates;
  }

  List<List<dynamic>> progressRows({bool weekly = false, int count = 30}) {
    final sessions = weekly ? sessionsWeekly(count) : sessionsDaily(count);
    final hands = weekly ? handsWeekly(count) : handsDaily(count);
    final mistakes = weekly ? mistakesWeekly(count) : mistakesDaily(count);
    final sMap = {for (final e in sessions) e.key: e.value};
    final hMap = {for (final e in hands) e.key: e.value};
    final mMap = {for (final e in mistakes) e.key: e.value};
    final dates = {...sMap.keys, ...hMap.keys, ...mMap.keys}.toList()..sort();
    final rows = <List<dynamic>>[
      ['Date', 'Sessions', 'Hands', 'Mistakes'],
    ];
    for (final d in dates) {
      final key = d.toIso8601String().split('T').first;
      rows.add([key, sMap[d] ?? 0, hMap[d] ?? 0, mMap[d] ?? 0]);
    }
    return rows;
  }

  Future<void> shareProgress({bool weekly = false}) async {
    final exporter = ProgressExportService(stats: this);
    final csv = await exporter.exportCsv(weekly: weekly);
    final pdf = await exporter.exportPdf(weekly: weekly);
    await Share.shareXFiles([XFile(csv.path), XFile(pdf.path)]);
  }

  Map<String, int> _loadMap(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return {};
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return {for (final e in data.entries) e.key: e.value as int};
  }

  Future<void> _saveMap(
    SharedPreferences prefs,
    String key,
    Map<String, int> map,
  ) async {
    await prefs.setString(key, jsonEncode(map));
  }

  void _trim(Map<String, int> map) {
    final keys = map.keys.toList()..sort();
    while (keys.length > 30) {
      map.remove(keys.first);
      keys.removeAt(0);
    }
  }

  int _calcCurrentStreak() {
    final today = DateTime.now();
    int streak = 0;
    for (int i = 0; ; i++) {
      final day = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: i));
      final key = day.toIso8601String().split('T').first;
      final hands = _handsPerDay[key] ?? 0;
      final mistakes = _mistakesPerDay[key] ?? 0;
      if (hands > 0 && mistakes == 0) {
        streak += 1;
      } else {
        break;
      }
    }
    return streak;
  }

  int _calcBestStreak() {
    final allKeys = {..._handsPerDay.keys, ..._mistakesPerDay.keys}
      ..removeWhere((e) => e.isEmpty);
    final dates = allKeys.map(DateTime.parse).toList()..sort();
    int best = 0;
    int current = 0;
    DateTime? prev;
    for (final d in dates) {
      final key = d.toIso8601String().split('T').first;
      final hands = _handsPerDay[key] ?? 0;
      final mistakes = _mistakesPerDay[key] ?? 0;
      if (prev != null && d.difference(prev).inDays > 1) current = 0;
      if (hands > 0 && mistakes == 0) {
        current += 1;
        if (current > best) best = current;
      } else {
        current = 0;
      }
      prev = d;
    }
    return best;
  }

  Future<void> _updateStreaks() async {
    _currentStreak = _calcCurrentStreak();
    _bestStreak = _calcBestStreak();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentStreakKey, _currentStreak);
    await prefs.setInt(_bestStreakKey, _bestStreak);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _sessions = prefs.getInt(_sessionsKey) ?? 0;
    _hands = prefs.getInt(_handsKey) ?? 0;
    _mistakes = prefs.getInt(_mistakesKey) ?? 0;
    _sessionsPerDay = _loadMap(prefs, _sessionsHistKey);
    _handsPerDay = _loadMap(prefs, _handsHistKey);
    _mistakesPerDay = _loadMap(prefs, _mistakesHistKey);
    _evalTotal = prefs.getInt(_evalTotalKey) ?? 0;
    _evalCorrect = prefs.getInt(_evalCorrectKey) ?? 0;
    _evalHistory = [
      for (final s in prefs.getStringList(_evalHistoryKey) ?? [])
        double.tryParse(s) ?? 0,
    ];
    final skillsRaw = prefs.getString(_skillStatsKey);
    if (skillsRaw != null) {
      final data = jsonDecode(skillsRaw) as Map<String, dynamic>;
      _skillStats = {
        for (final e in data.entries)
          e.key: SkillStat.fromJson(Map<String, dynamic>.from(e.value)),
      };
    }
    final countsRaw = prefs.getString(_mistakeCountsKey);
    if (countsRaw != null) {
      final data = jsonDecode(countsRaw) as Map<String, dynamic>;
      _mistakeCounts = {
        for (final e in data.entries) e.key: (e.value as num).toInt(),
      };
    }
    _currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
    _bestStreak = prefs.getInt(_bestStreakKey) ?? 0;
    if (cloud != null) {
      final remote = await cloud!.downloadTrainingStats();
      if (remote != null) {
        final remoteAt =
            DateTime.tryParse(remote['updatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final localAt =
            DateTime.tryParse(prefs.getString(_timeKey) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        if (remoteAt.isAfter(localAt)) {
          _sessions = (remote['sessions'] as num?)?.toInt() ?? _sessions;
          _hands = (remote['hands'] as num?)?.toInt() ?? _hands;
          _mistakes = (remote['mistakes'] as num?)?.toInt() ?? _mistakes;
          final spd = remote['sessionsPerDay'];
          final hpd = remote['handsPerDay'];
          final mpd = remote['mistakesPerDay'];
          if (spd is Map) {
            _sessionsPerDay = {
              for (final e in spd.entries) e.key: (e.value as num).toInt(),
            };
          }
          if (hpd is Map) {
            _handsPerDay = {
              for (final e in hpd.entries) e.key: (e.value as num).toInt(),
            };
          }
          if (mpd is Map) {
            _mistakesPerDay = {
              for (final e in mpd.entries) e.key: (e.value as num).toInt(),
            };
          }
          _currentStreak = (remote['currentStreak'] as num?)?.toInt() ?? 0;
          _bestStreak = (remote['bestStreak'] as num?)?.toInt() ?? 0;
          _evalTotal = (remote['evalTotal'] as num?)?.toInt() ?? 0;
          _evalCorrect = (remote['evalCorrect'] as num?)?.toInt() ?? 0;
          final hist = remote['evalHistory'];
          if (hist is List) {
            _evalHistory = [for (final v in hist) (v as num).toDouble()];
          }
          final skills = remote['skills'];
          if (skills is Map) {
            _skillStats = {
              for (final e in skills.entries)
                e.key: SkillStat.fromJson(
                  Map<String, dynamic>.from(e.value as Map),
                ),
            };
          }
          final counts = remote['mistakeCounts'];
          if (counts is Map) {
            _mistakeCounts = {
              for (final e in counts.entries) e.key: (e.value as num).toInt(),
            };
          }
          await _persist(remoteAt);
        } else if (localAt.isAfter(remoteAt)) {
          await cloud!.uploadTrainingStats(_toMap());
        }
      }
    }
    await _updateStreaks();
    notifyListeners();
  }

  Map<String, dynamic> _toMap() => {
    'sessions': _sessions,
    'hands': _hands,
    'mistakes': _mistakes,
    'sessionsPerDay': _sessionsPerDay,
    'handsPerDay': _handsPerDay,
    'mistakesPerDay': _mistakesPerDay,
    'currentStreak': _currentStreak,
    'bestStreak': _bestStreak,
    'evalTotal': _evalTotal,
    'evalCorrect': _evalCorrect,
    'evalHistory': _evalHistory,
    'skills': {for (final e in _skillStats.entries) e.key: e.value.toJson()},
    'mistakeCounts': _mistakeCounts,
    'updatedAt': DateTime.now().toIso8601String(),
  };

  Future<void> _persist(DateTime ts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionsKey, _sessions);
    await prefs.setInt(_handsKey, _hands);
    await prefs.setInt(_mistakesKey, _mistakes);
    await _saveMap(prefs, _sessionsHistKey, _sessionsPerDay);
    await _saveMap(prefs, _handsHistKey, _handsPerDay);
    await _saveMap(prefs, _mistakesHistKey, _mistakesPerDay);
    await prefs.setInt(_evalTotalKey, _evalTotal);
    await prefs.setInt(_evalCorrectKey, _evalCorrect);
    await prefs.setStringList(_evalHistoryKey, [
      for (final v in _evalHistory) v.toString(),
    ]);
    await prefs.setInt(_currentStreakKey, _currentStreak);
    await prefs.setInt(_bestStreakKey, _bestStreak);
    await prefs.setString(
      _skillStatsKey,
      jsonEncode({
        for (final e in _skillStats.entries) e.key: e.value.toJson(),
      }),
    );
    await prefs.setString(_mistakeCountsKey, jsonEncode(_mistakeCounts));
    await prefs.setString(_timeKey, ts.toIso8601String());
  }

  Future<void> _save() async {
    await _persist(DateTime.now());
    if (cloud != null) {
      await cloud!.uploadTrainingStats(_toMap());
    }
  }

  Future<void> incrementSessions() async {
    _sessions += 1;
    final key = DateTime.now().toIso8601String().split('T').first;
    _sessionsPerDay.update(key, (v) => v + 1, ifAbsent: () => 1);
    _trim(_sessionsPerDay);
    await _save();
    notifyListeners();
    _sessionController.add(_sessions);
  }

  Future<void> incrementHands([int count = 1]) async {
    _hands += count;
    final key = DateTime.now().toIso8601String().split('T').first;
    _handsPerDay.update(key, (v) => v + count, ifAbsent: () => count);
    _trim(_handsPerDay);
    await _updateStreaks();
    await _save();
    notifyListeners();
    _handsController.add(_hands);
  }

  Future<void> incrementMistakes([int count = 1]) async {
    _mistakes += count;
    final key = DateTime.now().toIso8601String().split('T').first;
    _mistakesPerDay.update(key, (v) => v + count, ifAbsent: () => count);
    _trim(_mistakesPerDay);
    await _updateStreaks();
    await _save();
    notifyListeners();
    _mistakeController.add(_mistakes);
  }

  Future<void> overwriteMistakeCounts(Map<String, int> map) async {
    _mistakeCounts
      ..clear()
      ..addAll(map);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mistakeCountsKey, jsonEncode(_mistakeCounts));
    if (cloud != null) {
      await cloud!.uploadTrainingStats(_toMap());
    }
    notifyListeners();
  }

  Future<void> updateSkill(String? category, double? ev, bool mistake) async {
    if (category == null || category.isEmpty) return;
    final prev = _skillStats[category];
    final hands = (prev?.handsPlayed ?? 0) + 1;
    final evAvg = ev != null
        ? (((prev?.evAvg ?? 0) * (prev?.handsPlayed ?? 0) + ev) / hands)
        : (prev?.evAvg ?? 0);
    final m = (prev?.mistakes ?? 0) + (mistake ? 1 : 0);
    _skillStats[category] = SkillStat(
      category: category,
      handsPlayed: hands,
      evAvg: evAvg,
      mistakes: m,
      lastUpdated: DateTime.now(),
    );
    await _save();
    notifyListeners();
  }

  Future<void> addEvalResult(double score) async {
    _evalTotal += 1;
    if (score >= 1) _evalCorrect += 1;
    _evalHistory.add(score);
    if (_evalHistory.length > 50) _evalHistory.removeAt(0);
    await _save();
    notifyListeners();
  }

  Future<void> resetEvalStats() async {
    _evalTotal = 0;
    _evalCorrect = 0;
    _evalHistory.clear();
    await _save();
    notifyListeners();
  }

  Future<PackPlayStats> getStatsForPack(String packId) async {
    if (!Hive.isBoxOpen('session_logs')) {
      await Hive.initFlutter();
      await Hive.openBox('session_logs');
    }
    final box = Hive.box('session_logs');
    int launches = 0;
    int hands = 0;
    int mistakes = 0;
    for (final v in box.values.whereType<Map>()) {
      final log = SessionLog.fromJson(Map<String, dynamic>.from(v));
      if (log.templateId == packId) {
        launches += 1;
        hands += log.correctCount + log.mistakeCount;
        mistakes += log.mistakeCount;
      }
    }
    return PackPlayStats(
      launches: launches,
      totalTrained: hands,
      mistakes: mistakes,
    );
  }

  Future<TrainingStats> aggregate({
    required TemplateStorageService templates,
    required StreakService streak,
    int limit = 3,
  }) async {
    final packs = <PackAccuracy>[];
    for (final t in templates.templates) {
      final stat = await TrainingPackStatsService.getStats(t.id);
      if (stat != null) {
        packs.add(
          PackAccuracy(id: t.id, name: t.name, accuracy: stat.accuracy),
        );
      }
    }
    final avg = packs.isNotEmpty
        ? packs.map((e) => e.accuracy).reduce((a, b) => a + b) / packs.length
        : 0.0;
    packs.sort((a, b) => b.accuracy.compareTo(a.accuracy));
    final top = packs.take(limit).toList();
    final bottom = packs.reversed.take(limit).toList();
    return TrainingStats(
      totalSpots: handsReviewed,
      avgAccuracy: avg,
      streakDays: streak.streak.value,
      topPacks: top,
      bottomPacks: bottom,
    );
  }

  @override
  void dispose() {
    _sessionController.close();
    _handsController.close();
    _mistakeController.close();
    super.dispose();
  }
}
