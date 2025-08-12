import 'dart:io';

import 'package:yaml/yaml.dart';

void main(List<String> args) {
  final dirs = [
    'assets/packs/l2/open_fold',
    'assets/packs/l2/3bet_push',
  ];
  var ok = true;
  for (final dir in dirs) {
    for (final entry in Directory(dir).listSync().whereType<File>()) {
      final doc = loadYaml(entry.readAsStringSync());
      if (doc is! YamlMap) {
        stderr.writeln('Invalid YAML in ${entry.path}');
        ok = false;
        continue;
      }
      final spots = doc['spots'];
      if (spots is! YamlList || spots.length < 80) {
        stderr.writeln('Pack ${entry.path} needs at least 80 spots');
        ok = false;
      }
      final tags = doc['tags'];
      if (tags is! YamlList || tags.isEmpty) {
        stderr.writeln('Pack ${entry.path} missing tags');
        ok = false;
      }
    }
  }
  if (!ok) exit(1);
  stdout.writeln('All packs look good');
}
