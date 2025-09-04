// ASCII-only; pure Dart CLI to fix intra-module duplicate IDs in JSONL content.

import 'dart:convert';
import 'dart:io';

import 'package:poker_analyzer/content/jsonl_validator.dart';

void main(List<String> args) {
  final write = args.contains('--write');

  final root = Directory('content');
  if (!root.existsSync()) {
    stderr.writeln('No content/ directory found');
    exit(1);
  }

  final matcherV = RegExp(r"/v\d+/");
  final targets = <String, List<File>>{}; // moduleId -> [files]

  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final p = entity.path.replaceAll('\\', '/');
    final name = p.split('/').last;
    if ((name == 'demos.jsonl' || name == 'drills.jsonl') &&
        matcherV.hasMatch(p)) {
      final moduleId = _moduleIdFromPath(p);
      targets.putIfAbsent(moduleId, () => <File>[]).add(entity);
    }
  }

  // Cross-module duplicate detection (report-only)
  final firstSeenPathById = <String, String>{};
  final crossDupMessages = <String>{};

  // Planned per-line renames within a module
  final plannedChanges =
      <String, Map<int, String>>{}; // path -> {lineIndex -> newId}

  for (final entry in targets.entries) {
    final moduleId = entry.key;
    final files = entry.value..sort((a, b) => a.path.compareTo(b.path));

    // Read and validate all files first
    final sources = <String, String>{};
    for (final f in files) {
      final text = _readFile(f.path);
      sources[f.path] = text;
      final report = validateJsonl(text);
      if (!report.ok) {
        stdout.writeln("VALIDATION FAIL ${f.path}");
        for (final issue in report.issues.take(5)) {
          stdout.writeln('  - line ${issue.line}: ${issue.message}');
        }
        final remaining =
            report.issues.length -
            (report.issues.length > 5 ? 5 : report.issues.length);
        if (remaining > 0) stdout.writeln('  ... and $remaining more');
        exit(1);
      }
    }

    // Build used set across module and plan renames for second+ duplicates
    final used = <String>{};
    for (final f in files) {
      final p = f.path.replaceAll('\\', '/');
      final lines = LineSplitter.split(sources[p]!).toList();
      for (var i = 0; i < lines.length; i++) {
        final raw = lines[i];
        final trimmed = raw.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) {
          continue;
        }
        Map<String, dynamic> obj;
        try {
          obj = jsonDecode(raw) as Map<String, dynamic>;
        } catch (_) {
          stdout.writeln("VALIDATION FAIL $p");
          stdout.writeln('  - line ${i + 1}: invalid JSON');
          exit(1);
        }
        final idVal = obj['id'];
        if (idVal is! String || idVal.isEmpty) {
          stdout.writeln("VALIDATION FAIL $p");
          stdout.writeln('  - line ${i + 1}: missing or invalid id');
          exit(1);
        }

        // Cross-module duplicates collection
        final seenAt = firstSeenPathById[idVal];
        if (seenAt == null) {
          firstSeenPathById[idVal] = p;
        } else {
          final otherModule = _moduleIdFromPath(seenAt);
          if (otherModule != moduleId && seenAt != p) {
            crossDupMessages.add(
              "duplicate id across files: '$idVal' in $seenAt and $p",
            );
          }
        }

        // Intra-module duplicate handling
        if (used.add(idVal)) {
          continue; // first occurrence is kept
        }

        // Plan a unique replacement with <moduleId>_ prefix
        final newId = _nextUniqueId(moduleId, idVal, used);
        plannedChanges.putIfAbsent(p, () => <int, String>{})[i] = newId;
        used.add(newId);
      }
    }
  }

  // Apply or print planned changes; also re-validate after modifications
  if (plannedChanges.isEmpty && crossDupMessages.isEmpty) {
    stdout.writeln('No changes.');
    exit(0);
  }

  // Build new contents in-memory and validate
  final newContents = <String, String>{};
  for (final module in targets.keys) {
    final files = targets[module]!;
    for (final f in files) {
      final path = f.path.replaceAll('\\', '/');
      final original = _readFile(path);
      final changed = _applyLineRenames(
        original,
        plannedChanges[path] ?? const {},
      );

      // If not writing and file unchanged, we still keep original for re-validation.
      newContents[path] = changed;

      // Print dry-run rename lines
      final renames = plannedChanges[path];
      if (renames != null) {
        // We need to recover old and new ids for printing
        final lines = LineSplitter.split(original).toList();
        for (final entry in renames.entries) {
          final ln = entry.key;
          final newId = entry.value;
          final oldId = _extractIdFromLine(lines[ln]);
          stdout.writeln("RENAME $path: '$oldId' -> '$newId'");
        }
      }
    }
  }

  // Print cross-module duplicates (report-only)
  for (final m in crossDupMessages) {
    stdout.writeln(m);
  }

  // Validate new contents
  for (final e in newContents.entries) {
    final report = validateJsonl(e.value);
    if (!report.ok) {
      stdout.writeln('POST-VALIDATION FAIL ${e.key}');
      for (final issue in report.issues.take(5)) {
        stdout.writeln('  - line ${issue.line}: ${issue.message}');
      }
      final remaining =
          report.issues.length -
          (report.issues.length > 5 ? 5 : report.issues.length);
      if (remaining > 0) stdout.writeln('  ... and $remaining more');
      exit(1);
    }
  }

  if (write) {
    // Persist changes
    for (final e in newContents.entries) {
      if (!_sameContent(_readFile(e.key), e.value)) {
        File(e.key).writeAsStringSync(e.value, flush: true);
      }
    }
  }

  exit(0);
}

