import 'package:hive_flutter/hive_flutter.dart';

import '../models/training_pack.dart';
import '../models/v2/training_pack_template.dart';

class PackReviewStatsExporter {
  static const _boxName = 'pack_review_stats_box';

  const PackReviewStatsExporter();

  Future<Box<dynamic>> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.initFlutter();
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<void> exportSessionStats(
    TrainingPackTemplate template,
    TrainingSessionResult result,
    Duration elapsed,
  ) async {
    final box = await _openBox();

    final tagStats = <String, Map<String, int>>{};
    final len = result.tasks.length < template.spots.length
        ? result.tasks.length
        : template.spots.length;
    for (var i = 0; i < len; i++) {
      final spot = template.spots[i];
      final task = result.tasks[i];
      for (final tag in spot.tags) {
        final stat = tagStats.putIfAbsent(
          tag,
          () => {'total': 0, 'correct': 0},
        );
        stat['total'] = (stat['total'] ?? 0) + 1;
        if (task.correct) {
          stat['correct'] = (stat['correct'] ?? 0) + 1;
        }
      }
    }

    final accuracy = result.total == 0 ? 0.0 : result.correct / result.total;
    final record = {
      'templateId': template.id,
      'templateName': template.name,
      'date': result.date.toIso8601String(),
      'accuracy': accuracy,
      'totalHands': result.total,
      'correctHands': result.correct,
      'durationSeconds': elapsed.inSeconds,
      'tagBreakdown': tagStats,
      'outcomes': {
        'correct': result.correct,
        'incorrect': result.total - result.correct,
      },
    };
    await box.add(record);
  }
}
