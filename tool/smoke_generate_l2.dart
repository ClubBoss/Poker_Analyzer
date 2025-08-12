import 'dart:io';

import 'package:yaml/yaml.dart';

void main() {
  final subtypes = {
    'open-fold': 'assets/packs/l2/open-fold',
    '3bet-push': 'assets/packs/l2/3bet-push',
    'limped': 'assets/packs/l2/limped',
  };
  for (final entry in subtypes.entries) {
    for (var run = 0; run < 3; run++) {
      for (final file in Directory(entry.value).listSync().whereType<File>()) {
        final doc = loadYaml(file.readAsStringSync());
        final spots = doc['spots'] as YamlList?;
        if (spots == null || spots.isEmpty) {
          throw 'Empty spots in ${file.path}';
        }
      }
    }
  }
  stdout.writeln('Smoke tests passed');
}
