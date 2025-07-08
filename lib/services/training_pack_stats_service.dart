import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
}
