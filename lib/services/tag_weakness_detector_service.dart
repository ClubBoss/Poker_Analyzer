import 'package:hive_flutter/hive_flutter.dart';

class TagWeaknessDetectorService {
  static const _boxName = 'pack_review_stats_box';

  Future<Box<dynamic>> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.initFlutter();
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<List<String>> getWeakTags({int maxSessions = 20}) async {
    final box = await _openBox();
    final start = box.length > maxSessions ? box.length - maxSessions : 0;
    final Map<String, _TagStats> stats = {};

    for (var i = start; i < box.length; i++) {
      final record = Map<String, dynamic>.from(box.getAt(i));
      final tags = Map<String, dynamic>.from(record['tagBreakdown'] ?? {});
      for (final entry in tags.entries) {
        final tag = entry.key;
        final data = Map<String, dynamic>.from(entry.value);
        final total = data['total'] as int? ?? 0;
        final correct = data['correct'] as int? ?? 0;
        final s = stats.putIfAbsent(tag, () => _TagStats());
        s.total += total;
        s.correct += correct;
      }
    }

    final weakTags = <String>[];
    stats.forEach((tag, s) {
      if (s.total >= 3) {
        final accuracy = s.correct / s.total;
        if (accuracy < 0.7) {
          weakTags.add(tag);
        }
      }
    });

    weakTags.sort((a, b) {
      final accA = stats[a]!.correct / stats[a]!.total;
      final accB = stats[b]!.correct / stats[b]!.total;
      return accA.compareTo(accB);
    });

    return weakTags;
  }
}

class _TagStats {
  int total = 0;
  int correct = 0;
}
