import 'package:flutter/material.dart';
import 'level_stage.dart';

class AchievementInfo {
  final String id;
  final String title;
  final String description;
  final int progress;
  final List<int> thresholds;
  final List<IconData> iconsPerLevel;
  final String category;

  const AchievementInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.thresholds,
    required this.iconsPerLevel,
    required this.category,
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

  LevelStage get maxLevel => LevelStage.values[thresholds.length - 1];

  int get _prevTarget => levelIndex == 0 ? 0 : thresholds[levelIndex - 1];

  int get target =>
      levelIndex < thresholds.length ? thresholds[levelIndex] : thresholds.last;

  int get progressInLevel => progress - _prevTarget;

  int get targetInLevel => target - _prevTarget;

  IconData get icon =>
      iconsPerLevel[level.index.clamp(0, iconsPerLevel.length - 1)];

  bool get completed => levelIndex >= thresholds.length;
}
