// Sync image status in spec.yml with actual SVG presence.
// Usage:
//   dart run tooling/sync_image_status.dart [--module <id>] [--dry-run] [--quiet]
//
// Scans content/<module>/v1/spec.yml and updates each image entry's `status`
// to `done` if the `out` file exists, otherwise `todo`.
//
// Minimal YAML parsing, ASCII-only, no new deps. Preserves item order and all
// fields; only mutates the `status` value (adds the line if missing).
// Exit 0 on success; 1 only on I/O/parse errors. Idempotent.

import 'dart:io';

void main(List<String> args) {
  String? onlyModule;
  var dryRun = false;
  var quiet = false;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--module' && i + 1 < args.length) {
      onlyModule = args[++i];
    } else if (a == '--dry-run') {
      dryRun = true;
    } else if (a == '--quiet') {
      quiet = true;
    }
  }

  final modules = _discoverModules(onlyModule);
  var updatedTotal = 0;
  var alreadyTotal = 0;
  var errorsTotal = 0;

  for (final m in modules) {
    final v1 = Directory('content/$m/v1');
    final specPath = '${v1.path}/spec.yml';
    final f = File(specPath);
    if (!f.existsSync()) {
      // No spec -> nothing to sync for this module.
      continue;
    }

    String raw;
    try {
      raw = f.readAsStringSync();
    } catch (e) {
      if (!quiet) stderr.writeln('read error for $specPath: $e');
      errorsTotal++;
      continue;
    }
    final lines = raw.split('\n');

    final res = _syncModule(m, v1.path, lines);
    if (res.ioOrParseError) {
      errorsTotal++;
      continue;
    }

    if (!quiet) {
      stdout.writeln(
        'SYNC-IMG $m: updated=${res.updated} already=${res.already} items=${res.items}',
      );
    }

    updatedTotal += res.updated;
    alreadyTotal += res.already;

    if (!dryRun && res.updated > 0) {
      try {
        // Join using '\n' to keep consistent with our read split.
        File(specPath).writeAsStringSync(res.newLines.join('\n'));
      } catch (e) {
        if (!quiet) stderr.writeln('write error for $specPath: $e');
        errorsTotal++;
      }
    }
  }

  stdout.writeln(
    'SYNC-IMG updated=$updatedTotal already=$alreadyTotal errors=$errorsTotal',
  );
  if (errorsTotal > 0) exitCode = 1;
}

class _SyncResult {
  final List<String> newLines;
  final int updated;
  final int already;
  final int items;
  final bool ioOrParseError;
  _SyncResult(
    this.newLines,
    this.updated,
    this.already,
    this.items,
    this.ioOrParseError,
  );
}

_SyncResult _syncModule(String module, String v1dir, List<String> lines) {
  final newLines = <String>[];
  var i = 0;
  var inImages = false;
  var updated = 0;
  var already = 0;
  var items = 0;

  while (i < lines.length) {
    final line = lines[i];
    if (!inImages) {
      newLines.add(line);
      if (line.trim() == 'images:') {
        inImages = true;
      }
      i++;
      continue;
    }

    // Inside images block
    if (line.startsWith('  - ')) {
      // Parse item block [i, end)
      final start = i;
      var end = i + 1;
      while (end < lines.length && lines[end].startsWith('    ')) {
        end++;
      }
      final block = List<String>.from(lines.sublist(start, end));
      final parsed = _parseItemBlock(block);
      if (parsed == null) {
        // Parse error -> propagate and stop module processing
        return _SyncResult(lines, 0, 0, 0, true);
      }

      items++;
      final outRel = (parsed.out.isNotEmpty)
          ? parsed.out
          : 'images/${parsed.slug}.svg';
      final outPath = _joinPaths(v1dir, outRel);
      final exists = File(outPath).existsSync();
      final want = exists ? 'done' : 'todo';

      if (parsed.statusIdx >= 0) {
        final curr = _valueFromKVLine(block[parsed.statusIdx]);
        if (curr == want) {
          already++;
          // Append unchanged block
          newLines.addAll(block);
        } else {
          // Replace status line, preserve indentation
          final indent = _indentOf(block[parsed.statusIdx]);
          block[parsed.statusIdx] = '${indent}status: $want';
          updated++;
          newLines.addAll(block);
        }
      } else {
        // Insert new status line before notes if present, else at end
        final insertIdx = (parsed.notesIdx >= 0)
            ? parsed.notesIdx
            : block.length;
        block.insert(insertIdx, '    status: $want');
        updated++;
        newLines.addAll(block);
      }

      i = end;
      continue;
    }

    // Check if we are leaving the images block
    if (!line.startsWith('    ') && !line.startsWith('  - ')) {
      inImages = false;
    }

    // Pass-through any non-item line inside images (unlikely)
    newLines.add(line);
    i++;
  }

  return _SyncResult(newLines, updated, already, items, false);
}

