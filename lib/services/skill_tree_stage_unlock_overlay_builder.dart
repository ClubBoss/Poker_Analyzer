import 'package:flutter/material.dart';

/// Builds overlay widgets indicating lock/unlock/completed state for skill tree stages.
class SkillTreeStageUnlockOverlayBuilder {
  const SkillTreeStageUnlockOverlayBuilder();

  /// Returns a positioned overlay to display above a stage header.
  Widget buildOverlay({
    required int level,
    required bool isUnlocked,
    required bool isCompleted,
  }) {
    if (isCompleted) {
      return const Positioned(
        right: 0,
        top: 0,
        child: Icon(Icons.check_circle, color: Colors.green, size: 20),
      );
    }

    if (!isUnlocked) {
      final tooltip = level <= 0
          ? 'Stage locked'
          : 'Complete level ${level - 1} to unlock';
      return Positioned.fill(
        child: Tooltip(
          message: tooltip,
          child: Container(
            color: Colors.black45,
            alignment: Alignment.center,
            child: const Icon(Icons.lock, color: Colors.white, size: 28),
          ),
        ),
      );
    }

    // Stage is unlocked but not completed.
    return const Positioned(
      right: 0,
      top: 0,
      child: Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
    );
  }
}
