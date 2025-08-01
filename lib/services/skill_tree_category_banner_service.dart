import 'package:flutter/material.dart';
import '../models/skill_tree_category_visual.dart';

/// Provides visual info for skill tree categories used across the UI.
class SkillTreeCategoryBannerService {
  const SkillTreeCategoryBannerService();

  static const Map<String, SkillTreeCategoryVisual> _visuals = {
    'Push/Fold': SkillTreeCategoryVisual(
      iconAsset: 'assets/images/red_chip.png',
      color: Color(0xFFE53935),
      displayName: 'Push/Fold',
    ),
    'Postflop': SkillTreeCategoryVisual(
      iconAsset: 'assets/images/postflop.png',
      color: Color(0xFF2196F3),
      displayName: 'Postflop',
    ),
    'ICM': SkillTreeCategoryVisual(
      iconAsset: 'assets/images/icm.png',
      color: Color(0xFF8E24AA),
      displayName: 'ICM',
    ),
    '3bet': SkillTreeCategoryVisual(
      iconAsset: 'assets/images/three_bet.png',
      color: Color(0xFF3949AB),
      displayName: '3bet',
    ),
  };

  /// Returns visual metadata for [category].
  /// Falls back to a default if the category is unknown.
  SkillTreeCategoryVisual getVisual(String category) {
    return _visuals[category] ??
        const SkillTreeCategoryVisual(
          iconAsset: 'assets/images/default.png',
          color: Colors.grey,
          displayName: '',
        );
  }
}
