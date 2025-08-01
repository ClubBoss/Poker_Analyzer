import 'package:flutter/material.dart';

/// Visual metadata for a skill tree category.
class SkillTreeCategoryVisual {
  final String category;
  final String emoji;
  final Color color;

  const SkillTreeCategoryVisual({
    required this.category,
    required this.emoji,
    required this.color,
  });
}
