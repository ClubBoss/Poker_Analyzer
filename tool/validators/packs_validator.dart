import 'dart:io';
import 'package:yaml/yaml.dart';

final _posSet = {'EP','MP','CO','BTN','SB','BB'};
final _kebab = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*\$');

void main() {
  final dir = Directory('assets/packs/l2');
  if (!dir.existsSync()) {
    stderr.writeln('::error file=assets/packs/l2::missing directory');
    exit(1);
  }
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.yaml'))
      .toList();
  final ids = <String, String>{};
  final errors = <String>[];
  for (final f in files) {
    final rel = f.path;
    dynamic doc;
    try {
      doc = loadYaml(f.readAsStringSync());
    } catch (e) {
      errors.add('$rel: invalid yaml');
      continue;
    }
    if (doc is! YamlMap) {
      errors.add('$rel: root not map');
      continue;
    }
    final id = doc['id'];
    if (id is! String || id.isEmpty) {
      errors.add('$rel: missing id');
      continue;
    }
    ids[id] = rel;
  }
  for (final f in files) {
    final rel = f.path;
    final doc = loadYaml(f.readAsStringSync()) as YamlMap;
    void err(String msg) => errors.add('$rel: $msg');
    final stage = doc['stage'];
    if (stage is! YamlMap || stage['id'] != 'L2') {
      err('stage.id must be L2');
    }
    final unlock = stage is YamlMap ? stage['unlockAfter'] : null;
    if (unlock != null && !ids.containsKey(unlock)) {
      err('stage.unlockAfter references unknown id $unlock');
    }
    final subtype = doc['subtype'];
    final tags = doc['tags'];
    if (tags is! YamlList || tags.isEmpty) {
      err('tags missing');
    } else {
      for (final t in tags) {
        if (t is! String || !_kebab.hasMatch(t)) {
          err('invalid tag $t');
        }
      }
      if (!(tags.contains('l2') && tags.contains(subtype))) {
        err('tags must include l2 and subtype');
      }
    }
    final spots = doc['spots'];
    if (spots is! YamlList || spots.length < 80) {
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
      if (bucket is! String || !RegExp(r'^\\d+-\\d+\$').hasMatch(bucket)) {
        err('invalid stackBucket');
      }
    } else if (subtype == 'limped') {
      if (doc['limped'] != true) {
        err('limped=true required');
      }
      final pos = doc['position'];
      if (pos is! String || !{'SB','BB'}.contains(pos)) {
        err('limped position invalid');
      }
    } else {
      err('unknown subtype $subtype');
    }
  }
  if (errors.isNotEmpty) {
    for (final e in errors) {
      final idx = e.indexOf(': ');
      if (idx != -1) {
        final file = e.substring(0, idx);
        final msg = e.substring(idx + 2);
        stderr.writeln('::error file=' + file + '::' + msg);
      } else {
        stderr.writeln('::error::' + e);
      }
    }
    exit(1);
  }
}
