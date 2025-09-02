import 'dart:convert';
import 'dart:io';

import 'ids_source.dart';

const _dispatcherPath = 'prompts/dispatcher/_ALL.txt';
const _statusPath = 'curriculum_status.json';

String _ascii(String s) {
  final b = StringBuffer();
  for (final c in s.codeUnits) {
    if (c == 0x0D) continue; // normalize CRLF -> LF
    b.writeCharCode(c <= 0x7F ? c : 0x3F);
  }
  return b.toString();
}

List<MapEntry<String, String>> _splitDispatcher(String raw) {
  final reg = RegExp(r'^module_id:\s*([a-z0-9_]+)\s*$', multiLine: true);
  final matches = reg.allMatches(raw).toList();
  if (matches.isEmpty || matches.first.start != 0) {
    throw const FormatException('parse dispatcher');
  }
  final out = <MapEntry<String, String>>[];
  for (var i = 0; i < matches.length; i++) {
    final id = matches[i].group(1)!;
    final start = matches[i].start;
    final end = i + 1 < matches.length ? matches[i + 1].start : raw.length;
    final block = raw.substring(start, end).trimRight();
    out.add(MapEntry(id, block));
  }
  return out;
}

List<String> _readModulesDone() {
  final f = File(_statusPath);
  if (!f.existsSync()) return const <String>[];
  final txt = _ascii(f.readAsStringSync());
  final obj = jsonDecode(txt);
  if (obj is! Map) return const <String>[];
  final list = obj['modules_done'];
  if (list is! List) return const <String>[];
  final out = <String>[];
  for (final v in list) {
    if (v is String && RegExp(r'^[a-z0-9_]+$').hasMatch(v)) out.add(v);
  }
  return out;
}

String _stubBlock(String id) {
  final buf = StringBuffer()
    ..writeln('module_id: $id')
    ..writeln('short_scope: TODO')
    ..writeln('spotkind_allowlist:')
    ..writeln('  none')
    ..writeln('target_tokens_allowlist:')
    ..writeln('  none');
  return buf.toString().trimRight();
}

void main(List<String> args) {
  // Load SSOT order strictly from curriculum_ids.dart
  final ssot = readCurriculumIds();
  if (idSource != 'curriculum_ids.dart') {
    stderr.writeln('expected SSOT from curriculum_ids.dart');
    exit(2);
  }
  // Load dispatcher (existing), may be empty/missing.
  final dFile = File(_dispatcherPath);
  if (!dFile.existsSync()) {
    stderr.writeln('missing dispatcher');
    exit(2);
  }
  final dispRaw = _ascii(dFile.readAsStringSync());
  final blocks = _splitDispatcher(dispRaw);
  final idToBlock = <String, String>{for (final e in blocks) e.key: e.value};

  // Read subset and sort by SSOT order.
  final modulesDone = _readModulesDone();
  final doneSorted = modulesDone.where((id) => ssot.contains(id)).toList()
    ..sort((a, b) => ssot.indexOf(a).compareTo(ssot.indexOf(b)));

  // Rebuild: first N = modules_done in SSOT order; then the rest in original order.
  final outBlocks = <String>[];
  for (final id in doneSorted) {
    outBlocks.add((idToBlock[id] ?? _stubBlock(id)).trimRight());
  }
  final doneSet = doneSorted.toSet();
  for (final e in blocks) {
    if (doneSet.contains(e.key)) continue; // already placed in prefix
    outBlocks.add(e.value.trimRight());
  }

  final newText = outBlocks.join('\n') + '\n';

  // Best-effort atomic write: write temp then rename.
  final tmp = File('$_dispatcherPath.tmp');
  tmp.writeAsStringSync(newText);
  try {
    if (dFile.existsSync()) {
      // On some platforms rename over existing path may fail; remove then rename.
      dFile.deleteSync();
    }
  } catch (_) {}
  tmp.renameSync(_dispatcherPath);
  stdout.writeln('dispatcher rebuilt: modules=${doneSorted.length}');
}
