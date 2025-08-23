import 'dart:io';

String _ascii(String s) {
  final buf = StringBuffer();
  for (final code in s.codeUnits) {
    if (code == 0x0D) continue; // drop CR
    buf.writeCharCode(code < 0x80 ? code : 0x3F);
  }
  return buf.toString();
}

Map<String, String> _splitBlocks(String raw) {
  final reg = RegExp(r'^GO MODULE:\s+([a-z0-9_]+)\s*$', multiLine: true);
  final matches = reg.allMatches(raw).toList();
  if (matches.isEmpty || matches.first.start != 0) {
    throw const FormatException('parse error');
  }
  final out = <String, String>{};
  for (var i = 0; i < matches.length; i++) {
    final id = matches[i].group(1)!;
    if (out.containsKey(id)) {
      throw const FormatException('duplicate id');
    }
    final start = matches[i].start;
    final end = i + 1 < matches.length ? matches[i + 1].start : raw.length;
    out[id] = raw.substring(start, end);
  }
  return out;
}

void main(List<String> args) {
  const path = 'prompts/research/_ALL.prompts.txt';
  try {
    final file = File(path);
    final raw = _ascii(file.readAsStringSync());
    final blocks = _splitBlocks(raw);
    if (args.contains('--list')) {
      for (final id in blocks.keys) {
        stdout.writeln(id);
      }
      return;
    }
    String? id;
    final idx = args.indexOf('--id');
    if (idx != -1) {
      if (idx + 1 >= args.length) {
        stderr.writeln('missing id');
        exit(2);
      }
      id = args[idx + 1];
    }
    if (id != null) {
      final block = blocks[id];
      if (block == null) {
        stderr.writeln('id not found');
        exit(2);
      }
      stdout.write(block);
      return;
    }
    stdout.write(blocks.values.first);
  } on FileSystemException {
    stderr.writeln('io error');
    exit(4);
  } on FormatException {
    stderr.writeln('parse error');
    exit(2);
  }
}
