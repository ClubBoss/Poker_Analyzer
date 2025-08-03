import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';

import 'skill_loss_detector.dart';
import 'tag_mastery_history_service.dart';

/// Periodically checks for skill loss on tags and caches results.
class TagInsightReminderEngine {
  final TagMasteryHistoryService history;
  TagInsightReminderEngine({required this.history});

  static const _lastKey = 'tag_insight_reminder_last';
  static const _dataKey = 'tag_insight_reminder_data';

  Future<List<SkillLoss>> loadLosses({int days = 14}) async {
    final prefs = await PreferencesService.getInstance();
    final now = DateTime.now();
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    if (last != null && now.difference(last) < const Duration(days: 1)) {
      final raw = prefs.getString(_dataKey);
      if (raw != null) {
        try {
          final list = jsonDecode(raw);
          if (list is List) {
            return [
              for (final item in list)
                if (item is Map)
                  SkillLoss(
                    tag: item['tag'] ?? '',
                    drop: (item['drop'] as num?)?.toDouble() ?? 0,
                    trend: item['trend'] ?? '',
                  )
            ];
          }
        } catch (_) {}
      }
    }

    final hist = await history.getHistory();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: days - 1));
    final map = <String, List<double>>{};
    for (final entry in hist.entries) {
      final data = List<double>.filled(days, 0);
      for (final e in entry.value) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        if (d.isBefore(start) || d.isAfter(today)) continue;
        final idx = d.difference(start).inDays;
        if (idx >= 0 && idx < days) data[idx] += e.xp.toDouble();
      }
      map[entry.key] = data;
    }
    final losses = const SkillLossDetector().detect(map).take(2).toList();
    final encoded = jsonEncode([
      for (final l in losses)
        {'tag': l.tag, 'drop': l.drop, 'trend': l.trend}
    ]);
    await prefs.setString(_lastKey, now.toIso8601String());
    await prefs.setString(_dataKey, encoded);
    return losses;
  }
}
