import 'dart:io';
import 'package:yaml/yaml.dart';

final _posSet = {'EP', 'MP', 'CO', 'BTN', 'SB', 'BB'};
final _kebab = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

/// Returns a list of validation error strings for all L2 packs.
List<String> validateL2Packs({String root = 'assets/packs/l2'}) {
  final dir = Directory(root);
  if (!dir.existsSync()) {
    return ['::error file=$root::missing directory'];
  }

  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.yaml'))
      .toList();

  final ids = <String, String>{}; // id -> file
  final errors = <String>[];

  for (final f in files) {
    final rel = f.path;
    dynamic doc;
    try {
      doc = loadYaml(f.readAsStringSync());
    } catch (_) {
      errors.add('$rel: invalid yaml');
      continue;
    }
    if (doc is not YamlMap) {
      errors.add('$rel: root not map');
      continue;
    }

    void err(String m) => errors.add('$rel: $m');

    final id = doc['id'];
    if (id is! String || id.isEmpty) {
      err('missing id');
      continue;
    }
    if (ids.containsKey(id)) {
      err('duplicate id "$id" (also in ${ids[id]})');
    } else {
      ids[id] = rel;
    }

    final name = doc['name'];
    if (name is! String || name.isEmpty) err('missing name');

    final stage = doc['stage'];
    if (stage is! YamlMap || (stage['id'] as String?)?.toUpperCase() != 'L2') {
      err('stage.id must be L2');
    }

    final subtype = doc['subtype'];
    if (subtype is! String ||
        !{'open-fold', '3bet-push', 'limped'}.contains(subtype)) {
      err('invalid subtype "$subtype"');
    }

    final tags = (doc['tags'] as YamlList?)?.toList() ?? const [];
    if (tags.isEmpty) err('missing tags');
    for (final t in tags) {
      if (t is! String || !_kebab.hasMatch(t)) {
        err('tag not lower-kebab-case: $t');
        break;
      }
    }
    if (!tags.contains('l2')) err('tags must include "l2"');
    if (subtype is String && !tags.contains(subtype)) {
      err('tags must include subtype "$subtype"');
    }

    final spots = (doc['spots'] as YamlList?)?.toList() ?? const [];
    if (spots.length < 80) {
      err('must have at least 80 spots');
    } else {
      for (final s in spots) {
        if (s is! YamlMap) continue;
        final at = s['actionType'];
        if (subtype == 'open-fold' && at != 'open-fold') {
          err('spot actionType mismatch');
          break;
        }
        if (subtype == '3bet-push' && at != '3bet-push') {
          err('spot actionType mismatch');
          break;
        }
        if (subtype == 'limped' && at != 'limped') {
          err('spot actionType mismatch');
          break;
        }
      }
    }

    if (subtype == 'open-fold') {
      final pos = doc['position'];
      if (pos is! String || !_posSet.contains(pos)) {
        err('invalid position $pos');
      }
    } else if (subtype == '3bet-push') {
      final bucket = doc['stackBucket'];
      if (bucket is! String || !RegExp(r'^\d+-\d+$').hasMatch(bucket)) {
        err('invalid stackBucket "$bucket"');
      }
    } else if (subtype == 'limped') {
      if (doc['limped'] != true) {
        err('limped=true required');
      }
      final pos = doc['position'];
      if (pos is! String || !{'SB', 'BB'}.contains(pos)) {
        err('limped position invalid');
      }
    }

    final unlockAfter = (doc['stage'] as YamlMap?)?['unlockAfter'];
    if (unlockAfter != null && unlockAfter is! String) {
      err('stage.unlockAfter must be string id');
    }
  }

  // Second pass: validate unlockAfter refs resolve within L2.
  for (final f in files) {
    final rel = f.path;
    final doc = loadYaml(f.readAsStringSync()) as YamlMap;
    final unlock = (doc['stage'] as YamlMap?)?['unlockAfter'] as String?;
    if (unlock != null) {
      if (!ids.containsKey(unlock)) {
        errors.add(
            '$rel: stage.unlockAfter references unknown id "$unlock"');
      }
    }
  }

  return errors;
}

void main() {
  final errors = validateL2Packs();
  if (errors.isNotEmpty) {
    for (final e in errors) {
      final idx = e.indexOf(': ');
      if (idx != -1) {
        final file = e.substring(0, idx);
        final msg = e.substring(idx + 2);
        stderr.writeln('::error file=$file::$msg');
      } else {
        stderr.writeln('::error::$e');
      }
    }
    exit(1);
  }
}
