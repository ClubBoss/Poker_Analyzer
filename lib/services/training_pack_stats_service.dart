import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/training_pack_template.dart';
import '../models/session_log.dart';

class TrainingPackStat {
  final double accuracy;
  final DateTime last;
  TrainingPackStat({required this.accuracy, required this.last});

  Map<String, dynamic> toJson() => {
        'accuracy': accuracy,
        'last': last.millisecondsSinceEpoch,
      };

  factory TrainingPackStat.fromJson(Map<String, dynamic> j) => TrainingPackStat(
        accuracy: (j['accuracy'] as num?)?.toDouble() ?? 0,
        last: DateTime.fromMillisecondsSinceEpoch(
            (j['last'] as num?)?.toInt() ?? 0),
      );
}

class TrainingPackStatsService {
  static const _prefix = 'tpl_stat_';

  static Future<void> recordSession(
      String templateId, int correct, int total) async {
    if (templateId.isEmpty || total <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final stat = TrainingPackStat(
      accuracy: correct / total,
      last: DateTime.now(),
    );
    await prefs.setString('$_prefix$templateId', jsonEncode(stat.toJson()));
  }

  static Future<TrainingPackStat?> getStats(String templateId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$templateId');
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) {
        return TrainingPackStat.fromJson(data);
      }
    } catch (_) {}
    return null;
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
}
