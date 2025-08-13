import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';

import '../core/training/generation/yaml_writer.dart';
import '../models/learning_path_stage_model.dart';
import '../models/stage_type.dart';
import 'learning_path_stage_library.dart';
import 'smart_theory_suggestion_engine.dart';

/// Automatically creates theory stage templates based on missing tags.
class AutoTheoryStageSeeder {
  final SmartTheorySuggestionEngine engine;
  final YamlWriter writer;
  final String? outputDir;
  final DateTime Function() now;

  const AutoTheoryStageSeeder({
    required this.engine,
    this.writer = const YamlWriter(),
    this.outputDir,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<List<LearningPathStageModel>> _buildStages(
      {bool inject = false}) async {
    final suggestions = await engine.suggestMissingTheoryStages();
    final stages = <LearningPathStageModel>[];
    final library = LearningPathStageLibrary.instance;
    var order = 0;
    for (final s in suggestions) {
      final stage = LearningPathStageModel(
        id: s.proposedPackId,
        title: 'Теория: ${s.tag}',
        description: '',
        packId: s.proposedPackId,
        type: StageType.theory,
        requiredAccuracy: 0,
        minHands: 0,
        tags: [s.tag],
        order: order++,
      );
      if (inject) library.add(stage);
      stages.add(stage);
    }
    return stages;
  }

  /// Generates YAML snippet with stages for all missing theory tags.
  Future<String> generateYamlForMissingTheoryStages() async {
    final stages = await _buildStages();
    final data = {
      'stages': [for (final s in stages) s.toJson()]
    };
    return const YamlEncoder().convert(data);
  }

  /// Builds stages and writes them to a YAML file. Returns the file path or
  /// `null` if there were no suggestions.
  Future<String?> exportYamlFile({bool inject = false}) async {
    final stages = await _buildStages(inject: inject);
    if (stages.isEmpty) return null;
    final dirPath =
        outputDir ?? (await getApplicationDocumentsDirectory()).path;
    final ts = DateFormat('yyyyMMdd_HHmmss').format(now());
    final path = p.join(dirPath, 'auto_theory_seed_$ts.yaml');
    await writer.write({
      'stages': [for (final s in stages) s.toJson()]
    }, path);
    return path;
  }
}
