import 'package:flutter/material.dart';

import '../main.dart';
import '../screens/skill_tree_screen.dart';

/// Handles navigation to skill tree tracks.
class SkillTreeNavigator {
  SkillTreeNavigator();

  static SkillTreeNavigator instance = const SkillTreeNavigator();

  /// Opens the track with [trackId].
  Future<void> openTrack(String trackId) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    await Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => SkillTreeScreen(category: trackId)),
    );
  }
}
