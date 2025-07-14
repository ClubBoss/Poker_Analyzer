import "package:flutter/material.dart";
class AchievementInfo {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int progress;
  final int target;
  final String category;
  const AchievementInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
    required this.target,
    required this.category,
  });
  bool get completed => progress >= target;
}
