import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';
import 'package:json2yaml/json2yaml.dart';
import 'package:poker_analyzer/utils/yaml_utils.dart';

/// Scans YAML training packs under `assets/packs/v2/` and fixes common
/// validation errors. By default it runs in dry-run mode. Use `--apply`
/// to overwrite files with the fixed contents.
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('apply', negatable: false, help: 'Write changes to files');
  final results = parser.parse(args);
  final apply = results['apply'] as bool;

  final dir = Directory('assets/packs/v2');
  if (!dir.existsSync()) {
    stderr.writeln('Directory not found: ${dir.path}');
    exit(1);
  }

  final logBuffer = StringBuffer();
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.yaml'))
      .toList();

  for (final file in files) {
    final changes = _fixFile(file, apply: apply);
    if (changes.isNotEmpty) {
      logBuffer.writeln('${file.path}: ${changes.join(', ')}');
    }
  }

  if (logBuffer.isNotEmpty) {
    File('fix_log.txt').writeAsStringSync(logBuffer.toString());
  }

  stdout.writeln('Processed ${files.length} files');
  stdout.writeln('Found ${logBuffer.isEmpty ? 0 : logBuffer.toString().split('\n').where((l) => l.trim().isNotEmpty).length} files with fixes');
  if (apply) stdout.writeln('Changes applied');
}

List<String> _fixFile(File file, {required bool apply}) {
  final yamlContent = file.readAsStringSync();
  final data = loadYaml(yamlContent);
  final map = yamlToDart(data) as Map<String, dynamic>;

  final changes = <String>[];

  // spotCount check
  final spots = map['spots'] as List? ?? [];
  final spotCount = (map['spotCount'] as num?)?.toInt();
  if (spotCount != spots.length) {
    map['spotCount'] = spots.length;
    changes.add('spotCount');
  }

  // bb validation
  const validBbs = [10, 20, 25, 40, 50, 100];
  final bbVal = (map['bb'] as num?)?.toInt();
  if (bbVal == null || !validBbs.contains(bbVal)) {
    map.remove('bb');
    changes.add('bb');
  }

  // meta.schemaVersion
  Map<String, dynamic> meta;
  final existingMeta = map['meta'];
  if (existingMeta is Map) {
    meta = Map<String, dynamic>.from(existingMeta);
  } else {
    meta = <String, dynamic>{};
    map['meta'] = meta;
    changes.add('meta');
  }
  if (meta['schemaVersion'] != '2.0.0') {
    meta['schemaVersion'] = '2.0.0';
    changes.add('meta.schemaVersion');
  }

  if (apply && changes.isNotEmpty) {
    final yamlOut = json2yaml(map, yamlStyle: YamlStyle.pubspecYaml);
    file.writeAsStringSync('$yamlOut\n');
  }

  return changes;
}
