// ASCII-only; pure Dart CLI to normalize JSONL IDs to <moduleId>_... scheme.

import 'dart:convert';
import 'dart:io';

import 'package:poker_analyzer/content/jsonl_validator.dart';

void main(List<String> args) {
  final write = args.contains('--write');
  final force = args.contains('--force') || args.contains('--skip-prevalidate');
  final modulesArg = args.firstWhere(
    (a) => a.startsWith('--modules='),
    orElse: () => '',
  );
  final onlyModules = modulesArg.isEmpty
      ? null
      : modulesArg
            .substring('--modules='.length)
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toSet();

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
      if (onlyModules == null || onlyModules.contains(moduleId)) {
        targets.putIfAbsent(moduleId, () => <File>[]).add(entity);
      }
    }
  }

  // Cross-module duplicate detection (report-only)
  final firstSeenPathById = <String, String>{};
  final crossDupMessages = <String>{};

  // Planned per-line renames within a module
  final plannedChanges =
      <String, Map<int, String>>{}; // path -> {lineIndex -> newId}

  // Per-module used id namespaces to ensure uniqueness across both files
  final usedByModule = <String, Set<String>>{};

  // Load, validate, and plan changes
  for (final entry in targets.entries) {
    final moduleId = entry.key;
    final files = entry.value..sort((a, b) => a.path.compareTo(b.path));

    // Read and validate all files first
    final sources = <String, String>{};
    for (final f in files) {
      final text = _readFile(f.path);
      sources[f.path] = text;
      final report = validateJsonl(text);
      if (!report.ok && !force) {
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

    // Build used set across module from existing ids across both files
    final used = <String>{};
    usedByModule[moduleId] = used;

    // First pass: collect ids and cross-module duplicates
    for (final f in files) {
      final p = f.path.replaceAll('\\', '/');
      final lines = const LineSplitter().convert(sources[p]!);
      for (var i = 0; i < lines.length; i++) {
        final raw = lines[i].trim();
        if (raw.isEmpty || raw.startsWith('#')) continue;
        Map<String, dynamic> obj;
        try {
          obj = jsonDecode(lines[i]) as Map<String, dynamic>;
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
        used.add(idVal);

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
      }
    }

    // Second pass: plan renames for non-canonical ids
    for (final f in files) {
      final p = f.path.replaceAll('\\', '/');
      final name = p.split('/').last;
      final kindPrefix = name == 'demos.jsonl' ? 'demo' : 'drill';
      final lines = const LineSplitter().convert(sources[p]!);
      for (var i = 0; i < lines.length; i++) {
        final raw = lines[i];
        final trimmed = raw.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
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
        if (idVal.startsWith('${moduleId}_')) continue; // already canonical

        // Compute new canonical id with attempt to preserve trailing _NNN if free
        final preserved = _tryPreserveSuffix(moduleId, kindPrefix, idVal, used);
        final newId = preserved ?? _nextAvailable(moduleId, kindPrefix, used);
        plannedChanges.putIfAbsent(p, () => <int, String>{})[i] = newId;
        used.add(newId);
      }
    }
  }

  if (plannedChanges.isEmpty && crossDupMessages.isEmpty) {
    stdout.writeln('No changes.');
    exit(0);
  }

  // Build new contents in-memory and validate
  final newContents = <String, String>{};
  for (final entry in plannedChanges.entries) {
    final path = entry.key;
    final original = _readFile(path);
    final changed = _applyLineRenames(original, entry.value);
    newContents[path] = changed;
  }

  // Print planned renames (dry-run)
  for (final e in plannedChanges.entries) {
    final path = e.key;
    final original = _readFile(path);
    final lines = const LineSplitter().convert(original);
    for (final re in e.value.entries) {
      final oldId = _extractIdFromLine(lines[re.key]);
      stdout.writeln("RENAME $path: '$oldId' -> '${re.value}'");
    }
  }

  // Print cross-module duplicates (diagnostics only)
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
  final lines = const LineSplitter().convert(source).toList();
  final idField = RegExp(r'("id"\s*:\s*")([^"]*)(")');
  lineToNewId.forEach((idx, newId) {
    if (idx < 0 || idx >= lines.length) return;
    final line = lines[idx];
    final m = idField.firstMatch(line);
    if (m == null) return;
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

String? _tryPreserveSuffix(
  String moduleId,
  String kind,
  String currentId,
  Set<String> used,
) {
  final suffixRe = RegExp(r'.*_([0-9]{3})$');
  final m = suffixRe.firstMatch(currentId);
  if (m == null) return null;
  final n = int.tryParse(m.group(1)!);
  if (n == null) return null;
  final cand = _formatId(moduleId, kind, n);
  if (used.contains(cand)) return null;
  return cand;
}

String _nextAvailable(String moduleId, String kind, Set<String> used) {
  var n = 1;
  while (true) {
    final cand = _formatId(moduleId, kind, n);
    if (!used.contains(cand)) return cand;
    n++;
  }
}

String _formatId(String moduleId, String kind, int n) {
  final num = n.toString().padLeft(3, '0');
  return '${moduleId}_${kind}_$num';
}

bool _sameContent(String a, String b) => a.length == b.length && a == b;
