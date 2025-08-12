import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

void main(List<String> args) {
  final parser = ArgParser()..addOption('dir', mandatory: true);
  final argResults = parser.parse(args);
  final dir = Directory(argResults['dir'] as String);
  if (!dir.existsSync()) {
    stderr.writeln('Directory not found: ${dir.path}');
    exit(1);
  }
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.yaml'));
  var hadError = false;
  final posSet = {'EP', 'MP', 'CO', 'BTN', 'SB', 'BB'};
  final bucketReg = RegExp(r'^\d+-\d+$');
  for (final file in files) {
    final content = file.readAsStringSync();
    final data = loadYaml(content) as YamlMap;
    final subtype = data['subtype'];
    final spots = data['spots'] as YamlList?;
    if (spots == null || spots.isEmpty) {
      stderr.writeln('Empty spots in ${file.path}');
      hadError = true;
      continue;
    }
    for (final spot in spots) {
      if (spot['actionType'] != subtype) {
        stderr.writeln('actionType mismatch in ${file.path}');
        hadError = true;
        break;
      }
    }
    if (subtype == 'limped') {
      if (data['limped'] != true) {
        stderr.writeln('Missing limped:true in ${file.path}');
        hadError = true;
      }
    } else if (subtype == 'open-fold') {
      final pos = data['position'];
      if (!posSet.contains(pos)) {
        stderr.writeln('Invalid position $pos in ${file.path}');
        hadError = true;
      }
    } else if (subtype == '3bet-push') {
      final bucket = data['stackBucket'];
      if (bucket is! String || !bucketReg.hasMatch(bucket)) {
        stderr.writeln('Invalid stackBucket $bucket in ${file.path}');
        hadError = true;
      }
    }
  }
  if (hadError) exit(1);
}
