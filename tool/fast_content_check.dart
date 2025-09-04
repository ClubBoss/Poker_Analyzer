import 'dart:io';

import 'package:poker_analyzer/content/jsonl_validator.dart';
import 'package:poker_analyzer/content/jsonl_loader.dart';

void main(List<String> args) {
  final matcher = RegExp(r"/v\d+/");
  final root = Directory('content');
  final targets = <File>[];

  if (!root.existsSync()) {
    stderr.writeln('No content/ directory found');
    exit(0);
  }

  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final p = entity.path.replaceAll('\\', '/');
    final name = p.split('/').last;
    if ((name == 'demos.jsonl' || name == 'drills.jsonl') &&
        matcher.hasMatch(p)) {
      targets.add(entity);
    }
  }

  var allOk = true;

  // Repo-wide duplicate id guard across all scanned files.
  final firstSeenPathById = <String, String>{};
  final globalDuplicateMessages = <String>{};

  for (final f in targets) {
    final path = f.path;
    String text;
    try {
      text = f.readAsStringSync();
    } catch (e) {
      stdout.writeln('FAIL $path');
      stdout.writeln('  - read error: $e');
      allOk = false;
      continue;
    }
    final report = validateJsonl(text);

    // Collect per-file diagnostics (validation + prefix checks)
    final diagnostics = <String>[];

    if (!report.ok) {
      final sample = report.issues.take(5).toList();
      for (final issue in sample) {
        diagnostics.add('  - line ${issue.line}: ${issue.message}');
      }
      final remaining = report.issues.length - sample.length;
      if (remaining > 0) {
        diagnostics.add('  ... and $remaining more');
      }
    }

    // Derive moduleId from path: content/<moduleId>/v*/...
    final moduleId = _moduleIdFromPath(path);

    bool fileOk = report.ok;
    if (report.ok) {
      // Parse and enforce id prefix; also collect for global duplicates.
      try {
        final objs = parseJsonl(text);
        var prefixMismatches = 0;
        for (final obj in objs) {
          final idVal = obj['id'];
          if (idVal is String) {
            // Repo-wide duplicate collection across files
            final seenAt = firstSeenPathById[idVal];
            if (seenAt == null) {
              firstSeenPathById[idVal] = path;
            } else if (seenAt != path) {
              globalDuplicateMessages.add(
                "duplicate id across files: '$idVal' in $seenAt and $path",
              );
            }

            // Prefix check
            if (!idVal.startsWith('${moduleId}_')) {
              if (prefixMismatches < 5) {
                diagnostics.add(
                  "  - id prefix mismatch: '$idVal' (path: $path, module: $moduleId)",
                );
              }
              prefixMismatches++;
            }
          } else {
            // This should be covered by validateJsonl, but guard anyway.
            diagnostics.add('  - invalid id field (not string)');
            fileOk = false;
          }
        }
        if (prefixMismatches > 5) {
          diagnostics.add('  ... and ${prefixMismatches - 5} more');
        }
        if (prefixMismatches > 0) fileOk = false;
      } catch (e) {
        // parseJsonl should not throw after ok report, but be safe.
        diagnostics.add('  - parse error: $e');
        fileOk = false;
      }
    }

    if (fileOk) {
      stdout.writeln('OK   $path');
    } else {
      allOk = false;
      stdout.writeln('FAIL $path');
      for (final d in diagnostics) {
        stdout.writeln(d);
      }
    }
  }

  // Print repo-wide duplicate diagnostics (do not alter OK/FAIL lines above)
  if (globalDuplicateMessages.isNotEmpty) {
    allOk = false;
    for (final m in globalDuplicateMessages) {
      stdout.writeln(m);
    }
  }

  if (!allOk) exit(1);
}

String _moduleIdFromPath(String p) {
  final norm = p.replaceAll('\\', '/');
  final parts = norm.split('/');
  final idx = parts.indexOf('content');
  if (idx != -1 && idx + 1 < parts.length) {
    return parts[idx + 1];
  }
  // Fallback: look for a segment exactly matching vN and take the one before it.
  final vIdx = parts.indexWhere((e) => RegExp(r'^v\d+$').hasMatch(e));
  if (vIdx > 0) return parts[vIdx - 1];
  return '';
}
