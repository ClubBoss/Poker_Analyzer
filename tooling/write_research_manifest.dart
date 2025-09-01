import 'dart:convert';
import 'dart:io';

import 'ids_source.dart';

const _researchPath = 'prompts/research/_ALL.prompts.txt';
const _dispatcherPath = 'prompts/dispatcher/_ALL.txt';
const _manifestPath = 'prompts/research/_ALL.manifest.json';

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

Map<String, int> _counts(String path) {
  final file = File(path);
  final bytes = file.readAsBytesSync().length;
  final lines = const LineSplitter()
      .convert(_ascii(file.readAsStringSync()))
      .length;
  return {'bytes': bytes, 'lines': lines};
}

void main(List<String> args) {
  var dryRun = false;
  for (final a in args) {
    if (a == '--dry-run') {
      dryRun = true;
    } else {
      stderr.writeln('unknown arg');
      exit(2);
    }
  }

  try {
    _loadIds();
    final researchRaw = _ascii(File(_researchPath).readAsStringSync());
    final dispatcherRaw = _ascii(File(_dispatcherPath).readAsStringSync());
    final rBlocks = _splitResearch(researchRaw);
    final dBlocks = _splitDispatcher(dispatcherRaw);
    final rIds = rBlocks.map((e) => e.key).toList();
    final dIds = dBlocks.map((e) => e.key).toList();
    if (rIds.length != dIds.length) {
      throw const FormatException('id mismatch');
    }
    for (var i = 0; i < rIds.length; i++) {
      if (rIds[i] != dIds[i]) throw const FormatException('id mismatch');
    }
    final rc = _counts(_researchPath);
    final dc = _counts(_dispatcherPath);
    final manifest = {
      'id_source': idSource,
      'module_ids': rIds,
      'research_path': _researchPath,
      'dispatcher_path': _dispatcherPath,
      'bytes': {'research': rc['bytes'], 'dispatcher': dc['bytes']},
      'line_count': {'research': rc['lines'], 'dispatcher': dc['lines']},
      'generated_at': DateTime.now().toIso8601String().split('.').first,
    };
    final enc = const JsonEncoder.withIndent('  ');
    final json = enc.convert(manifest) + '\n';
    if (dryRun) {
      stdout.write(json);
    } else {
      final out = File(_manifestPath);
      out.createSync(recursive: true);
      out.writeAsStringSync(json);
    }
  } on FileSystemException {
    stderr.writeln('io error');
    exit(4);
  } on FormatException {
    stderr.writeln('parse error');
    exit(2);
  }
}
