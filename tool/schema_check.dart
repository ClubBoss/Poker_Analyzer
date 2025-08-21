import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

String? validateMap(Map<dynamic, dynamic> root, {String? source}) {
  if (root['baseSpot'] is! Map) {
    return 'E_BASE_SPOT_REQUIRED baseSpot object required';
  }

  final outputVariants = root['outputVariants'];
  if (outputVariants is! Map) {
    return 'E_OUTPUT_VARIANTS_MAP_REQUIRED outputVariants must be a map';
  }

  for (final entry in outputVariants.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is! String || key.trim().isEmpty) {
      return 'E_OUTPUT_VARIANT_NAME_INVALID outputVariants keys must be non-empty strings';
    }
    if (value is! Map) {
      return 'E_OUTPUT_VARIANT_NOT_MAP outputVariants[$key] must be a map';
    }

    for (final field in value.keys) {
      if (field is! String ||
          ![
            'targetStreet',
            'boardConstraints',
            'requiredTags',
            'excludedTags',
            'seed',
          ].contains(field)) {
        return 'E_OUTPUT_VARIANT_FIELD_INVALID outputVariants[$key]: unexpected field $field';
      }
    }

    if (value.containsKey('seed') && value['seed'] is! int) {
      return 'E_SEED_INT_REQUIRED outputVariants[$key].seed must be int';
    }

    if (value.containsKey('targetStreet')) {
      final ts = value['targetStreet'];
      const allowed = ['preflop', 'flop', 'turn', 'river'];
      if (ts is! String || !allowed.contains(ts)) {
        return 'E_TARGET_STREET_INVALID outputVariants[$key].targetStreet must be one of ${allowed.join('|')}';
      }
    }

    if (value.containsKey('requiredTags')) {
      final list = value['requiredTags'];
      if (list is! List || list.any((e) => e is! String)) {
        return 'E_REQUIRED_TAGS_STRING_LIST outputVariants[$key].requiredTags must be a list of strings';
      }
    }

    if (value.containsKey('excludedTags')) {
      final list = value['excludedTags'];
      if (list is! List || list.any((e) => e is! String)) {
        return 'E_EXCLUDED_TAGS_STRING_LIST outputVariants[$key].excludedTags must be a list of strings';
      }
    }

    if (value.containsKey('boardConstraints')) {
      final list = value['boardConstraints'];
      if (list is! List || list.any((e) => e is! Map)) {
        return 'E_BOARD_CONSTRAINTS_MAP_LIST outputVariants[$key].boardConstraints must be a list of maps';
      }
    }
  }

  return null;
}

void main(List<String> args) {
  final parser = ArgParser()..addFlag('soft', negatable: false);
  final res = parser.parse(args);
  final soft = res['soft'] as bool;

  final files = Directory('assets')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) {
    final l = f.path.toLowerCase();
    return l.endsWith('.yaml') || l.endsWith('.yml');
  });

  final errors = <String>[];
  var checked = 0;
  for (final file in files) {
    final content = file.readAsStringSync();
    if (!content.contains('baseSpot:')) continue;
    try {
      final doc = loadYaml(content);
      if (doc is Map) {
        final err = validateMap(doc, source: file.path);
        if (err != null) {
          errors.add('${file.path}: $err');
        } else {
          checked++;
        }
      } else {
        errors.add('${file.path}: E_ROOT_MAP_REQUIRED root YAML must be a map');
      }
    } catch (e) {
      errors.add('${file.path}: E_YAML_PARSE_ERROR $e');
    }
  }

  if (errors.isEmpty) {
    stdout.writeln('Schema OK for $checked templates.');
  } else {
    for (final err in errors) {
      stderr.writeln(err);
    }
    if (!soft) exitCode = 1;
  }
}
