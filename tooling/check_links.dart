// Validate links and images in theory.md files.
// Usage:
//   dart run tooling/check_links.dart [--json <path>] [--quiet]
// Scans content/*/v1/theory.md and validates:
// - Image refs: ![...](images/<slug>.<ext>) -> file exists (relative to v1).
// - See-also lines: "- <id> (score N) -> ../../<id>/v1/theory.md" -> target exists.
// - Generic relative links: ](images/...) and ](../../<mod>/v1/theory.md) -> must exist.
// Ignores absolute URLs (with scheme or starting with '/').
// Outputs an ASCII table: module|missing_images|missing_links|errors
// --json writes a payload {"rows": [...], "totals": {...}}
// Exit 0 if all totals are zero, otherwise 1. Deterministic ordering.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  String? jsonPath;
  var quiet = false;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--json' && i + 1 < args.length) {
      jsonPath = args[++i];
    } else if (a == '--quiet') {
      quiet = true;
    }
  }

  final modules = _discoverModules();
  final rows = <Map<String, dynamic>>[];

  var totalMissingImages = 0;
  var totalMissingLinks = 0;
  var totalErrors = 0;

  for (final m in modules) {
    final v1 = 'content/$m/v1';
    final theoryPath = '$v1/theory.md';
    final file = File(theoryPath);
    if (!file.existsSync()) {
      // Skip modules without theory.md (by spec: scan existing theory.md).
      continue;
    }

    int missingImages = 0;
    int missingLinks = 0;
    int errors = 0;

    List<String> lines;
    try {
      lines = file.readAsLinesSync();
    } catch (_) {
      // Count as error and continue.
      lines = const <String>[];
      errors++;
    }

    // Validate image refs: ![...](images/...)
    for (final line in lines) {
      for (final url in _extractImageUrls(line)) {
        if (_isAbsolute(url)) continue; // not expected, but be safe
        if (!url.startsWith('images/'))
          continue; // only validate images/... relative
        final p = '$v1/${_normalizeRel(url)}';
        if (!File(p).existsSync()) missingImages++;
      }
    }

    // Validate generic relative links: ](images/...) and ](../../<mod>/v1/theory.md)
    for (final line in lines) {
      for (final url in _extractNonImageUrls(line)) {
        if (_isAbsolute(url)) continue;
        final rel = _normalizeRel(url);
        if (rel.startsWith('images/')) {
          final p = '$v1/$rel';
          if (!File(p).existsSync()) missingLinks++;
        } else if (rel.startsWith('../../')) {
          // Expected: ../../<mod>/v1/theory.md
          final p = '${_resolvePath(v1, rel)}';
          if (!File(p).existsSync()) missingLinks++;
        }
      }
    }

    // Validate see-also bullet lines.
    // Example line: "- module_b (score 7) -> ../../module_b/v1/theory.md"
    final seeAlsoRe = RegExp(
      r'^-\s+([a-z0-9_]+)\s+\(score\s+\d+\)\s+(?:\u2192|->)\s+\.\.\/\.\.\/([a-z0-9_]+)\/v1\/theory\.md\s*$',
    );
    for (final line in lines) {
      final m2 = seeAlsoRe.firstMatch(line.trim());
      if (m2 != null) {
        final id = m2.group(1)!; // left id
        final pathId = m2.group(2)!; // id in the path part
        // Compute canonical expected path, trust the id in the bullet text.
        final target = 'content/$id/v1/theory.md';
        if (id != pathId) {
          // Inconsistency between left id and path id: treat as missing link.
          missingLinks++;
        } else if (!File(target).existsSync()) {
          missingLinks++;
        }
      }
    }

    rows.add({
      'module': m,
      'missing_images': missingImages,
      'missing_links': missingLinks,
      'errors': errors,
    });

    totalMissingImages += missingImages;
    totalMissingLinks += missingLinks;
    totalErrors += errors;
  }

  rows.sort((a, b) => (a['module'] as String).compareTo(b['module'] as String));

  final totals = {
    'modules': rows.length,
    'missing_images': totalMissingImages,
    'missing_links': totalMissingLinks,
    'errors': totalErrors,
  };

  if (!quiet) {
    stdout.writeln('module|missing_images|missing_links|errors');
    for (final r in rows) {
      stdout.writeln(
        '${r['module']}|${r['missing_images']}|${r['missing_links']}|${r['errors']}',
      );
    }
    stdout.writeln(
      'TOTAL|${totals['missing_images']}|${totals['missing_links']}|${totals['errors']}',
    );
  }

  if (jsonPath != null) {
    final f = File(jsonPath);
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(jsonEncode({'rows': rows, 'totals': totals}));
  }

  if (totalMissingImages == 0 && totalMissingLinks == 0 && totalErrors == 0) {
    // ok
  } else {
    exitCode = 1;
  }
}

List<String> _extractImageUrls(String line) {
  // Matches image markdown: ![alt](url)
  final re = RegExp(r'!\[[^\]]*\]\(([^)\s]+)\)');
  return re.allMatches(line).map((m) => m.group(1)!.trim()).toList();
}

List<String> _extractNonImageUrls(String line) {
  // Matches non-image markdown links: [text](url) but not starting with '!'
  final re = RegExp(r'(?<!!)\[[^\]]*\]\(([^)\s]+)\)');
  return re.allMatches(line).map((m) => m.group(1)!.trim()).toList();
}

bool _isAbsolute(String url) {
  if (url.startsWith('/')) return true; // root-absolute
  final scheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+\-.]*:');
  return scheme.hasMatch(url) || url.startsWith('//');
}

String _normalizeRel(String p) {
  // Keep it simple: collapse any "./" segments.
  return p.replaceAll('\\', '/').replaceAll('/./', '/');
}

String _resolvePath(String baseDir, String rel) {
  // baseDir is absolute or relative directory path; rel is a relative path.
  final parts = <String>[];
  for (final s in baseDir.replaceAll('\\', '/').split('/')) {
    if (s.isEmpty) continue;
    parts.add(s);
  }
  for (final s in rel.replaceAll('\\', '/').split('/')) {
    if (s.isEmpty || s == '.') continue;
    if (s == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else {
      parts.add(s);
    }
  }
  return parts.join('/');
}

List<String> _discoverModules() {
  final root = Directory('content');
  if (!root.existsSync()) return <String>[];
  final out = <String>[];
  for (final e in root.listSync()) {
    if (e is! Directory) continue;
    final id = _basename(e.path);
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