class _ItemParsed {
  final String slug;
  final String out;
  final int statusIdx; // index within the block list (0-based)
  final int
  notesIdx; // index where notes key appears; helps insert before notes
  _ItemParsed(this.slug, this.out, this.statusIdx, this.notesIdx);
}

_ItemParsed? _parseItemBlock(List<String> block) {
  if (block.isEmpty) return null;
  // Header like: '  - slug: <slug>' (allow extra spaces)
  final head = block.first.trimLeft();
  final m = RegExp(r'^-\s+slug:\s*(.+)$').firstMatch(head);
  if (m == null) return null;
  final slug = _stripQuotes(m.group(1)!.trim());

  var out = 'images/$slug.svg';
  var statusIdx = -1;
  var notesIdx = -1;

  for (var j = 1; j < block.length; j++) {
    final l = block[j];
    if (!l.startsWith('    ')) break;
    final t = l.trim();
    final kv = t.split(':');
    if (kv.isEmpty) continue;
    final key = kv.first.trim();
    final val = _stripQuotes(t.substring(key.length + 1).trim());
    switch (key) {
      case 'out':
        if (val.isNotEmpty) out = val;
        break;
      case 'status':
        statusIdx = j;
        break;
      case 'notes':
        if (notesIdx == -1) notesIdx = j;
        break;
      default:
        break;
    }
  }
  return _ItemParsed(slug, out, statusIdx, notesIdx);
}

String _valueFromKVLine(String line) {
  final t = line.trim();
  final idx = t.indexOf(':');
  if (idx == -1) return '';
  return _stripQuotes(t.substring(idx + 1).trim());
}

String _indentOf(String line) {
  var n = 0;
  while (n < line.length && line[n] == ' ') n++;
  return ' ' * n;
}

List<String> _discoverModules(String? only) {
  final root = Directory('content');
  if (!root.existsSync()) return <String>[];
  final out = <String>[];
  for (final e in root.listSync()) {
    if (e is! Directory) continue;
    final id = _basename(e.path);
    if (id.isEmpty || id.startsWith('_')) continue;
    if (only != null && id != only) continue;
    final v1 = Directory('${e.path}/v1');
    if (v1.existsSync()) out.add(id);
  }
  out.sort();
  return out;
}

String _basename(String path) {
  final norm = path.replaceAll('\\', '/');
  var s = norm;
  if (s.endsWith('/')) s = s.substring(0, s.length - 1);
  final idx = s.lastIndexOf('/');
  return idx == -1 ? s : s.substring(idx + 1);
}

String _stripQuotes(String s) {
  if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
    final inner = s.substring(1, s.length - 1);
    return inner.replaceAll('\\"', '"').replaceAll('\\n', '\n');
  }
  return s;
}

String _joinPaths(String a, String b) {
  final left = a.replaceAll('\\', '/');
  final right = b.replaceAll('\\', '/');
  if (left.endsWith('/')) return left + right;
  return left + '/' + right;
}
