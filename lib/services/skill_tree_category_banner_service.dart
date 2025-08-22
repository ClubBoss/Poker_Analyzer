import 'package:flutter/material.dart';

import '../models/skill_tree_category_visual.dart';

/// Provides visual metadata for skill tree categories.
class SkillTreeCategoryBannerService {
  SkillTreeCategoryBannerService();

  /// Returns visuals for [category].
  SkillTreeCategoryVisual getVisual(String category) {
    switch (category) {
      case 'Push/Fold':
        return SkillTreeCategoryVisual(
          category: category,
          emoji: '💥',
          color: Colors.redAccent,
        );
      case 'Postflop':
        return SkillTreeCategoryVisual(
          category: category,
          emoji: '♠️',
          color: Colors.blueAccent,
        );
      case 'ICM':
        return SkillTreeCategoryVisual(
          category: category,
          emoji: '🏆',
          color: Colors.orangeAccent,
        );
      case '3bet':
        return SkillTreeCategoryVisual(
          category: category,
          emoji: '🎯',
          color: Colors.purpleAccent,
        );
      default:
        return SkillTreeCategoryVisual(
          category: category,
          emoji: '🃏',
          color: Colors.grey,
        );
    }
  }
}
