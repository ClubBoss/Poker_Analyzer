import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

import '../models/learning_path_node.dart';
import 'game_mode_profile_engine.dart';
import 'graph_path_template_parser.dart';

/// Loads a learning path graph for the active [GameModeProfile].
class LearningPathGraphOrchestrator {
  final GraphPathTemplateParser parser;
  final GameModeProfileEngine profiles;

  LearningPathGraphOrchestrator({
    GraphPathTemplateParser? parser,
    GameModeProfileEngine? profiles,
  }) : parser = parser ?? GraphPathTemplateParser(),
       profiles = profiles ?? GameModeProfileEngine.instance;

  /// Loads the graph defined for the currently active profile.
  Future<List<LearningPathNode>> loadGraph() async {
    final profile = profiles.getActiveProfile();
    final fileName = _fileNameForProfile(profile);
    final path = 'assets/paths/$fileName';
    String? raw;
    try {
      raw = await rootBundle.loadString(path);
    } catch (_) {
      final file = File(path);
      if (file.existsSync()) {
        raw = await file.readAsString();
      }
    }
    if (raw == null) return [];
    return parser.parseFromYaml(raw);
  }

  String _fileNameForProfile(GameModeProfile profile) {
    switch (profile) {
      case GameModeProfile.cashOnline:
        return 'cash_online.yaml';
      case GameModeProfile.cashLive:
        return 'cash_live.yaml';
      case GameModeProfile.mttOnline:
        return 'mtt_online.yaml';
      case GameModeProfile.mttLive:
        return 'mtt_live.yaml';
    }
  }
}
