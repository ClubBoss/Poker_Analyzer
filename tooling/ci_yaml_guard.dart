import 'dart:io';

class _Context {
  final int indent;
  final Set<String> keys = {};
  bool pathSeen = false;
  final bool checkUploadArtifact;
  _Context(this.indent, {this.checkUploadArtifact = false});
}

int _indentOf(String line) {
  var i = 0;
  while (i < line.length && line[i] == ' ') i++;
  return i;
}

void main() {
  final issues = <String>[];
  final dir = Directory('.github/workflows');
  if (!dir.existsSync()) exit(0);
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.yml') || f.path.endsWith('.yaml'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final rel = file.path.startsWith('./') ? file.path.substring(2) : file.path;
    final lines = file.readAsLinesSync();
    final stack = <_Context>[_Context(-1)];
    int? blockIndent;
    bool expectUploadWith = false;
    for (var i = 0; i < lines.length; i++) {
      final lineNo = i + 1;
      final line = lines[i];
      if (blockIndent != null) {
        if (_indentOf(line) > blockIndent) {
          continue; // inside block scalar
        } else {
          blockIndent = null;
        }
      }
      final trimmed = line.trimLeft();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }
      final m = RegExp(r'^(\s*)(- )?([A-Za-z0-9_-]+):').firstMatch(line);
      if (m == null) continue;
      final baseIndent = m.group(1)!.length;
      final isList = m.group(2) != null;
      final indent = baseIndent + (isList ? 2 : 0);
      final key = m.group(3)!;

      if (isList) {
        while (stack.isNotEmpty && indent <= stack.last.indent) {
          stack.removeLast();
        }
        stack.add(_Context(indent));
      } else {
        while (stack.isNotEmpty && indent < stack.last.indent) {
          stack.removeLast();
        }
      }
      final ctx = stack.last;
      if (ctx.checkUploadArtifact && key == 'path') {
        if (ctx.pathSeen) {
          issues.add('CI-YAML key-dupe $rel:$lineNo path');
        }
        ctx.pathSeen = true;
      } else {
        if (!ctx.keys.add(key)) {
          issues.add('CI-YAML key-dupe $rel:$lineNo $key');
        }
      }
      final rest = line.substring(m.end).trim();
      if (key == 'uses' && rest.contains('actions/upload-artifact@v4')) {
        expectUploadWith = true;
      } else if (key == 'with') {
        final special = expectUploadWith && indent == stack.last.indent;
        expectUploadWith = false;
        final child = _Context(indent + 2, checkUploadArtifact: special);
        stack.add(child);
        continue;
      } else {
        expectUploadWith = false;
      }
      if (rest.isEmpty) {
        stack.add(_Context(indent + 2));
      } else if (rest == '|' || rest == '>') {
        blockIndent = indent;
      }
    }
  }
  if (issues.isNotEmpty) {
    for (final issue in issues) {
      stdout.writeln(issue);
    }
    exit(1);
  }
}
