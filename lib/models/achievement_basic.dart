import 'package:flutter/material.dart';

/// Basic achievement model used by [AchievementsEngine].
class AchievementBasic {
  final String id;
  final String title;
  final String description;
  bool isUnlocked;
  DateTime? unlockDate;

  AchievementBasic({
    required this.id,
    required this.title,
    required this.description,
    this.isUnlocked = false,
    this.unlockDate,
  });

  AchievementBasic copyWith({
    bool? isUnlocked,
    DateTime? unlockDate,
  }) {
    return AchievementBasic(
      id: id,
      title: title,
      description: description,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockDate: unlockDate ?? this.unlockDate,
    );
  }
}
