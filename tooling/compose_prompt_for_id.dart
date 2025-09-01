import 'dart:convert';
import 'dart:io';

const _dispatcherPath = 'prompts/dispatcher/_ALL.txt';
const _tplPath = 'prompts/research/_TEMPLATE_v2.txt';

String _ascii(String s) {
  final b = StringBuffer();
  for (final c in s.codeUnits) {
    if (c == 0x0D) continue; // drop CR
    b.writeCharCode(c <= 0x7F ? c : 0x3F); // non-ASCII -> '?'
  }
  return b.toString();
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

class _Block {
  final String id;
  final String shortScope;
  final List<String> spotKinds;
  final List<String> tokens;
  _Block(this.id, this.shortScope, this.spotKinds, this.tokens);
}

_Block _parseBlock(String id, String block) {
  final lines = const LineSplitter().convert(block);
  String shortScope = '';
  int spotIdx = -1, tokIdx = -1;

  for (var i = 0; i < lines.length; i++) {
    final l = lines[i].trimRight();
    if (l.startsWith('short_scope:')) {
      shortScope = l.substring('short_scope:'.length).trim();
    } else if (l == 'spotkind_allowlist:') {
      spotIdx = i;
    } else if (l == 'target_tokens_allowlist:') {
      tokIdx = i;
    }
  }

  final spotKinds = <String>[];
  final tokens = <String>[];

  if (spotIdx != -1 && tokIdx != -1) {
    for (var i = spotIdx + 1; i < tokIdx; i++) {
      final t = lines[i].trim();
      if (t.isNotEmpty) spotKinds.add(t);
    }
    for (var i = tokIdx + 1; i < lines.length; i++) {
      final t = lines[i].trim();
      if (t.isNotEmpty) tokens.add(t);
    }
  }

  return _Block(id, shortScope, spotKinds, tokens);
}

void main(List<String> args) {
  String? id;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--id') {
      if (i + 1 >= args.length) {
        stderr.writeln('missing id');
        exit(2);
      }
      id = args[++i];
    } else {
      stderr.writeln('unknown arg');
      exit(2);
    }
  }
  if (id == null || id.isEmpty) {
    stderr.writeln('missing --id');
    exit(2);
  }

  try {
    final dispatcherRaw = _ascii(File(_dispatcherPath).readAsStringSync());
    final blocks = _splitDispatcher(dispatcherRaw);
    final match = blocks.firstWhere(
      (e) => e.key == id,
      orElse: () => throw StateError('module not found: $id'),
    );

    final parsed = _parseBlock(match.key, match.value);
    if (parsed.shortScope.isEmpty) {
      stderr.writeln('missing short_scope for $id');
      exit(2);
    }

    final tpl = File(_tplPath).readAsStringSync();

    final spotBlock =
        (parsed.spotKinds.length == 1 && parsed.spotKinds[0] == 'none')
        ? 'none'
        : parsed.spotKinds.join('\n');

    final tokensBlock =
        (parsed.tokens.isEmpty ||
            (parsed.tokens.length == 1 && parsed.tokens[0] == 'none'))
        ? 'none'
        : parsed.tokens.join('\n');

    final prompt = tpl
        .replaceAll('{{MODULE_ID}}', parsed.id)
        .replaceAll('{{SHORT_SCOPE}}', parsed.shortScope)
        .replaceAll('{{SPOTKIND_ALLOWLIST}}', spotBlock)
        .replaceAll('{{TARGET_TOKENS_ALLOWLIST}}', tokensBlock);

    stdout.write(prompt);
  } on FileSystemException {
    stderr.writeln('io error');
    exit(4);
  } on FormatException {
    stderr.writeln('parse error');
    exit(2);
  } on StateError catch (e) {
    stderr.writeln(e.toString());
    exit(2);
  }
}
