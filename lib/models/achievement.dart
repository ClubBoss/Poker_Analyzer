import 'package:flutter/material.dart';
import 'level_stage.dart';

class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final int progress;
  final List<int> thresholds;

  const Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
    required this.thresholds,
  });

  int get levelIndex {
    var idx = 0;
    for (final t in thresholds) {
      if (progress >= t) {
        idx++;
      } else {
        break;
      }
    }
    return idx;
  }

  LevelStage get level =>
      LevelStage.values[levelIndex.clamp(0, thresholds.length - 1)];

  bool get completed => levelIndex >= thresholds.length;

  int get nextTarget =>
      levelIndex < thresholds.length ? thresholds[levelIndex] : thresholds.last;

  double get pct {
    if (completed) return 1.0;
    final prev = levelIndex == 0 ? 0 : thresholds[levelIndex - 1];
    final next = thresholds[levelIndex];
    return ((progress - prev) / (next - prev)).clamp(0.0, 1.0);
  }

  Achievement copyWith({int? progress}) => Achievement(
    title: title,
    description: description,
    icon: icon,
    progress: progress ?? this.progress,
    thresholds: thresholds,
  );
}
