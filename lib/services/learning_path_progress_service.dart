import 'package:flutter/material.dart';

enum LearningItemStatus { locked, available, completed }

class LearningStageItem {
  final String title;
  final IconData icon;
  final double progress;
  final LearningItemStatus status;

  const LearningStageItem({
    required this.title,
    required this.icon,
    required this.progress,
    required this.status,
  });
}

class LearningStageState {
  final String title;
  final List<LearningStageItem> items;

  const LearningStageState({required this.title, required this.items});
}

class LearningPathProgressService {
  LearningPathProgressService._();
  static final instance = LearningPathProgressService._();

  Future<List<LearningStageState>> getCurrentStageState() async {
    return [
      LearningStageState(title: 'Beginner', items: const [
        LearningStageItem(
          title: 'Push/Fold Basics',
          icon: Icons.play_circle_fill,
          progress: 1.0,
          status: LearningItemStatus.completed,
        ),
        LearningStageItem(
          title: '10bb Ranges',
          icon: Icons.school,
          progress: 0.6,
          status: LearningItemStatus.available,
        ),
        LearningStageItem(
          title: '15bb Ranges',
          icon: Icons.school,
          progress: 0.0,
          status: LearningItemStatus.locked,
        ),
      ]),
      LearningStageState(title: 'Intermediate', items: const [
        LearningStageItem(
          title: 'ICM Concepts',
          icon: Icons.insights,
          progress: 0.0,
          status: LearningItemStatus.locked,
        ),
        LearningStageItem(
          title: 'Shoving Charts 20bb',
          icon: Icons.table_chart,
          progress: 0.0,
          status: LearningItemStatus.locked,
        ),
      ]),
      LearningStageState(title: 'Advanced', items: const [
        LearningStageItem(
          title: 'Exploit Spots',
          icon: Icons.lightbulb_outline,
          progress: 0.0,
          status: LearningItemStatus.locked,
        ),
      ]),
    ];
  }
}
