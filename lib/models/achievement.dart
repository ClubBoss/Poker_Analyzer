import 'package:flutter/material.dart';
class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final int progress;
  final int target;

  const Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
    required this.target,
  });

  bool get completed => progress >= target;

  Achievement copyWith({int? progress}) => Achievement(
        title: title,
        description: description,
        icon: icon,
        progress: progress ?? this.progress,
        target: target,
      );
}
