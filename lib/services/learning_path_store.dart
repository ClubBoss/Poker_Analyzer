import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/injected_path_module.dart';
import 'user_skill_model_service.dart';

/// Persists injected learning path modules per user.
class LearningPathStore {
  final String rootDir;

  const LearningPathStore({this.rootDir = 'autogen_cache/learning_paths'});

  File _fileFor(String userId) => File('$rootDir/$userId.json');

  Future<List<String>> listUsers() async {
    final dir = Directory(rootDir);
    if (!dir.existsSync()) return [];
    final users = <String>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        final id = p.basenameWithoutExtension(entity.path);
        if (id.isNotEmpty) users.add(id);
      }
    }
    return users;
  }

  Future<List<InjectedPathModule>> listModules(String userId) async {
    final file = _fileFor(userId);
    if (!file.existsSync()) return [];
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return [];
    final data = jsonDecode(raw) as List;
    return data
        .map((e) => InjectedPathModule.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _save(String userId, List<InjectedPathModule> modules) async {
    final file = _fileFor(userId);
    file.parent.createSync(recursive: true);
    final tmp = File('${file.path}.tmp');
    final data = modules.map((m) => m.toJson()).toList();
    await tmp.writeAsString(jsonEncode(data));
    if (file.existsSync()) {
      await tmp.rename(file.path);
    } else {
      await tmp.rename(file.path);
    }
  }

  Future<void> upsertModule(String userId, InjectedPathModule module) async {
    final modules = await listModules(userId);
    final idx = modules.indexWhere((m) => m.moduleId == module.moduleId);
    if (idx >= 0) {
      modules[idx] = module;
    } else {
      modules.add(module);
    }
    await _save(userId, modules);
  }

  Future<void> updateModuleStatus(
    String userId,
    String moduleId,
    String status, {
    double? passRate,
  }) async {
    final modules = await listModules(userId);
    final idx = modules.indexWhere((m) => m.moduleId == moduleId);
    if (idx == -1) return;
    final module = modules[idx];
    final metrics = Map<String, dynamic>.from(module.metrics);
    final now = DateTime.now().toIso8601String();
    if (status == 'in_progress') {
      metrics['startedAt'] = now;
    } else if (status == 'completed') {
      metrics['completedAt'] = now;
      if (passRate != null) metrics['passRate'] = passRate;
    }
    modules[idx] = module.copyWith(status: status, metrics: metrics);
    await _save(userId, modules);
    if (status == 'completed') {
      final tags = (metrics['clusterTags'] as List?)?.cast<String>() ?? const [];
      if (tags.isNotEmpty) {
        await UserSkillModelService.instance.recordAttempt(
          userId,
          tags,
          correct: (passRate ?? 0.0) > 0.6,
        );
      }
    }
  }

  Future<void> removeModule(String userId, String moduleId) async {
    final modules = await listModules(userId);
    modules.removeWhere((m) => m.moduleId == moduleId);
    await _save(userId, modules);
  }
}
