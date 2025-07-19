import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LearningItemStatus { locked, available, completed }

class LearningStageItem {
  final String title;
  final IconData icon;
  final double progress;
  final LearningItemStatus status;
  final String? templateId;

  const LearningStageItem({
    required this.title,
    required this.icon,
    required this.progress,
    required this.status,
    this.templateId,
  });
}

class LearningStageState {
  final String title;
  final List<LearningStageItem> items;

  const LearningStageState({required this.title, required this.items});

  static double computeStageProgress(List<LearningStageItem> items) {
    if (items.isEmpty) return 0.0;
    var sum = 0.0;
    for (final item in items) {
      switch (item.status) {
        case LearningItemStatus.completed:
          sum += 1.0;
          break;
        case LearningItemStatus.available:
          sum += 0.5;
          break;
        case LearningItemStatus.locked:
        default:
          sum += 0.0;
      }
    }
    return sum / items.length;
  }
}

class LearningPathProgressService {
  LearningPathProgressService._();
  static final instance = LearningPathProgressService._();

  bool mock = false;
  final Map<String, bool> _mockCompleted = {};

  static String _key(String id) => 'learning_completed_$id';

  Future<void> markCompleted(String templateId) async {
    if (mock) {
      _mockCompleted[templateId] = true;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(templateId), true);
  }

  Future<bool> isCompleted(String templateId) async {
    if (mock) return _mockCompleted[templateId] == true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(templateId)) ?? false;
  }

  Future<List<LearningStageState>> getCurrentStageState() async {
    final prefs = mock ? null : await SharedPreferences.getInstance();

    bool completed(String id) {
      if (mock) return _mockCompleted[id] == true;
      return prefs?.getBool(_key(id)) ?? false;
    }

    final stages = [
      LearningStageState(title: 'Beginner', items: [
        LearningStageItem(
          title: 'Push/Fold Basics',
          icon: Icons.play_circle_fill,
          progress: 1.0,
          status: LearningItemStatus.locked,
          templateId: 'starter_pushfold_10bb',
        ),
        LearningStageItem(
          title: '10bb Ranges',
          icon: Icons.school,
          progress: 0.6,
          status: LearningItemStatus.locked,
          templateId: 'starter_pushfold_10bb',
        ),
        LearningStageItem(
          title: '15bb Ranges',
          icon: Icons.school,
          progress: 0.0,
          status: LearningItemStatus.locked,
          templateId: 'starter_pushfold_15bb',
        ),
      ]),
      LearningStageState(title: 'Intermediate', items: [
        LearningStageItem(
          title: 'ICM Concepts',
          icon: Icons.insights,
          progress: 0.0,
          status: LearningItemStatus.locked,
          templateId: 'starter_pushfold_12bb',
        ),
        LearningStageItem(
          title: 'Shoving Charts 20bb',
          icon: Icons.table_chart,
          progress: 0.0,
          status: LearningItemStatus.locked,
          templateId: 'starter_pushfold_20bb',
        ),
      ]),
      LearningStageState(title: 'Advanced', items: [
        LearningStageItem(
          title: 'Exploit Spots',
          icon: Icons.lightbulb_outline,
          progress: 0.0,
          status: LearningItemStatus.locked,
        ),
      ]),
    ];

    final result = <LearningStageState>[];
    for (final stage in stages) {
      final items = <LearningStageItem>[];
      var unlock = true;
      for (final item in stage.items) {
        final done =
            item.templateId != null && completed(item.templateId!);
        final status = done
            ? LearningItemStatus.completed
            : unlock
                ? LearningItemStatus.available
                : LearningItemStatus.locked;
        items.add(LearningStageItem(
          title: item.title,
          icon: item.icon,
          progress: item.progress,
          status: status,
          templateId: item.templateId,
        ));
        unlock = done;
      }
      result.add(LearningStageState(title: stage.title, items: items));
    }
    return result;
  }
}
