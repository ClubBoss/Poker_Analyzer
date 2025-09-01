/// tooling/generate_research_prompts.dart
/// Generate research prompts and dispatcher inputs.
///
/// Usage:
///   dart run tooling/generate_research_prompts.dart [--write] [--split] [--overwrite] [--only <id>]
///
/// Default run is a dry-run with no writes. Use --write to produce aggregate files,
/// --split for per-module files, and --overwrite to allow overwriting in split mode.

import 'dart:convert';
import 'dart:io';

import 'ids_source.dart';

const String _templatePath = 'RESEARCH_BATCH_TEMPLATE.md';
const String _shortScopePath = 'tooling/short_scope.json';
const String _allowlistDir = 'tooling/allowlists';
const String _researchDir = 'prompts/research';
const String _dispatcherDir = 'prompts/dispatcher';

String _normalize(String s) {
  const repl = {
    '“': '"',
    '”': '"',
    '‘': "'",
    '’': "'",
    '–': '-',
    '—': '-',
    '•': '-',
  };
  var out = s;
  repl.forEach((k, v) => out = out.replaceAll(k, v));
  return out;
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

String? readAllow(String path) {
  final f = File(path);
  if (!f.existsSync()) return null;
  return _normalize(f.readAsStringSync()).trim();
}

bool isReady(String id, Map<String, String> shortScope) {
  final scope = shortScope[id];
  if (scope == null || scope.trim().isEmpty) return false;
  final spot = '$_allowlistDir/spotkind_allowlist_${id}.txt';
  final token = '$_allowlistDir/target_tokens_allowlist_${id}.txt';
  return File(spot).existsSync() && File(token).existsSync();
}

String renderPrompt(
  String template,
  String id,
  String scope,
  String spot,
  String token,
) {
  final repl = {
    '{{MODULE_ID}}': id,
    '{{SHORT_SCOPE}}': scope,
    '{{SPOTKIND_ALLOWLIST}}': spot.trim().isEmpty ? 'none' : spot,
    '{{TARGET_TOKENS_ALLOWLIST}}': token.trim().isEmpty ? 'none' : token,
  };
  var out = template;
  repl.forEach((k, v) => out = out.replaceAll(k, v));
  return out;
}

String renderDispatcherBlock(
  String id,
  String scope,
  String spot,
  String token,
) {
  final s = spot.trim().isEmpty ? 'none' : spot;
  final t = token.trim().isEmpty ? 'none' : token;
  final buf = StringBuffer()
    ..writeln('module_id: $id')
    ..writeln('short_scope: $scope')
    ..writeln('spotkind_allowlist:')
    ..writeln(s)
    ..writeln('target_tokens_allowlist:')
    ..writeln(t);
  return buf.toString().trimRight();
}

void writeAggregate(
  List<String> ready,
  Map<String, String> prompts,
  Map<String, String> dispatchers,
) {
  Directory(_researchDir).createSync(recursive: true);
  Directory(_dispatcherDir).createSync(recursive: true);

  final pBuf = StringBuffer();
  for (final id in ready) {
    final prompt = prompts[id]!;
    pBuf.writeln('GO MODULE: $id');
    pBuf.writeln(prompt);
  }
  File('$_researchDir/_ALL.prompts.txt').writeAsStringSync(pBuf.toString());

  final blocks = <String>[];
  for (final id in ready) {
    blocks.add(dispatchers[id]!);
  }
  File('$_dispatcherDir/_ALL.txt').writeAsStringSync(blocks.join('\n\n'));
}

void maybeWriteSplit(
  List<String> ready,
  Map<String, String> prompts,
  Map<String, String> dispatchers,
  bool overwrite,
) {
  Directory(_researchDir).createSync(recursive: true);
  Directory(_dispatcherDir).createSync(recursive: true);
  for (final id in ready) {
    final pFile = File('$_researchDir/${id}.prompt.txt');
    if (!overwrite && pFile.existsSync()) {
      // skip
    } else {
      pFile.writeAsStringSync('GO MODULE: $id\n${prompts[id]!}');
    }
    final dFile = File('$_dispatcherDir/${id}.txt');
    if (!overwrite && dFile.existsSync()) {
      // skip
    } else {
      dFile.writeAsStringSync(dispatchers[id]! + '\n');
    }
  }
}

void main(List<String> args) {
  final write = args.contains('--write');
  final split = args.contains('--split');
  final overwrite = args.contains('--overwrite');
  String? only;
  final idx = args.indexOf('--only');
  if (idx != -1 && idx + 1 < args.length) {
    only = args[idx + 1];
  }

  try {
    final ids = readCurriculumIds();
    stdout.writeln('ID SOURCE: $idSource');
    final templateFile = File(_templatePath);
    if (!templateFile.existsSync()) {
      stderr.writeln('missing template');
      exit(2);
    }
    final template = _normalize(templateFile.readAsStringSync());
    final shortScope = readShortScope();
    final ready = <String>[];
    final skipped = <String>[];
    final prompts = <String, String>{};
    final dispatchers = <String, String>{};
    var scopeMissing = 0;
    var spotMissing = 0;
    var tokenMissing = 0;

    for (final id in ids) {
      if (only != null && id != only) continue;
      if (isReady(id, shortScope)) {
        ready.add(id);
        if (write) {
          final scope = _normalize(shortScope[id]!);
          final spot =
              readAllow('$_allowlistDir/spotkind_allowlist_${id}.txt') ?? '';
          final token =
              readAllow('$_allowlistDir/target_tokens_allowlist_${id}.txt') ??
              '';
          prompts[id] = renderPrompt(template, id, scope, spot, token);
          dispatchers[id] = renderDispatcherBlock(id, scope, spot, token);
        }
      } else {
        skipped.add(id);
        final scope = shortScope[id];
        if (scope == null || scope.trim().isEmpty) scopeMissing++;
        final spotPath = '$_allowlistDir/spotkind_allowlist_${id}.txt';
        if (!File(spotPath).existsSync()) spotMissing++;
        final tokenPath = '$_allowlistDir/target_tokens_allowlist_${id}.txt';
        if (!File(tokenPath).existsSync()) tokenMissing++;
      }
    }

    stdout.writeln('READY (${ready.length}): ${ready.join(', ')}');
    stdout.writeln('SKIPPED (${skipped.length}): ${skipped.join(', ')}');
    if (!write) {
      stdout.writeln(
        'SKIP REASONS: scope=$scopeMissing, spot=$spotMissing, token=$tokenMissing',
      );
    }

    String? next;
    for (final id in ready) {
      if (!Directory('content/$id/v1').existsSync()) {
        next = id;
        break;
      }
    }
    stdout.writeln('NEXT: ${next ?? 'none'}');

    if (write) {
      writeAggregate(ready, prompts, dispatchers);
      if (split) maybeWriteSplit(ready, prompts, dispatchers, overwrite);
    }
  } on FormatException {
    exit(3);
  } on FileSystemException {
    exit(4);
  }
}
