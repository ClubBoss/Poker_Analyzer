import 'package:yaml/yaml.dart';

/// Generates starter YAML learning path templates.
class GraphPathTemplateGenerator {
  const GraphPathTemplateGenerator();

  /// Returns a simple Cash vs MTT graph template.
  String generateCashVsMttTemplate() {
    final map = {
      'nodes': [
        {
          'type': 'stage',
          'id': 'start',
          'next': ['format'],
        },
        {
          'type': 'branch',
          'id': 'format',
          'prompt': 'Choose format',
          'branches': {'Cash': 'cash_intro', 'MTT': 'mtt_intro'},
        },
        {
          'type': 'stage',
          'id': 'cash_intro',
          'next': ['end'],
        },
        {
          'type': 'stage',
          'id': 'mtt_intro',
          'next': ['end'],
        },
        {'type': 'stage', 'id': 'end'},
      ],
    };
    return const YamlEncoder().convert(map);
  }

  /// Returns a simple Live vs Online graph template.
  String generateLiveVsOnlineTemplate() {
    final map = {
      'nodes': [
        {
          'type': 'stage',
          'id': 'start',
          'next': ['environment'],
        },
        {
          'type': 'branch',
          'id': 'environment',
          'prompt': 'Choose environment',
          'branches': {'Live': 'live_intro', 'Online': 'online_intro'},
        },
        {
          'type': 'stage',
          'id': 'live_intro',
          'next': ['end'],
        },
        {
          'type': 'stage',
          'id': 'online_intro',
          'next': ['end'],
        },
        {'type': 'stage', 'id': 'end'},
      ],
    };
    return const YamlEncoder().convert(map);
  }

  /// Returns a simple ICM introduction graph template.
  String generateIcmIntroTemplate() {
    final map = {
      'nodes': [
        {
          'type': 'stage',
          'id': 'start',
          'next': ['knowledge'],
        },
        {
          'type': 'branch',
          'id': 'knowledge',
          'prompt': 'ICM experience',
          'branches': {'Beginner': 'icm_basics', 'Advanced': 'icm_advanced'},
        },
        {
          'type': 'stage',
          'id': 'icm_basics',
          'next': ['end'],
        },
        {
          'type': 'stage',
          'id': 'icm_advanced',
          'next': ['end'],
        },
        {'type': 'stage', 'id': 'end'},
      ],
    };
    return const YamlEncoder().convert(map);
  }

  /// Returns a simple Heads-Up introduction graph template.
  String generateHeadsUpIntroTemplate() {
    final map = {
      'nodes': [
        {
          'type': 'stage',
          'id': 'start',
          'next': ['experience'],
        },
        {
          'type': 'branch',
          'id': 'experience',
          'prompt': 'Heads-Up experience',
          'branches': {'New': 'hu_basics', 'Grinder': 'hu_strategy'},
        },
        {
          'type': 'stage',
          'id': 'hu_basics',
          'next': ['end'],
        },
        {
          'type': 'stage',
          'id': 'hu_strategy',
          'next': ['end'],
        },
        {'type': 'stage', 'id': 'end'},
      ],
    };
    return const YamlEncoder().convert(map);
  }
}
