// Derive per-module allowlists from existing content.
// Usage:
//   dart run tooling/derive_allowlists.dart [--module <id>] [--write] [--clear] [--quiet]
//
// Scans content/<module>/v1/{demos.jsonl,drills.jsonl} and derives:
// - tooling/allowlists/spotkind_allowlist_<module>.txt  (from spot_kind|spotKind)
// - tooling/allowlists/target_tokens_allowlist_<module>.txt  (from target|targets)
//
// Default (--dry-run) prints a diff-style preview for files that would change.
// --write writes/overwrites files. --clear writes sentinel `none` when derived
// set is empty. Deterministic ordering. ASCII-only. No new deps.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  String? onlyModule;
  var write = false;
  var clearEmpty = false;
  var quiet = false;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--module' && i + 1 < args.length) {
      onlyModule = args[++i];
    } else if (a == '--write') {
      write = true;
    } else if (a == '--clear') {
      clearEmpty = true;
    } else if (a == '--quiet') {
      quiet = true;
    }
  }

  final modules = _discoverModules(onlyModule);
  var wrote = 0;
  var skipped = 0;
  var emptyFiles = 0;
  var ioError = false;

  for (final m in modules) {
    final base = 'content/$m/v1';
    final demos = File('$base/demos.jsonl');
    final drills = File('$base/drills.jsonl');

    final spotKinds = <String>{};
    final targets = <String>{};

    void scanLine(String line) {
      final s = line.trim();
      if (s.isEmpty) return;
      try {
        final obj = jsonDecode(s);
        if (obj is Map<String, dynamic>) {
          final sk1 = obj['spot_kind'];
          final sk2 = obj['spotKind'];
          if (sk1 is String && _isAscii(sk1)) spotKinds.add(sk1);
          if (sk2 is String && _isAscii(sk2)) spotKinds.add(sk2);
          final tgts = obj['targets'];
          final tgt = obj['target'];
          if (tgts is List) {
            for (final t in tgts) {
              if (t is String && _isAscii(t)) targets.add(t);
            }
          }
          if (tgt is List) {
            for (final t in tgt) {
              if (t is String && _isAscii(t)) targets.add(t);
            }
          } else if (tgt is String) {
            if (_isAscii(tgt)) targets.add(tgt);
          }
        }
      } catch (_) {
        // ignore malformed lines
      }
    }

    if (demos.existsSync()) {
      try {
        for (final line in demos.readAsLinesSync()) {
          scanLine(line);
        }
      } catch (e) {
        if (!quiet) stderr.writeln('read error: ${demos.path}: $e');
        ioError = true;
        continue;
      }
    }
    if (drills.existsSync()) {
      try {
        for (final line in drills.readAsLinesSync()) {
          scanLine(line);
        }
      } catch (e) {
        if (!quiet) stderr.writeln('read error: ${drills.path}: $e');
        ioError = true;
        continue;
      }
    }

    final spotList = spotKinds.toList()..sort();
    final targetList = targets.toList()..sort();

    final spotPath = 'tooling/allowlists/spotkind_allowlist_${m}.txt';
    final targetPath = 'tooling/allowlists/target_tokens_allowlist_${m}.txt';

    final spotNew = spotList.isEmpty && clearEmpty ? ['none'] : spotList;
    final targetNew = targetList.isEmpty && clearEmpty ? ['none'] : targetList;

    final spotOld = _readListFile(spotPath);
    final targetOld = _readListFile(targetPath);

    final spotChanged = !_listEquals(spotOld, spotNew);
    final targetChanged = !_listEquals(targetOld, targetNew);

    final spotEmpty = spotList.isEmpty;
    final targetEmpty = targetList.isEmpty;
    emptyFiles += (spotEmpty ? 1 : 0) + (targetEmpty ? 1 : 0);

    if (!quiet) {
      stdout.writeln(
        'ALLOWLISTS $m: spot=${spotList.length} target=${targetList.length} wrote=${(spotChanged ? 1 : 0) + (targetChanged ? 1 : 0)} empty=${(spotEmpty ? 1 : 0) + (targetEmpty ? 1 : 0)}',
      );
      // Diff-style preview for changed files in dry-run
      if (!write) {
        if (spotChanged) _printDiff(spotPath, spotOld, spotNew);
        if (targetChanged) _printDiff(targetPath, targetOld, targetNew);
      }
    }

    if (write) {
      // Ensure directory exists
      try {
        Directory('tooling/allowlists').createSync(recursive: true);
      } catch (e) {
        if (!quiet) stderr.writeln('mkdir error: tooling/allowlists: $e');
        ioError = true;
        continue;
      }
      if (spotChanged) {
        if (_writeListFile(spotPath, spotNew)) {
          wrote++;
        } else {
          ioError = true;
        }
      } else {
        skipped++;
      }
      if (targetChanged) {
        if (_writeListFile(targetPath, targetNew)) {
          wrote++;
        } else {
          ioError = true;
        }
      } else {
        skipped++;
      }
    } else {
      // Dry-run: count as skipped if unchanged; would write if changed
      if (spotChanged) {
        wrote++;
      } else {
        skipped++;
      }
      if (targetChanged) {
        wrote++;
      } else {
        skipped++;
      }
    }
  }

  stdout.writeln(
    'ALLOWLISTS modules=${modules.length} wrote=$wrote skipped=$skipped empty=$emptyFiles',
  );
  if (ioError) exitCode = 1;
}

bool _writeListFile(String path, List<String> lines) {
  try {
    final f = File(path);
    f.parent.createSync(recursive: true);
    final content = lines.join('\n') + (lines.isEmpty ? '' : '\n');
    f.writeAsStringSync(content);
    return true;
  } catch (_) {
    return false;
  }
}

List<String> _readListFile(String path) {
  final f = File(path);
  if (!f.existsSync()) return <String>[];
  try {
    final out = <String>[];
    for (final l in f.readAsLinesSync()) {
      final s = l.trim();
      if (s.isEmpty) continue;
      if (s.startsWith('#')) continue;
      if (!_isAscii(s)) continue;
      out.add(s);
    }
    out.sort();
    return out;
  } catch (_) {
    return <String>[];
  }
}

void _printDiff(String path, List<String> oldL, List<String> newL) {
  stdout.writeln('--- $path (old)');
  stdout.writeln('+++ $path (new)');
  final oldSet = oldL.toSet();
  final newSet = newL.toSet();
  final removed = <String>[]..addAll(oldL.where((e) => !newSet.contains(e)));
  final added = <String>[]..addAll(newL.where((e) => !oldSet.contains(e)));
  for (final r in removed) stdout.writeln('- $r');
  for (final a in added) stdout.writeln('+ $a');
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
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

bool _isAscii(String s) {
  for (final code in s.codeUnits) {
    if (code > 0x7F) return false;
  }
  return true;
}
