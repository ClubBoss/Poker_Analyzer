import 'dart:convert';
import 'dart:io';

import 'ids_source.dart';

const _researchPath = 'prompts/research/_ALL.prompts.txt';
const _dispatcherPath = 'prompts/dispatcher/_ALL.txt';

String _ascii(String s) {
  final buf = StringBuffer();
  for (final c in s.codeUnits) {
    if (c == 0x0D) continue;
    buf.writeCharCode(c <= 0x7F ? c : 0x3F);
  }
  return buf.toString();
}

List<MapEntry<String, String>> _splitResearch(String raw) {
  final reg = RegExp(r'^GO MODULE:\s+([a-z0-9_]+)\s*$', multiLine: true);
  final matches = reg.allMatches(raw).toList();
  if (matches.isEmpty || matches.first.start != 0) {
    throw const FormatException('parse error');
  }
  final out = <MapEntry<String, String>>[];
  for (var i = 0; i < matches.length; i++) {
    final id = matches[i].group(1)!;
    final start = matches[i].start;
    final end = i + 1 < matches.length ? matches[i + 1].start : raw.length;
    out.add(MapEntry(id, raw.substring(start, end)));
  }
  return out;
}

List<MapEntry<String, String>> _splitDispatcher(String raw) {
  final reg = RegExp(r'^module_id:\s*([a-z0-9_]+)\s*$', multiLine: true);
  final matches = reg.allMatches(raw).toList();
  if (matches.isEmpty || matches.first.start != 0) {
    throw const FormatException('parse error');
  }
  final out = <MapEntry<String, String>>[];
  for (var i = 0; i < matches.length; i++) {
    final id = matches[i].group(1)!;
    final start = matches[i].start;
    final end = i + 1 < matches.length ? matches[i + 1].start : raw.length;
    out.add(MapEntry(id, raw.substring(start, end)));
  }
  return out;
}

List<String> _loadIds() {
  final ids = readCurriculumIds();
  stdout.writeln('ID SOURCE: $idSource');
  return ids;
}

List<String> _validate(
  List<MapEntry<String, String>> research,
  List<MapEntry<String, String>> dispatch,
  List<String> ssot,
  {String? onlyId},
) {
  final errors = <String>[];

  final r =
      onlyId == null ? research : research.where((e) => e.key == onlyId).toList();
  final d =
      onlyId == null ? dispatch : dispatch.where((e) => e.key == onlyId).toList();

  final rIds = r.map((e) => e.key).toList();
  final dIds = d.map((e) => e.key).toList();

  if (onlyId != null) {
    if (rIds.isEmpty) errors.add('missing research: $onlyId');
    if (dIds.isEmpty) errors.add('missing dispatcher: $onlyId');
    if (rIds.length > 1) errors.add('duplicate id: $onlyId');
  } else {
    final seen = <String>{};
    for (final id in rIds) {
      if (!seen.add(id)) errors.add('duplicate id: $id');
    }
  }

  var pos = -1;
  for (final id in rIds) {
    final idx = ssot.indexOf(id);
    if (idx == -1) {
      errors.add('unknown id: $id');
    } else {
      if (idx <= pos) errors.add('order mismatch: $id');
      pos = idx;
    }
  }

  final placeholder = RegExp(r'\{\{[^}]+\}\}');
  for (final e in r) {
    if (placeholder.hasMatch(e.value)) {
      errors.add('unresolved placeholder: ${e.key}');
    }
  }

  if (rIds.length != dIds.length) {
    errors.add('dispatcher ids mismatch');
  } else {
    for (var i = 0; i < rIds.length; i++) {
      if (rIds[i] != dIds[i]) {
        errors.add('dispatcher ids mismatch');
        break;
      }
    }
  }

  for (final e in d) {
    final lines = const LineSplitter().convert(e.value);
    if (lines.length < 5) {
      errors.add('dispatcher format: ${e.key}');
      continue;
    }
    if (lines.length < 2 || !lines[1].startsWith('short_scope:')) {
      errors.add('missing short_scope: ${e.key}');
    } else if (lines[1].substring('short_scope:'.length).trim().isEmpty) {
      errors.add('missing short_scope: ${e.key}');
    }
    final spotIdx = lines.indexOf('spotkind_allowlist:');
    final tokenIdx = lines.indexOf('target_tokens_allowlist:');
    if (spotIdx == -1) {
      errors.add('missing spotkind_allowlist: ${e.key}');
    }
    if (tokenIdx == -1) {
      errors.add('missing target_tokens_allowlist: ${e.key}');
    }
    if (spotIdx != -1 && tokenIdx != -1) {
      final spot = lines.sublist(spotIdx + 1, tokenIdx);
      final token = lines.sublist(tokenIdx + 1);
      if (spot.isEmpty) {
        errors.add('empty spotkind_allowlist: ${e.key}');
      } else if (!(spot.length == 1 && spot[0].trim() == 'none')) {
        if (spot.any((l) => l.trim().isEmpty)) {
          errors.add('empty spotkind_allowlist: ${e.key}');
        }
      }
      if (token.isEmpty) {
        errors.add('empty target_tokens_allowlist: ${e.key}');
      } else if (!(token.length == 1 && token[0].trim() == 'none')) {
        if (token.any((l) => l.trim().isEmpty)) {
          errors.add('empty target_tokens_allowlist: ${e.key}');
        }
      }
    }
  }

  return errors;
}

void main(List<String> args) {
  bool json = false;
  String? only;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--json') {
      json = true;
    } else if (a == '--only') {
      if (i + 1 >= args.length) {
        stderr.writeln('missing id');
        exit(2);
      }
      only = args[++i];
    } else {
      stderr.writeln('unknown arg');
      exit(2);
    }
  }

  try {
    final ids = _loadIds();
    final researchRaw = _ascii(File(_researchPath).readAsStringSync());
    final dispatchRaw = _ascii(File(_dispatcherPath).readAsStringSync());
    final researchBlocks = _splitResearch(researchRaw);
    final dispatchBlocks = _splitDispatcher(dispatchRaw);
    final errors =
        _validate(researchBlocks, dispatchBlocks, ids, onlyId: only);
    final ok = errors.isEmpty;
    final checkedIds =
        only != null ? <String>[only] : researchBlocks.map((e) => e.key).toList();
    if (json) {
      final res = {
        'ok': ok,
        'ids': checkedIds,
        'errors': errors,
        'idSource': idSource,
      };
      print(jsonEncode(res));
    } else if (ok) {
      if (checkedIds.isEmpty) {
        print('OK modules=0');
      } else {
        print('OK modules=${checkedIds.length} first=${checkedIds.first} last=${checkedIds.last}');
      }
    } else {
      for (final e in errors) {
        stderr.writeln(e);
      }
      exit(2);
    }
  } on FileSystemException {
    stderr.writeln('io error');
    exit(4);
  } on FormatException {
    stderr.writeln('parse error');
    exit(2);
  }
}
