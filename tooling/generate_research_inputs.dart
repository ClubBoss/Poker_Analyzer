/// tooling/generate_research_inputs.dart
/// Scaffold allowlists and short_scope entries for research modules.
///
/// Usage:
///   dart run tooling/generate_research_inputs.dart [--write]
///
/// Default run is a dry-run. Use --write to create missing files.

import 'dart:convert';
import 'dart:io';

const String _queuePath = 'RESEARCH_QUEUE.md';
const String _shortScopePath = 'tooling/short_scope.json';
const String _allowlistDir = 'tooling/allowlists';

String _normalize(String s) {
  const Map<String, String> repl = {'“': '"', '”': '"', '‘': "'", '’': "'"};
  var out = s;
  repl.forEach((k, v) => out = out.replaceAll(k, v));
  return out;
}

List<String> parseQueue() {
  final f = File(_queuePath);
  final txt = _normalize(f.readAsStringSync());
  final ids = <String>[];
  for (final line in const LineSplitter().convert(txt)) {
    final t = line.trim();
    if (t.startsWith('-')) {
      final id = t.substring(1).trim();
      if (RegExp(r'^[a-z0-9_]+$').hasMatch(id)) {
        ids.add(id);
      }
    }
  }
  if (ids.isEmpty) throw const FormatException('No modules found');
  return ids;
}

Map<String, String> readShortScope() {
  final f = File(_shortScopePath);
  if (!f.existsSync()) return <String, String>{};
  try {
    final txt = _normalize(f.readAsStringSync());
    final data = jsonDecode(txt) as Map<String, dynamic>;
    final out = <String, String>{};
    for (final e in data.entries) {
      out[e.key] = e.value is String ? e.value as String : '';
    }
    return out;
  } on FormatException {
    throw const FileSystemException('Invalid short_scope.json');
  }
}

Map<String, String> mergeShortScope(
  Map<String, String> existing,
  List<String> ids,
) {
  final merged = <String, String>{};
  merged.addAll(existing);
  for (final id in ids) {
    merged.putIfAbsent(id, () => '');
  }
  return merged;
}

List<int> ensureAllowlists(List<String> ids, bool write) {
  final dir = Directory(_allowlistDir);
  if (!dir.existsSync() && write) {
    dir.createSync(recursive: true);
  }
  var spot = 0;
  var token = 0;
  for (final id in ids) {
    final spotPath = '$_allowlistDir/spotkind_allowlist_${id}.txt';
    final tokenPath = '$_allowlistDir/target_tokens_allowlist_${id}.txt';
    final sf = File(spotPath);
    if (!sf.existsSync()) {
      spot++;
      if (write) sf.writeAsStringSync('none\n');
    }
    final tf = File(tokenPath);
    if (!tf.existsSync()) {
      token++;
      if (write) tf.writeAsStringSync('none\n');
    }
  }
  return <int>[spot, token];
}

void printSummary(int total, int spot, int token, int shortAdded, bool write) {
  stdout.writeln('TOTAL modules: $total');
  stdout.writeln('created spot/allows: $spot');
  stdout.writeln('created token/allows: $token');
  stdout.writeln('added short_scope keys: $shortAdded');
  stdout.writeln('Mode: ' + (write ? 'WROTE' : 'DRY-RUN'));
}

void main(List<String> args) {
  final write = args.contains('--write');
  try {
    final ids = parseQueue();
    final existing = readShortScope();
    final merged = mergeShortScope(existing, ids);
    final shortAdded = merged.length - existing.length;
    final counts = ensureAllowlists(ids, write);
    if (write) {
      final enc = const JsonEncoder.withIndent('  ');
      File(_shortScopePath).writeAsStringSync(enc.convert(merged) + '\n');
    }
    printSummary(ids.length, counts[0], counts[1], shortAdded, write);
  } on FormatException {
    exit(2);
  } on FileSystemException {
    exit(4);
  }
}