String _readFile(String path) {
  try {
    return File(path).readAsStringSync();
  } catch (e) {
    stderr.writeln('IO ERROR reading $path: $e');
    exit(1);
  }
}

String _applyLineRenames(String source, Map<int, String> lineToNewId) {
  if (lineToNewId.isEmpty) return source;
  final lines = LineSplitter.split(source).toList();
  final idField = RegExp(r'("id"\s*:\s*")([^"]*)(")');
  lineToNewId.forEach((idx, newId) {
    if (idx < 0 || idx >= lines.length) return;
    final line = lines[idx];
    final m = idField.firstMatch(line);
    if (m == null) return; // Should not happen for valid lines
    final replaced = line.replaceRange(
      m.start,
      m.end,
      '${m.group(1)}$newId${m.group(3)}',
    );
    lines[idx] = replaced;
  });
  return lines.join('\n') + (source.endsWith('\n') ? '\n' : '');
}

String _extractIdFromLine(String line) {
  final idField = RegExp(r'("id"\s*:\s*")([^"]*)(")');
  final m = idField.firstMatch(line);
  return m != null ? (m.group(2) ?? '') : '';
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

String _nextUniqueId(String moduleId, String currentId, Set<String> used) {
  final prefix = '${moduleId}_';

  // If current id already has moduleId_ prefix and ends with _NNN, bump from there.
  final suffixRe = RegExp(r'^(.*)_([0-9]{3})$');
  if (currentId.startsWith(prefix)) {
    final m = suffixRe.firstMatch(currentId);
    if (m != null) {
      // ignore: prefer_final_locals
      var base = m.group(1)!; // keep everything before numeric suffix
      // ignore: prefer_final_locals
      var n = int.parse(m.group(2)!);
      while (true) {
        n++;
        final cand = '${base}_${n.toString().padLeft(3, '0')}';
        if (!used.contains(cand)) return cand;
      }
    }
  }

  // Otherwise, start with moduleId_001 and bump until unique
  // ignore: prefer_final_locals
  var n = 1;
  while (true) {
    final cand = '${prefix}${n.toString().padLeft(3, '0')}';
    if (!used.contains(cand)) return cand;
    n++;
  }
}

bool _sameContent(String a, String b) => a.length == b.length && a == b;
