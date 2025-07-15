import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/training_pack_template.dart';
import '../models/session_log.dart';

class TrainingPackStat {
  final double accuracy;
  final DateTime last;
  final int lastIndex;
  final double preEvPct;
  final double preIcmPct;
  final double postEvPct;
  final double postIcmPct;
  final double evSum;
  final double icmSum;
  TrainingPackStat({
    required this.accuracy,
    required this.last,
    this.lastIndex = 0,
    this.preEvPct = 0,
    this.preIcmPct = 0,
    this.postEvPct = 0,
    this.postIcmPct = 0,
    this.evSum = 0,
    this.icmSum = 0,
  });

  Map<String, dynamic> toJson() => {
        'accuracy': accuracy,
        'last': last.millisecondsSinceEpoch,
        if (lastIndex > 0) 'idx': lastIndex,
        if (preEvPct > 0) 'preEv': preEvPct,
        if (preIcmPct > 0) 'preIcm': preIcmPct,
        if (postEvPct > 0) 'postEv': postEvPct,
        if (postIcmPct > 0) 'postIcm': postIcmPct,
        if (evSum != 0) 'evSum': evSum,
        if (icmSum != 0) 'icmSum': icmSum,
      };

  factory TrainingPackStat.fromJson(Map<String, dynamic> j) => TrainingPackStat(
        accuracy: (j['accuracy'] as num?)?.toDouble() ?? 0,
        last: DateTime.fromMillisecondsSinceEpoch(
            (j['last'] as num?)?.toInt() ?? 0),
        lastIndex: (j['idx'] as num?)?.toInt() ?? 0,
        preEvPct: (j['preEv'] as num?)?.toDouble() ?? 0,
        preIcmPct: (j['preIcm'] as num?)?.toDouble() ?? 0,
        postEvPct: (j['postEv'] as num?)?.toDouble() ?? 0,
        postIcmPct: (j['postIcm'] as num?)?.toDouble() ?? 0,
        evSum: (j['evSum'] as num?)?.toDouble() ?? 0,
        icmSum: (j['icmSum'] as num?)?.toDouble() ?? 0,
      );
}

class TrainingPackStatsService {
  static const _prefix = 'tpl_stat_';
  static const _histPrefix = 'tpl_hist_';
  static const _skillKey = 'stats_skill_stats';

  static Future<void> recordSession(
    String templateId,
    int correct,
    int total, {
    required double preEvPct,
    required double preIcmPct,
    required double postEvPct,
    required double postIcmPct,
    double evSum = 0,
    double icmSum = 0,
  }) async {
    if (templateId.isEmpty || total <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$templateId');
    int lastIndex = 0;
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map<String, dynamic>) {
          lastIndex = (data['idx'] as num?)?.toInt() ?? 0;
        }
      } catch (_) {}
    }
    final stat = TrainingPackStat(
      accuracy: correct / total,
      last: DateTime.now(),
      lastIndex: lastIndex,
      preEvPct: preEvPct,
      preIcmPct: preIcmPct,
      postEvPct: postEvPct,
      postIcmPct: postIcmPct,
      evSum: evSum,
      icmSum: icmSum,
    );
    await prefs.setString('$_prefix$templateId', jsonEncode(stat.toJson()));
    final histRaw = prefs.getString('$_histPrefix$templateId');
    final list = <Map<String, dynamic>>[];
    if (histRaw != null) {
      try {
        final data = jsonDecode(histRaw);
        if (data is List) {
          list.addAll(data.map((e) => Map<String, dynamic>.from(e as Map)));
        }
      } catch (_) {}
    }
    list.add(stat.toJson());
    while (list.length > 20) {
      list.removeAt(0);
    }
    await prefs.setString('$_histPrefix$templateId', jsonEncode(list));
  }

  static Future<TrainingPackStat?> getStats(String templateId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$templateId');
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) {
        final stat = TrainingPackStat.fromJson(data);
        if (!data.containsKey('preEv') &&
            !data.containsKey('postEv') &&
            !data.containsKey('preIcm') &&
            !data.containsKey('postIcm')) {
          await prefs.setString(
              '$_prefix$templateId', jsonEncode(stat.toJson()));
        }
        return stat;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> setLastIndex(String templateId, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$templateId');
    TrainingPackStat stat;
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map<String, dynamic>) {
          stat = TrainingPackStat.fromJson(data);
        } else {
          stat = TrainingPackStat(accuracy: 0, last: DateTime.now());
        }
      } catch (_) {
        stat = TrainingPackStat(accuracy: 0, last: DateTime.now());
      }
    } else {
      stat = TrainingPackStat(accuracy: 0, last: DateTime.now());
    }
    stat = TrainingPackStat(
      accuracy: stat.accuracy,
      last: stat.last,
      lastIndex: index,
      preEvPct: stat.preEvPct,
      preIcmPct: stat.preIcmPct,
      postEvPct: stat.postEvPct,
      postIcmPct: stat.postIcmPct,
      evSum: stat.evSum,
      icmSum: stat.icmSum,
    );
    await prefs.setString('$_prefix$templateId', jsonEncode(stat.toJson()));
  }

  static Future<List<TrainingPackTemplate>> recentlyPractisedTemplates(
    List<TrainingPackTemplate> templates, {
    int days = 3,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final list = <MapEntry<TrainingPackTemplate, DateTime>>[];
    for (final t in templates) {
      final raw = prefs.getString('$_prefix${t.id}');
      if (raw == null) continue;
      try {
        final data = jsonDecode(raw);
        if (data is Map<String, dynamic>) {
          final stat = TrainingPackStat.fromJson(data);
          if (stat.last.isAfter(cutoff)) {
            list.add(MapEntry(t, stat.last));
          }
        }
      } catch (_) {}
    }
    list.sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in list) e.key];
  }

  static Future<List<TrainingPackTemplate>> mostPlayedTemplates(
      List<TrainingPackTemplate> templates, int limit) async {
    if (!Hive.isBoxOpen('session_logs')) {
      await Hive.initFlutter();
      await Hive.openBox('session_logs');
    }
    final box = Hive.box('session_logs');
    final count = <String, int>{};
    for (final v in box.values.whereType<Map>()) {
      final log = SessionLog.fromJson(Map<String, dynamic>.from(v));
      count.update(log.templateId, (c) => c + 1, ifAbsent: () => 1);
    }
    final list = [for (final t in templates) if (count[t.id] != null) t];
    list.sort((a, b) {
      final r = (count[b.id] ?? 0).compareTo(count[a.id] ?? 0);
      return r == 0 ? a.name.compareTo(b.name) : r;
    });
    if (limit < list.length) return list.sublist(0, limit);
    return list;
  }

  static Future<List<TrainingPackStat>> history(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_histPrefix$id');
    if (raw == null) return [];
    try {
      final data = jsonDecode(raw);
      if (data is List) {
        return [
          for (final e in data)
            if (e is Map)
              TrainingPackStat.fromJson(Map<String, dynamic>.from(e as Map))
        ];
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, double>> getCategoryStats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_skillKey);
    if (raw == null) return {};
    try {
      final data = jsonDecode(raw);
      if (data is Map) {
        final map = <String, double>{};
        for (final e in data.entries) {
          final v = e.value;
          if (v is Map) {
            final played = (v['hands'] as num?)?.toInt() ?? 0;
            final miss = (v['mistakes'] as num?)?.toInt() ?? 0;
            if (played > 0) {
              map[e.key as String] = (played - miss) / played;
            }
          }
        }
        return map;
      }
    } catch (_) {}
    return {};
  }
}
