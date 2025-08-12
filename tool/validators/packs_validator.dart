import 'dart:io';
import 'package:yaml/yaml.dart';

final _posSet = {'EP', 'MP', 'CO', 'BTN', 'SB', 'BB'};
final _kebab = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

/// Возвращает список ошибок валидации всех L2-паков.
List<String> validateL2Packs({String root = 'assets/packs/l2'}) {
  final dir = Directory(root);
  if (!dir.existsSync()) {
    return ['$root: missing directory'];
  }

  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.yaml'))
      .toList();

  final ids = <String, String>{};
  final errors = <String>[];

  // Первый проход: базовая валидация и сбор id.
  for (final f in files) {
    final rel = f.path;
    dynamic doc;
    try {
      doc = loadYaml(f.readAsStringSync());
    } catch (_) {
      errors.add('$rel: invalid yaml');
      continue;
    }
    if (doc is! YamlMap) {
      errors.add('$rel: root not map');
      continue;
    }

    void err(String msg) => errors.add('$rel: $msg');

    final id = doc['id'];
    if (id is! String || id.isEmpty) {
      err('missing id');
    } else if (ids.containsKey(id)) {
      err('duplicate id: $id (also in ${ids[id]})');
    } else {
      ids[id] = rel;
    }

    final subtype = doc['subtype'];
    if (subtype is! String) {
      err('missing subtype');
    }

    final tags = (doc['tags'] as YamlList?)?.cast() ?? [];
    if (tags.isEmpty) {
      err('tags required');
    } else {
      for (final t in tags) {
        if (t is! String || !_kebab.hasMatch(t)) {
          err('bad tag: $t');
          break;
        }
      }
      if (!tags.contains('l2')) {
        err("tags must contain 'l2'");
      }
    }

    final spots = (doc['spots'] as YamlList?)?.cast() ?? const [];
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
        // Expected format: "low-high" in big blinds.
        err('invalid stackBucket');
      }
    } else if (subtype == 'limped') {
      if (doc['limped'] != true) {
        err('limped=true required');
      }
      final pos = doc['position'];
      if (pos is! String || !{'SB', 'BB'}.contains(pos)) {
        err('limped position invalid');
      }
    } else if (subtype is String) {
      err('unknown subtype $subtype');
    }
  }

  // Второй проход: проверка ссылок unlockAfter.
  for (final f in files) {
    final rel = f.path;
    dynamic doc;
    try {
      doc = loadYaml(f.readAsStringSync());
    } catch (_) {
      continue;
    }
    if (doc is! YamlMap) continue;
    final stage = doc['stage'];
    if (stage is YamlMap && stage['unlockAfter'] != null) {
      final unlock = stage['unlockAfter'];
      if (unlock is! String || unlock.isEmpty) {
        errors.add('$rel: stage.unlockAfter must be non-empty string');
      } else if (!ids.containsKey(unlock)) {
        errors.add('$rel: stage.unlockAfter references unknown id $unlock');
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
  } else {
    stdout.writeln('L2 packs valid.');
  }
}
