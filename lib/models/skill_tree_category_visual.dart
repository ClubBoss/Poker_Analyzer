import 'package:flutter/material.dart';

/// Visual metadata for a skill tree category.
class SkillTreeCategoryVisual {
  final String iconAsset;
  final Color color;
  final String displayName;

  const SkillTreeCategoryVisual({
    required this.iconAsset,
    required this.color,
    required this.displayName,
  });
}
