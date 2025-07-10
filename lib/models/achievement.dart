import "package:flutter/material.dart";
import "level_stage.dart";

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

  int get level {
    var l = 0;
    for (final t in thresholds) {
      if (progress >= t) l += 1;
    }
    return l.clamp(0, thresholds.length);
  }

  LevelStage get stage => LevelStage.values[(level.clamp(1, 5)) - 1];

  int get target =>
      level < thresholds.length ? thresholds[level] : thresholds.last;

  bool get completed => progress >= target;

  Achievement copyWith({int? progress}) => Achievement(
        title: title,
        description: description,
        icon: icon,
        progress: progress ?? this.progress,
        thresholds: thresholds,
      );
}
