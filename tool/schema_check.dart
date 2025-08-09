import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

/// Validate a parsed YAML map according to the minimal schema required by CI.
/// Returns a list of error strings in the form `CODE message`.
List<String> validateMap(Map<dynamic, dynamic> map, {String? source}) {
  final errors = <String>[];

  if (map['baseSpot'] is! Map) {
    errors.add('E_BASE_SPOT_OBJECT_REQUIRED baseSpot must be a map');
  }

  final outputVariants = map['outputVariants'];
  if (outputVariants != null && outputVariants is! Map) {
    errors.add('E_OUTPUT_VARIANTS_MAP_REQUIRED outputVariants must be a map');
  }

  if (outputVariants is Map) {
    for (final entry in outputVariants.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || key.trim().isEmpty) {
        errors.add(
            'E_OUTPUT_VARIANT_KEY_EMPTY outputVariants keys must be non-empty strings');
        continue;
      }
      if (value is! Map) {
        errors.add(
            'E_OUTPUT_VARIANT_VALUE_MAP_REQUIRED outputVariants."$key" must be a map');
        continue;
      }
      const allowedFields = {
        'targetStreet',
        'boardConstraints',
        'requiredTags',
        'excludedTags',
        'seed',
      };
      for (final field in value.keys) {
        if (!allowedFields.contains(field)) {
          errors.add(
              'E_OUTPUT_VARIANT_FIELD_UNKNOWN unknown field "$field" in outputVariants."$key"');
        }
      }
      if (value.containsKey('seed') && value['seed'] is! int) {
        errors.add(
            'E_OUTPUT_VARIANT_SEED_INT seed must be int in outputVariants."$key"');
      }
      if (value.containsKey('targetStreet')) {
        const streets = {'preflop', 'flop', 'turn', 'river'};
        if (value['targetStreet'] is! String ||
            !streets.contains(value['targetStreet'])) {
          errors.add(
              'E_OUTPUT_VARIANT_TARGET_STREET targetStreet must be one of preflop|flop|turn|river in outputVariants."$key"');
        }
      }
      if (value.containsKey('requiredTags')) {
        final list = value['requiredTags'];
        if (list is! List || list.any((e) => e is! String)) {
          errors.add(
              'E_OUTPUT_VARIANT_REQUIRED_TAGS_STRING_LIST requiredTags must be a list of strings in outputVariants."$key"');
        }
      }
      if (value.containsKey('excludedTags')) {
        final list = value['excludedTags'];
        if (list is! List || list.any((e) => e is! String)) {
          errors.add(
              'E_OUTPUT_VARIANT_EXCLUDED_TAGS_STRING_LIST excludedTags must be a list of strings in outputVariants."$key"');
        }
      }
      if (value.containsKey('boardConstraints')) {
        final list = value['boardConstraints'];
        if (list is! List || list.any((e) => e is! Map)) {
          errors.add(
              'E_OUTPUT_VARIANT_BOARD_CONSTRAINTS_MAP_LIST boardConstraints must be a list of maps in outputVariants."$key"');
        }
      }
    }
  }

  return errors;
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
      final yaml = loadYaml(content);
      if (yaml is Map) {
        final errs = validateMap(yaml);
        if (errs.isEmpty) {
          checked++;
        } else {
          for (final e in errs) {
            errors.add('${file.path}: $e');
          }
        }
      } else {
        errors.add(
            '${file.path}: E_TOP_LEVEL_MAP_REQUIRED YAML root must be a map');
      }
    } catch (e) {
      errors.add('${file.path}: E_PARSE $e');
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
