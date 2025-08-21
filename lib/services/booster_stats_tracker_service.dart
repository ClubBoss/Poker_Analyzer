import 'package:hive_flutter/hive_flutter.dart';

import '../models/training_pack.dart';
import '../models/training_pack_template.dart';

class BoosterTagProgress {
  final DateTime date;
  final double accuracy;

  BoosterTagProgress({required this.date, required this.accuracy});
}

/// Records booster session performance and retrieves progress over time.
class BoosterStatsTrackerService {
  static const _boxName = 'booster_stats_box';

  Future<Box<dynamic>> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.initFlutter();
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  /// Logs the [result] of a booster session for [tpl].
  Future<void> logBoosterResult(
    TrainingPackTemplate tpl,
    TrainingSessionResult result,
  ) async {
    final box = await _openBox();
    final tags = tpl.tags.map((e) => e.trim().toLowerCase()).toList();
    final totalAccuracy = result.total > 0
        ? result.correct / result.total
        : 0.0;
    final accuracyPerTag = {for (final t in tags) t: totalAccuracy};
    await box.add({
      'date': result.date.millisecondsSinceEpoch,
      'tags': tags,
      'accuracyPerTag': accuracyPerTag,
      'totalAccuracy': totalAccuracy,
    });
  }

  /// Returns historical accuracy for [tag] ordered by date.
  Future<List<BoosterTagProgress>> getProgressForTag(String tag) async {
    final box = await _openBox();
    final normTag = tag.trim().toLowerCase();
    final list = <BoosterTagProgress>[];
    for (var i = 0; i < box.length; i++) {
      final raw = box.getAt(i);
      if (raw is Map) {
        final data = Map<String, dynamic>.from(raw);
        final accMap = Map<String, dynamic>.from(data['accuracyPerTag'] ?? {});
        final acc = (accMap[normTag] as num?)?.toDouble();
        if (acc != null) {
          final ts = DateTime.fromMillisecondsSinceEpoch(
            (data['date'] as num?)?.toInt() ?? 0,
          );
          list.add(BoosterTagProgress(date: ts, accuracy: acc));
        }
      }
    }
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }
}
