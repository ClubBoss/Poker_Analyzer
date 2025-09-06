// Auto-scaffold missing theory.md sections and add the first image placeholder.
// Usage:
//   dart run tooling/theory_scaffold_fix.dart [--module <id>] [--fix-dry-run] [--fix] [--quiet]
//
// Behavior:
// - Reads build/gaps.json (from tooling/content_gap_report.dart).
// - For each module with missing sections, inserts exact section headers (plain lines)
//   in the deterministic order provided by the JSON list.
// - If theory.md is missing, creates a skeleton with all required sections.
// - If images_missing=1 and no [[IMAGE: ...]] placeholders exist, inserts a single
//   placeholder line after the first header: [[IMAGE: overview_diagram | Overview diagram]].
// - Idempotent and ASCII-only. Does not modify existing section content.
// - Exit 0 on success; 1 on I/O errors.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  String? onlyModule;
  var writeFixes = false;
  var quiet = false;

  // Accept both en-dash and double-dash forms just in case.
  final List<String> a2 = args
      .map((a) => a.replaceAll('–', '--'))
      .toList(growable: false); // normalize en-dash to "--"

  for (var i = 0; i < a2.length; i++) {
    final a = a2[i];
    if (a == '--module' && i + 1 < a2.length) {
      onlyModule = a2[++i];
    } else if (a == '--fix') {
      writeFixes = true;
    } else if (a == '--fix-dry-run') {
      writeFixes = false;
    } else if (a == '--quiet') {
      quiet = true;
    }
  }

  final gp = File('build/gaps.json');
  if (!gp.existsSync()) {
    stderr.writeln('missing build/gaps.json. Run: make gap');
    exitCode = 1;
    return;
  }

  Map<String, dynamic> root;
  try {
    root = jsonDecode(gp.readAsStringSync()) as Map<String, dynamic>;
  } catch (e) {
    stderr.writeln('failed to parse build/gaps.json: $e');
    exitCode = 1;
    return;
  }

  final rows = root['rows'];
  if (rows is! List) {
    stderr.writeln('invalid gaps.json: missing rows[]');
    exitCode = 1;
    return;
  }

  final knownHeaders = <String>[
    'What it is',
    'Why it matters',
    'Rules of thumb',
    'Mini example',
    'Common mistakes',
    'Mini-glossary',
    'Contrast',
  ];
  final knownSet = Set<String>.from(knownHeaders);

  var modulesScanned = 0;
  var created = 0;
  var sectionsAdded = 0;
  var imageAdded = 0;
  var unchanged = 0;
  var ioError = false;

  for (final r in rows) {
    if (r is! Map) continue;
    final module = r['module']?.toString() ?? '';
    if (module.isEmpty) continue;
    if (onlyModule != null && module != onlyModule) continue;

    modulesScanned++;
    final v1dir = Directory('content/$module/v1');
    final theoryPath = '${v1dir.path}/theory.md';
    final theoryFile = File(theoryPath);

    final msDyn = r['missing_sections'];
    final msList = <String>[];
    if (msDyn is List) {
      for (final e in msDyn) {
        if (e is String) msList.add(e);
      }
    }
    final imagesMissing = r['images_missing'] == true;

    final needsSkeleton =
        msList.contains('theory.md') || !theoryFile.existsSync();

    // Plan operations
    var planCreate = false;
    final planAddHeaders = <String>[];
    var planAddImage = false;

    // Read or construct base content
    List<String> lines = <String>[];
    if (needsSkeleton) {
      planCreate = true;
      // Build a skeleton with all required headers in canonical order.
      lines = [];
      for (var i = 0; i < knownHeaders.length; i++) {
        final h = knownHeaders[i];
        lines.add(h);
        lines.add('');
      }
      // Image placeholder will be inserted below if requested.
    } else {
      try {
        final raw = theoryFile.readAsStringSync();
        // Normalize to LF for stable processing
        final normalized = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
        lines = const LineSplitter().convert(normalized);
      } catch (e) {
        if (!quiet) stderr.writeln('read error: $theoryPath: $e');
        ioError = true;
        continue;
      }
    }

    // Determine missing headers to insert (ignore non_ascii and unknowns)
    if (!needsSkeleton && msList.isNotEmpty) {
      for (final h in msList) {
        if (!knownSet.contains(h))
          continue; // skip special markers like non_ascii
        // if already present (exact line), skip
        final present = _hasExactLine(lines, h);
        if (!present) planAddHeaders.add(h);
      }
    }

    // Determine if we should add the image placeholder
    if (imagesMissing) {
      final anyImage = _hasImagePlaceholder(lines);
      if (!anyImage) planAddImage = true;
    }

    if (!planCreate && planAddHeaders.isEmpty && !planAddImage) {
      unchanged++;
      continue;
    }

    if (!writeFixes) {
      if (!quiet) {
        final parts = <String>[];
        if (planCreate) parts.add('create theory.md');
        if (planAddHeaders.isNotEmpty) {
          parts.add('add sections: ' + planAddHeaders.join(', '));
        }
        if (planAddImage) parts.add('add image placeholder');
        stdout.writeln('THEORY-FIX ${module}: ' + parts.join('; '));
      }
      continue;
    }

    // Apply changes
    var changed = false;

    if (planCreate) {
      try {
        if (!v1dir.existsSync()) v1dir.createSync(recursive: true);
        theoryFile.writeAsStringSync(lines.join('\n'));
        created++;
        changed = true;
      } catch (e) {
        if (!quiet) stderr.writeln('write error: $theoryPath: $e');
        ioError = true;
        continue;
      }
    }

    if (planAddHeaders.isNotEmpty) {
      // Append missing headers at EOF, preserving a blank separator
      if (lines.isNotEmpty && lines.last.trim().isNotEmpty) lines.add('');
      for (final h in planAddHeaders) {
        if (!_hasExactLine(lines, h)) {
          lines.add(h);
          lines.add('');
          sectionsAdded++;
          changed = true;
        }
      }
    }

    if (planAddImage) {
      final idx = _firstHeaderIndex(lines, knownHeaders);
      final insertAt = (idx == -1) ? 0 : (idx + 1);
      final placeholder = '[[IMAGE: overview_diagram | Overview diagram]]';
      // Ensure there is exactly one blank line after insertion (readability)
      lines.insert(insertAt, placeholder);
      if (insertAt + 1 >= lines.length ||
          lines[insertAt + 1].trim().isNotEmpty) {
        lines.insert(insertAt + 1, '');
      }
      imageAdded++;
      changed = true;
    }

    if (changed) {
      try {
        theoryFile.writeAsStringSync(lines.join('\n'));
      } catch (e) {
        if (!quiet) stderr.writeln('write error: $theoryPath: $e');
        ioError = true;
        continue;
      }
    } else {
      unchanged++;
    }
  }

  if (!quiet) {
    stdout.writeln(
      'THEORY-FIX modules=$modulesScanned created=$created sections_added=$sectionsAdded image_added=$imageAdded unchanged=$unchanged',
    );
  }
  if (ioError && writeFixes) exitCode = 1; // dry-run always 0
}

bool _hasExactLine(List<String> lines, String needle) {
  for (final l in lines) {
    if (l.trimRight() == needle) return true;
  }
  return false;
}

bool _hasImagePlaceholder(List<String> lines) {
  final re = RegExp(r'^\[\[IMAGE:\s*[^\]|\s]+\s*\|\s*[^\]]+\]\]\s*');
  for (final l in lines) {
    if (re.hasMatch(l.trimRight())) return true;
  }
  return false;
}

int _firstHeaderIndex(List<String> lines, List<String> known) {
  final set = Set<String>.from(known);
  for (var i = 0; i < lines.length; i++) {
    final t = lines[i].trimRight();
    if (set.contains(t)) return i;
  }
  return -1;
}
