import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/mistake_tag.dart';
import '../models/mistake_tag_history_entry.dart';
import '../models/training_spot_attempt.dart';
import 'tag_mastery_trend_service.dart';

class MistakeTagHistoryService {
  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'app_data', 'mistake_tag_history.json'));
  }

  static Future<List<MistakeTagHistoryEntry>> _load(File file) async {
    if (!await file.exists()) return [];
    try {
      final data = jsonDecode(await file.readAsString());
      if (data is List) {
        return [
          for (final e in data)
            if (e is Map)
              MistakeTagHistoryEntry.fromJson(Map<String, dynamic>.from(e)),
        ];
      }
    } catch (_) {}
    return [];
  }

  static Future<void> logTags(
    String packId,
    TrainingSpotAttempt attempt,
    List<MistakeTag> tags,
  ) async {
    if (tags.isEmpty) return;
    final file = await _file();
    final list = await _load(file);
    list.insert(
      0,
      MistakeTagHistoryEntry(
        timestamp: DateTime.now(),
        packId: packId,
        spotId: attempt.spot.id,
        tags: tags,
        evDiff: attempt.evDiff,
      ),
    );
    while (list.length > 500) {
      list.removeLast();
    }
    await file.create(recursive: true);
    await file.writeAsString(
      jsonEncode([for (final e in list) e.toJson()]),
      flush: true,
    );
  }

  static Future<List<MistakeTagHistoryEntry>> _history() async {
    final file = await _file();
    return _load(file);
  }

  static Future<Map<MistakeTag, int>> getTagsByFrequency() async {
    final list = await _history();
    final map = <MistakeTag, int>{};
    for (final entry in list) {
      for (final t in entry.tags) {
        map[t] = (map[t] ?? 0) + 1;
      }
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sorted) e.key: e.value};
  }

  static Future<List<MistakeTagHistoryEntry>> getRecentMistakesByTag(
    MistakeTag tag, {
    int limit = 20,
  }) async {
    final list = await _history();
    final filtered = [
      for (final e in list)
        if (e.tags.contains(tag)) e,
    ];
    return filtered.take(limit).toList();
  }

  static Future<TagTrend> getTrend(MistakeTag tag, {int days = 14}) async {
    final list = await getRecentMistakesByTag(tag, limit: 1000);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: days - 1));
    final counts = List<int>.filled(days, 0);
    for (final e in list) {
      final d = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      if (d.isBefore(start) || d.isAfter(today)) continue;
      final idx = d.difference(start).inDays;
      if (idx >= 0 && idx < days) counts[idx] += 1;
    }
    final smoothed = List<double>.generate(days, (i) {
      double sum = 0;
      int c = 0;
      for (int j = i - 2; j <= i; j++) {
        if (j >= 0 && j < days) {
          sum += counts[j];
          c += 1;
        }
      }
      return c > 0 ? sum / c : 0;
    });
    if (smoothed.length < 2) return TagTrend.flat;
    final n = smoothed.length;
    final xs = [for (var i = 0; i < n; i++) i + 1];
    final sumX = xs.reduce((a, b) => a + b);
    final sumX2 = xs.map((e) => e * e).reduce((a, b) => a + b);
    final sumY = smoothed.reduce((a, b) => a + b);
    final sumXY = [
      for (var i = 0; i < n; i++) xs[i] * smoothed[i],
    ].reduce((a, b) => a + b);
    final denom = n * sumX2 - sumX * sumX;
    double slope = 0;
    if (denom != 0) {
      slope = (n * sumXY - sumX * sumY) / denom;
    }
    const eps = 0.5;
    if (slope > eps) return TagTrend.rising;
    if (slope < -eps) return TagTrend.falling;
    return TagTrend.flat;
  }

  /// Returns the most recent mistake history entries.
  static Future<List<MistakeTagHistoryEntry>> getRecentHistory({
    int limit = 20,
  }) async {
    final list = await _history();
    return list.take(limit).toList();
  }
}
