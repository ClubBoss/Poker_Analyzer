import 'dart:io';

import 'package:args/args.dart';
import 'package:poker_analyzer/models/training_pack_template_set.dart';

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
      TrainingPackTemplateSet.fromYaml(content, source: file.path);
      checked++;
    } catch (e) {
      errors.add('${file.path}: $e');
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
