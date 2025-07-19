import 'package:flutter/material.dart';

/// Simple representation of an unlockable achievement.
class AchievementV2 {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool Function() condition;
  DateTime? unlockedAt;

  AchievementV2({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.condition,
    this.unlockedAt,
  });

  bool get unlocked => unlockedAt != null;
}
