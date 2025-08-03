import 'dart:io';
import 'dart:convert';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';
import 'package:json2yaml/json2yaml.dart';
import 'package:poker_analyzer/utils/yaml_utils.dart';

class _Issue {
  _Issue(this.file, this.message, {this.error = false});
  final String file;
  final String message;
  final bool error;

  Map<String, dynamic> toJson() => {
        'file': file,
        'error': error,
        'message': message,
      };

  @override
  String toString() => '[${error ? 'ERROR' : 'WARN'}] $file: $message';
}

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('fix', negatable: false)
    ..addFlag('json', negatable: false)
    ..addFlag('ci', negatable: false);
  final results = parser.parse(args);
  final fix = results['fix'] as bool;
  final jsonOut = results['json'] as bool;
  final ci = results['ci'] as bool;

  final allowedTags = _loadAllowedTags();
  final declaredAssets = _loadDeclaredAssets();
  final issues = <_Issue>[];
  final globalSpotIds = <String, String>{};
  final packIds = <String, String>{};

  final dir = Directory('assets/packs/v2');
  if (!dir.existsSync()) {
    stderr.writeln('Directory not found: ${dir.path}');
    exit(1);
  }

  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.yaml'));

  for (final file in files) {
    issues.addAll(_validateFile(
      file,
      allowedTags,
      globalSpotIds,
      packIds,
      fix: fix,
      declaredAssets: declaredAssets,
    ));
  }

  if (jsonOut) {
    stdout.writeln(jsonEncode({'issues': [for (final i in issues) i.toJson()]}));
  } else {
    for (final i in issues) {
      final line = i.toString();
      if (i.error) {
        stderr.writeln(line);
      } else {
        stdout.writeln(line);
      }
    }
    stdout.writeln('Checked ${files.length} files, found ${issues.length} issues');
  }

  if (ci && issues.any((e) => e.error)) exit(1);
}

Set<String> _loadAllowedTags() {
  final file = File('assets/packs/v2/library_index.json');
  if (!file.existsSync()) return <String>{};
  try {
    final data = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    final set = <String>{};
    for (final entry in data) {
      for (final t in entry['tags'] as List? ?? []) {
        set.add(t.toString().toLowerCase());
      }
    }
    return set;
  } catch (_) {
    return <String>{};
  }
}

Set<String> _loadDeclaredAssets() {
  final file = File('pubspec.yaml');
  if (!file.existsSync()) return <String>{};
  try {
    final yamlMap = loadYaml(file.readAsStringSync()) as YamlMap;
    final flutter = yamlMap['flutter'];
    if (flutter is YamlMap) {
      final assets = flutter['assets'];
      if (assets is YamlList) {
        return {for (final a in assets) a.toString()};
      }
    }
    return <String>{};
  } catch (_) {
    return <String>{};
  }
}

