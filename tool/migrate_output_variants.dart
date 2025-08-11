import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import 'package:poker_analyzer/utils/yaml_utils.dart';

class MigrationResult {
  MigrationResult(this.content, this.before, this.after);
  final String content;
  final int before;
  final int after;
}

MigrationResult? migrateOutputVariantsContent(String input) {
  final doc = loadYamlNode(input);
  if (doc is! YamlMap) return null;
  final ov = doc.nodes['outputVariants'];
  if (ov == null || ov is! YamlList) return null;

  final usedKeys = <String>{};
  for (final node in ov.nodes) {
    if (node is YamlMap) {
      final k = node.nodes['key'];
      if (k != null) usedKeys.add(k.value.toString());
    }
  }
  var nextIndex = 0;
  String nextKey() {
    while (true) {
      final candidate = String.fromCharCode('A'.codeUnitAt(0) + nextIndex);
      nextIndex++;
      if (!usedKeys.contains(candidate)) {
        usedKeys.add(candidate);
        return candidate;
      }
    }
  }

  final variants = <String, Map<String, dynamic>>{};
  for (final node in ov.nodes) {
    if (node is! YamlMap) continue;
    final map = yamlToDart(node) as Map<String, dynamic>;
    String key;
    if (map.containsKey('key')) {
      key = map.remove('key').toString();
    } else {
      key = nextKey();
    }
    for (final t in ['requiredTags', 'excludedTags']) {
      final tags = map[t];
      if (tags is List) {
        final sorted = List.of(tags.map((e) => e.toString()))..sort();
        map[t] = sorted;
      }
    }
    variants[key] = map;
  }
  final sortedKeys = variants.keys.toList()..sort();
  final ordered = {for (final k in sortedKeys) k: variants[k]!};

  final editor = YamlEditor(input);
  editor.update(['outputVariants'], ordered);
  return MigrationResult(editor.toString(), ov.length, ordered.length);
}

void main(List<String> args) {
  final parser = ArgParser()
    ..addFlag('dry-run', defaultsTo: true, negatable: false)
    ..addFlag('write', defaultsTo: false, negatable: false);
  final res = parser.parse(args);
  final write = res['write'] as bool;

  final files = Directory('assets')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) {
    final l = f.path.toLowerCase();
    return l.endsWith('.yaml') || l.endsWith('.yml');
  }).toList();

  final changes = <Map<String, Object>>[];
  var failures = 0;

  for (final file in files) {
    try {
      final content = file.readAsStringSync();
      final result = migrateOutputVariantsContent(content);
      if (result != null) {
        if (write) {
          final eol = content.contains('\r\n') ? '\r\n' : '\n';
          final normalized = result.content.split('\n').join(eol);
          file.writeAsStringSync(normalized);
        }
        changes.add({
          'path': file.path,
          'before': result.before,
          'after': result.after,
        });
      }
    } catch (e) {
      failures++;
      stderr.writeln('Failed to process ${file.path}: $e');
    }
  }

  if (changes.isEmpty) {
    stdout.writeln('No legacy outputVariants found.');
  } else {
    stdout.writeln('Migrated outputVariants:');
    stdout.writeln('${'File'.padRight(60)}Before After');
    for (final c in changes) {
      final path = c['path'] as String;
      final before = c['before'];
      final after = c['after'];
      stdout.writeln('${path.padRight(60)}${before.toString().padLeft(6)} ${after.toString().padLeft(5)}');
    }
  }

  if (write && failures > 0) exitCode = 1;
}
