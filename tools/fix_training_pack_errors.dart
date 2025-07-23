import 'dart:io';
import 'dart:convert';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';
import 'package:json2yaml/json2yaml.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('dry-run', negatable: false)
    ..addFlag('apply', negatable: false);
  final results = parser.parse(args);
  final dryRun = results['dry-run'] as bool;
  final apply = results['apply'] as bool;

  if (!dryRun && !apply) {
    stdout.writeln(
      'Usage: dart tools/fix_training_pack_errors.dart --dry-run|--apply',
    );
    exit(0);
  }

  final dir = Directory('assets/packs/v2/preflop');
  if (!dir.existsSync()) {
    stderr.writeln('Directory not found: ${dir.path}');
    exit(1);
  }

  final changedFiles = <String>[];

  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.yaml'));

  for (final file in files) {
    final changed = _processFile(file, apply: apply);
    if (changed) changedFiles.add(file.path);
  }

  if (apply && changedFiles.isNotEmpty) {
    final logFile = File('fix_log.txt');
    logFile.writeAsStringSync(changedFiles.join('\n') + '\n');
  }

  stdout.writeln('Processed ${files.length} files');
  if (changedFiles.isNotEmpty) {
    stdout.writeln('Modified ${changedFiles.length} files');
  }
}

bool _processFile(File file, {required bool apply}) {
  final content = file.readAsStringSync();
  final data = loadYaml(content);
  final map = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
  var changed = false;

  final spots = map['spots'] as List? ?? [];
  final spotCount = (map['spotCount'] as num?)?.toInt();
  if (spotCount != spots.length) {
    map['spotCount'] = spots.length;
    changed = true;
  }

  final bbVal = (map['bb'] as num?)?.toInt();
  const validBbs = {10, 20, 25, 40, 50, 100};
  if (bbVal == null || !validBbs.contains(bbVal)) {
    final gameType = map['gameType']?.toString().toLowerCase();
    final trainingType = map['trainingType']?.toString().toLowerCase();
    final isCash =
        (gameType != null && gameType.contains('cash')) ||
        (trainingType != null && trainingType.contains('cash'));
    map['bb'] = isCash ? 100 : 25;
    changed = true;
  }

  var meta = map['meta'] as Map?;
  if (meta == null) {
    meta = <String, dynamic>{};
    map['meta'] = meta;
    changed = true;
  }
  if (meta['schemaVersion'] != '2.0.0') {
    meta['schemaVersion'] = '2.0.0';
    changed = true;
  }

  if (map['recommended'] == null) {
    map['recommended'] = false;
    changed = true;
  }

  if (map['icon'] == null) {
    map['icon'] = 'north';
    changed = true;
  }

  if (apply && changed) {
    final yamlOut = json2yaml(map, yamlStyle: YamlStyle.pubspecYaml);
    file.writeAsStringSync(yamlOut + '\n');
  }

  return changed;
}