List<_Issue> _validateFile(
  File file,
  Set<String> allowedTags,
  Map<String, String> spotIds,
  Map<String, String> packIds, {
  bool fix = false,
  required Set<String> declaredAssets,
}) {
  final issues = <_Issue>[];
  Map<String, dynamic> map;
  try {
    final yamlMap = loadYaml(file.readAsStringSync());
    map = yamlToDart(yamlMap) as Map<String, dynamic>;
  } catch (e) {
    issues.add(_Issue(file.path, 'Invalid YAML: $e', error: true));
    return issues;
  }

  bool changed = false;
  // Required fields
  const requiredFields = ['id', 'name', 'tags', 'spots', 'bb', 'positions'];
  for (final f in requiredFields) {
    if (map[f] == null) {
      issues.add(_Issue(file.path, 'Missing required field `$f`', error: true));
    }
  }

  // unique pack id
  final pid = map['id']?.toString();
  if (pid != null && pid.isNotEmpty) {
    final prev = packIds[pid];
    if (prev != null && prev != file.path) {
      issues.add(_Issue(file.path,
          'Duplicate pack id `$pid` also in $prev',
          error: true));
    } else {
      packIds[pid] = file.path;
    }
  }

  // tags validation
  final tags = [for (final t in (map['tags'] as List? ?? [])) t.toString()];
  final newTags = <String>[];
  for (final t in tags) {
    final lower = t.toLowerCase();
    if (t != lower) {
      issues.add(_Issue(file.path, 'Tag `$t` should be lowercase'));
      if (fix) changed = true;
    }
    if (allowedTags.isNotEmpty && !allowedTags.contains(lower)) {
      issues.add(_Issue(file.path, 'Unknown tag `$t`'));
    }
    newTags.add(fix ? lower : t);
  }
  if (fix && newTags.isNotEmpty) map['tags'] = newTags;

  // bb warning
  const validBbs = [10, 20, 25, 40, 50, 100];
  final bbVal = (map['bb'] as num?)?.toInt();
  if (bbVal != null && !validBbs.contains(bbVal)) {
    issues.add(_Issue(file.path, 'Unrecognized bb value $bbVal', error: true));
  }

  final spots = map['spots'] as List? ?? [];
  final spotIdsLocal = <String>{};
  for (final s in spots) {
    if (s is! Map) continue;
    final id = s['id']?.toString();
    if (id == null || id.isEmpty) {
      issues.add(_Issue(file.path, 'Spot missing id', error: true));
    } else {
      if (!spotIdsLocal.add(id)) {
        issues.add(_Issue(file.path, 'Duplicate spot id `$id`', error: true));
      }
      final prev = spotIds[id];
      if (prev != null && prev != file.path) {
        issues.add(_Issue(file.path,
            'Spot id `$id` also used in $prev',
            error: true));
      } else {
        spotIds[id] = file.path;
      }
    }
    final type = s['type']?.toString();
    final isTheory = type == 'theory';
    if (isTheory) {
      final image = s['image']?.toString();
      if (image != null) {
        if (!File(image).existsSync()) {
          issues.add(_Issue(file.path,
              'Spot `$id` image not found: $image',
              error: true));
        }
        bool declared = false;
        for (final a in declaredAssets) {
          if (a.endsWith('/')) {
            if (image.startsWith(a)) {
              declared = true;
              break;
            }
          } else if (a == image) {
            declared = true;
            break;
          }
        }
        if (!declared) {
          issues.add(_Issue(file.path,
              'Image `$image` not declared in pubspec.yaml',
              error: true));
        }
      }
    }
    final hand = s['hand'] as Map?;
    if (!isTheory) {
      if (hand == null) {
        issues.add(_Issue(file.path, 'Spot `$id` missing hand', error: true));
        continue;
      }
      if (hand['heroCards'] == null) {
        issues.add(_Issue(file.path, 'Spot `$id` missing heroCards', error: true));
      }
      if (hand['position'] == null) {
        issues.add(_Issue(file.path, 'Spot `$id` missing position', error: true));
      }
      if (hand['stacks'] == null) {
        issues.add(_Issue(file.path, 'Spot `$id` missing stacks', error: true));
      }
      final heroOptions = s['heroOptions'] as List?;
      if (heroOptions == null || heroOptions.isEmpty) {
        issues.add(_Issue(file.path, 'Spot `$id` missing heroOptions', error: true));
      }
    }
  }

  final spotCount = map['spotCount'];
  if (spotCount == null || spotCount != spots.length) {
    issues.add(_Issue(file.path,
        'spotCount $spotCount does not match spots length ${spots.length}',
        error: true));
    if (fix) {
      map['spotCount'] = spots.length;
      changed = true;
    }
  }

  final meta = map['meta'];
  final schemaVersion =
      meta is Map ? meta['schemaVersion']?.toString() : null;
  if (schemaVersion != '2.0.0') {
    issues.add(_Issue(file.path,
        'meta.schemaVersion expected 2.0.0 but found $schemaVersion',
        error: true));
  }

  final gameType = map['gameType']?.toString();
  if (gameType != null && gameType != 'cash' && gameType != 'tournament') {
    issues.add(_Issue(file.path, 'Unknown gameType `$gameType`'));
  }

  if (fix && changed) {
    final yamlOut = json2yaml(map);
    file.writeAsStringSync('$yamlOut\n');
  }

  return issues;
}
