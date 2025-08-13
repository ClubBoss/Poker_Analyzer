import 'package:flutter/material.dart';

class SimpleAchievement {
  final String id;
  final String title;
  final IconData icon;
  final bool unlocked;
  final DateTime? date;

  const SimpleAchievement({
    required this.id,
    required this.title,
    required this.icon,
    this.unlocked = false,
    this.date,
  });

  SimpleAchievement copyWith({bool? unlocked, DateTime? date}) =>
      SimpleAchievement(
        id: id,
        title: title,
        icon: icon,
        unlocked: unlocked ?? this.unlocked,
        date: date ?? this.date,
      );
}
