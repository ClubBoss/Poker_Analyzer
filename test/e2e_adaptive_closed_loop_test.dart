import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/injected_path_module.dart';
import 'package:poker_analyzer/services/learning_path_store.dart';
import 'package:poker_analyzer/services/adaptive_training_planner.dart';
import 'package:poker_analyzer/services/user_skill_model_service.dart';

InjectedPathModule _module(String id, List<String> tags) => InjectedPathModule(
      moduleId: id,
      clusterId: 'c$id',
      themeName: 't',
      theoryIds: const [],
      boosterPackIds: const [],
      assessmentPackId: 'a$id',
      createdAt: DateTime.now(),
      triggerReason: 'test',
      metrics: {'clusterTags': tags},
    );

Map<String, dynamic> _skillJson(double mastery) {
  final now = DateTime.now().toIso8601String();
  return {'mastery': mastery, 'confidence': 0.0, 'lastSeen': now, 'seenCount': 0};
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('planner prioritizes tags with positive outcomes', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('skillModel.user', jsonEncode({
      'a': _skillJson(0.2),
      'b': _skillJson(0.2),
    }));
    await prefs.setInt('planner.maxTagsPerPlan', 1);
    await prefs.setInt('planner.budgetPaddingMins', 0);
    await prefs.setDouble('bandit.alpha.user.b', 5.0);
    await prefs.setDouble('bandit.beta.user.b', 1.0);

    final planner = AdaptiveTrainingPlanner();
    final store = LearningPathStore(rootDir: 'test_lp');
    final plan0 = await planner.plan(userId: 'user', durationMinutes: 20);
    expect(plan0.clusters.first.tags.contains('b'), true);

    final m1 = _module('m1', ['a']);
    await store.upsertModule('user', m1);
    await store.updateModuleStatus('user', 'm1', 'in_progress');
    await store.updateModuleStatus('user', 'm1', 'completed', passRate: 0.8);

    await prefs.setString('skillModel.user', jsonEncode({
      'a': _skillJson(0.2),
      'b': _skillJson(0.2),
    }));

    final plan1 = await planner.plan(userId: 'user', durationMinutes: 20);
    expect(plan1.clusters.first.tags.contains('a'), true);

    await Directory('test_lp').delete(recursive: true);
  });
}
