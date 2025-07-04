import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_pack_template_model.dart';
import '../repositories/training_pack_template_repository.dart';
import 'training_pack_cloud_sync_service.dart';
import 'goal_progress_cloud_service.dart';

class TrainingPackTemplateStorageService extends ChangeNotifier {
  static const _key = 'training_pack_templates';

  TrainingPackTemplateStorageService({this.cloud, this.goals});

  final TrainingPackCloudSyncService? cloud;
  final GoalProgressCloudService? goals;

  final Map<String, Map<String, dynamic>> _goalProgress = {};
  Map<String, Map<String, dynamic>> get goalProgress =>
      {for (final e in _goalProgress.entries) e.key: Map.unmodifiable(e.value)};

  final List<TrainingPackTemplateModel> _templates = [];
  List<TrainingPackTemplateModel> get templates => List.unmodifiable(_templates);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    _templates
      ..clear()
      ..addAll(raw.map((e) =>
          TrainingPackTemplateModel.fromJson(jsonDecode(e) as Map<String, dynamic>)));
    if (_templates.isEmpty) {
      _templates.addAll(await TrainingPackTemplateRepository.getAll());
      await _persist();
    }
    final list = await goals?.loadGoals() ?? [];
    for (final g in list) {
      final tpl = g['templateId'] as String?;
      final goal = g['goal'] as String?;
      if (tpl == null || goal == null) continue;
      _goalProgress.putIfAbsent(tpl, () => {})[goal] = g;
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      [for (final t in _templates) jsonEncode(t.toJson())],
    );
  }

  Future<void> add(TrainingPackTemplateModel model) async {
    _templates.add(model);
    await _persist();
    await cloud?.saveTemplate(model);
    notifyListeners();
  }

  Future<void> update(TrainingPackTemplateModel model) async {
    final index = _templates.indexWhere((t) => t.id == model.id);
    if (index == -1) return;
    _templates[index] = model;
    await _persist();
    await cloud?.saveTemplate(model);
    notifyListeners();
  }

  Future<void> remove(TrainingPackTemplateModel model) async {
    _templates.removeWhere((t) => t.id == model.id);
    await _persist();
    await cloud?.deleteTemplate(model.id);
    notifyListeners();
  }

  void merge(List<TrainingPackTemplateModel> list) {
    for (final m in list) {
      final index = _templates.indexWhere((t) => t.id == m.id);
      if (index == -1) {
        _templates.add(m);
      } else {
        _templates[index] = m;
      }
    }
  }

  Future<void> saveAll() async {
    await _persist();
    notifyListeners();
  }

  Future<void> clear() async {
    _templates.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> saveGoalProgress(
    String templateId,
    String goal, {
    required bool completed,
    required int attempts,
    required double accuracy,
    required DateTime lastTrainedAt,
  }) async {
    final data = {
      'templateId': templateId,
      'goal': goal,
      'completed': completed,
      'attempts': attempts,
      'accuracy': accuracy,
      'lastTrainedAt': lastTrainedAt.toIso8601String(),
    };
    _goalProgress.putIfAbsent(templateId, () => {})[goal] = data;
    await goals?.saveGoal(data);
  }
}
