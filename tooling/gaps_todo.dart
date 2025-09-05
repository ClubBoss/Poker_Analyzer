// Build a prioritized TODO plan to reach green gates per module.
// Usage:
//   dart run tooling/gaps_todo.dart [--module <id>] [--quiet] [--no-shell]
//
// Inputs (artifacts preferred, else recompute quietly unless --no-shell):
//   - build/gaps.json          (from content_gap_report.dart)
//   - build/term_lint.json     (from term_lint.dart)
//   - build/links_report.json  (from check_links.dart; optional)
//   - content/*/v1/spec.yml    (to count images not rendered)
//
// Output:
//   - Writes build/gaps_todo.md with deterministic sections per module.
//   - Prints one-line summary:
//       TODO modules=<N> with_gaps=<K> actions=<M> written=build/gaps_todo.md
// Exit code: 0 on success; 1 on I/O/parse errors. ASCII-only. No deps.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  String? onlyModule;
  var quiet = false;
  var noShell = false;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--module' && i + 1 < args.length) {
      onlyModule = args[++i];
    } else if (a == '--quiet') {
      quiet = true;
    } else if (a == '--no-shell') {
      noShell = true;
    }
  }

  // Ensure artifacts, optionally regenerating silently
  final need = <_Artifact>[
    _Artifact('build/gaps.json', [
      [
        'dart',
        'run',
        'tooling/content_gap_report.dart',
        '--json',
        'build/gaps.json',
      ],
    ]),
    _Artifact('build/term_lint.json', [
      [
        'dart',
        'run',
        'tooling/term_lint.dart',
        '--json',
        'build/term_lint.json',
        '--quiet',
      ],
    ]),
    _Artifact('build/links_report.json', [
      [
        'dart',
        'run',
        'tooling/check_links.dart',
        '--json',
        'build/links_report.json',
      ],
    ], optional: true),
  ];

  for (final art in need) {
    if (File(art.path).existsSync()) continue;
    if (noShell) {
      if (!art.optional) {
        stderr.writeln(
          'missing artifact: ${art.path} (use without --no-shell to generate)',
        );
        exitCode = 1;
        return;
      }
      continue; // optional; ignore
    }
    for (final cmd in art.commands) {
      final r = await _run(cmd);
      // links checker may fail when there are issues; still consider file if produced
      if (File(art.path).existsSync()) break;
      // If file not produced, try next command (if any)
    }
  }

  // Load artifacts
  final gaps = _loadGaps('build/gaps.json');
  final terms = _loadTerms('build/term_lint.json');
  final links = _loadLinks('build/links_report.json');
  if (gaps == null || terms == null) {
    exitCode = 1;
    return;
  }

  // Build module list deterministically
  final modules = _discoverModules(onlyModule);

  // Compose per-module entries
  final entries = <_Entry>[];
  for (final m in modules) {
    final g = gaps[m] ?? _Gap.defaultFor(m);
    final t = terms[m] ?? _Terms(0, 0);
    final lk = links?[m];
    final ir = _imagesNotDoneCount(m);

    final issues =
        g.missingSections.length +
        (g.wordcountOutOfRange ? 1 : 0) +
        (g.imagesMissing ? 1 : 0) +
        (g.demoCountBad ? 1 : 0) +
        (g.drillCountBad ? 1 : 0) +
        (g.invalidSpotKind ? 1 : 0) +
        (g.invalidTargets ? 1 : 0) +
        (g.duplicateIds ? 1 : 0) +
        (g.offTreeSizes ? 1 : 0) +
        t.badTerms +
        t.fvBadCase +
        ((lk != null) ? lk.missingImages + lk.missingLinks : 0) +
        ir;

    entries.add(
      _Entry(
        module: m,
        gap: g,
        terms: t,
        links: lk,
        imagesNotDone: ir,
        issueScore: issues,
      ),
    );
  }

  // Summary
  final totalModules = entries.length;
  final withGaps = entries.where((e) => e.issueScore > 0).length;
  final totalActions = entries.fold<int>(0, (a, b) => a + b.issueScore);

  // Top 10 by issues
  final top = List<_Entry>.from(entries)
    ..sort((a, b) {
      final d = b.issueScore.compareTo(a.issueScore);
      if (d != 0) return d;
      return a.module.compareTo(b.module);
    });
  final top10 = top.take(10).toList();

  // Emit markdown
  final out = StringBuffer();
  out.writeln('# Gaps TODO');
  out.writeln('Modules: $totalModules');
  out.writeln('With gaps: $withGaps');
  out.writeln('Top 10 modules by issues:');
  for (var i = 0; i < top10.length; i++) {
    final e = top10[i];
    out.writeln('${i + 1}. ${e.module} (issues=${e.issueScore})');
  }
  out.writeln('');

  // Per-module sections, sorted by module id
  entries.sort((a, b) => a.module.compareTo(b.module));
  for (final e in entries) {
    final g = e.gap;
    final t = e.terms;
    final lk = e.links;
    final missing = g.missingSections.isEmpty
        ? '-'
        : g.missingSections.join(',');
    out.writeln('## ${e.module}');
    out.writeln(
      '- [ ] theory: missing_sections=$missing, wordcount_out_of_range=${_b(g.wordcountOutOfRange)}, images_missing=${_b(g.imagesMissing)}',
    );
    out.writeln('- [ ] demos: count_ok=${_b(!g.demoCountBad)}');
    out.writeln(
      '- [ ] drills: count_ok=${_b(!g.drillCountBad)}, off_tree_sizes=${_b(g.offTreeSizes)}',
    );
    out.writeln('- [ ] ids: duplicates=${_b(g.duplicateIds)}');
    out.writeln(
      '- [ ] allowlists: invalid_spot_kind=${_b(g.invalidSpotKind)}, invalid_targets=${_b(g.invalidTargets)}',
    );
    out.writeln(
      '- [ ] terminology: bad_terms=${t.badTerms}, fv_bad_case=${t.fvBadCase}',
    );
    if (lk != null) {
      out.writeln(
        '- [ ] links: missing_images=${lk.missingImages}, missing_links=${lk.missingLinks}',
      );
    }
    out.writeln('- [ ] images_render: not_done=${e.imagesNotDone}');
    out.writeln('');
  }

  // Write file
  final outFile = File('build/gaps_todo.md');
  try {
    outFile.parent.createSync(recursive: true);
    outFile.writeAsStringSync(out.toString());
  } catch (e) {
    stderr.writeln('write error: build/gaps_todo.md: $e');
    exitCode = 1;
    return;
  }

  if (!quiet) {
    stdout.writeln(
      'TODO modules=$totalModules with_gaps=$withGaps actions=$totalActions written=build/gaps_todo.md',
    );
  } else {
    // Even with --quiet, still print the one-liner per spec
    stdout.writeln(
      'TODO modules=$totalModules with_gaps=$withGaps actions=$totalActions written=build/gaps_todo.md',
    );
  }
}

class _Artifact {
  final String path;
  final List<List<String>> commands;
  final bool optional;
  _Artifact(this.path, this.commands, {this.optional = false});
}

Future<int> _run(List<String> cmd) async {
  try {
    final p = await Process.run(cmd.first, cmd.sublist(1));
    return p.exitCode;
  } catch (_) {
    return 1;
  }
}

class _Entry {
  final String module;
  final _Gap gap;
  final _Terms terms;
  final _Links? links;
  final int imagesNotDone;
  final int issueScore;
  _Entry({
    required this.module,
    required this.gap,
    required this.terms,
    required this.links,
    required this.imagesNotDone,
    required this.issueScore,
  });
}

class _Gap {
  final String module;
  final List<String> missingSections;
  final bool wordcountOutOfRange;
  final bool imagesMissing;
  final bool demoCountBad;
  final bool drillCountBad;
  final bool invalidSpotKind;
  final bool invalidTargets;
  final bool duplicateIds;
  final bool offTreeSizes;
  _Gap({
    required this.module,
    required this.missingSections,
    required this.wordcountOutOfRange,
    required this.imagesMissing,
    required this.demoCountBad,
    required this.drillCountBad,
    required this.invalidSpotKind,
    required this.invalidTargets,
    required this.duplicateIds,
    required this.offTreeSizes,
  });
  static _Gap defaultFor(String m) => _Gap(
    module: m,
    missingSections: const <String>[],
    wordcountOutOfRange: false,
    imagesMissing: false,
    demoCountBad: false,
    drillCountBad: false,
    invalidSpotKind: false,
    invalidTargets: false,
    duplicateIds: false,
    offTreeSizes: false,
  );
}

class _Terms {
  final int badTerms;
  final int fvBadCase;
  _Terms(this.badTerms, this.fvBadCase);
}

class _Links {
  final int missingImages;
  final int missingLinks;
  _Links(this.missingImages, this.missingLinks);
}

Map<String, _Gap>? _loadGaps(String path) {
  final f = File(path);
  if (!f.existsSync()) return null;
  try {
    final obj = jsonDecode(f.readAsStringSync());
    if (obj is! Map<String, dynamic>) return null;
    final rows = obj['rows'];
    if (rows is! List) return null;
    final out = <String, _Gap>{};
    for (final r in rows) {
      if (r is Map) {
        final m = r['module']?.toString() ?? '';
        if (m.isEmpty) continue;
        final missing = <String>[];
        final ms = r['missing_sections'];
        if (ms is List) {
          for (final x in ms) {
            if (x is String && x.isNotEmpty) missing.add(x);
          }
        }
        out[m] = _Gap(
          module: m,
          missingSections: missing,
          wordcountOutOfRange: r['wordcount_out_of_range'] == true,
          imagesMissing: r['images_missing'] == true,
          demoCountBad: r['demo_count_bad'] == true,
          drillCountBad: r['drill_count_bad'] == true,
          invalidSpotKind: r['invalid_spot_kind'] == true,
          invalidTargets: r['invalid_targets'] == true,
          duplicateIds: r['duplicate_ids'] == true,
          offTreeSizes: r['off_tree_sizes'] == true,
        );
      }
    }
    return out;
  } catch (_) {
    return null;
  }
}

Map<String, _Terms>? _loadTerms(String path) {
  final f = File(path);
  if (!f.existsSync()) return null;
  try {
    final obj = jsonDecode(f.readAsStringSync());
    if (obj is! Map<String, dynamic>) return null;
    final rows = obj['rows'];
    if (rows is! List) return null;
    final out = <String, _Terms>{};
    for (final r in rows) {
      if (r is Map) {
        final m = r['module']?.toString() ?? '';
        if (m.isEmpty) continue;
        final bt = (r['bad_terms'] is int) ? r['bad_terms'] as int : 0;
        final fv = (r['fv_bad_case'] is int) ? r['fv_bad_case'] as int : 0;
        out[m] = _Terms(bt, fv);
      }
    }
    return out;
  } catch (_) {
    return null;
  }
}

Map<String, _Links>? _loadLinks(String path) {
  final f = File(path);
  if (!f.existsSync()) return null;
  try {
    final obj = jsonDecode(f.readAsStringSync());
    if (obj is! Map<String, dynamic>) return null;
    final rows = obj['rows'];
    if (rows is! List) return null;
    final out = <String, _Links>{};
    for (final r in rows) {
      if (r is Map) {
        final m = r['module']?.toString() ?? '';
        if (m.isEmpty) continue;
        final mi = (r['missing_images'] is int)
            ? r['missing_images'] as int
            : 0;
        final ml = (r['missing_links'] is int) ? r['missing_links'] as int : 0;
        out[m] = _Links(mi, ml);
      }
    }
    return out;
  } catch (_) {
    return null;
  }
}

int _imagesNotDoneCount(String module) {
  final v1 = Directory('content/$module/v1');
  final specFile = File('${v1.path}/spec.yml');
  if (!specFile.existsSync()) return 0;
  _Spec spec;
  try {
    spec = _parseSpec(specFile.readAsLinesSync());
  } catch (_) {
    return 0; // treat parse error as 0 to avoid blocking generation
  }
  var n = 0;
  for (final img in spec.images) {
    final outRel = (img.out.isNotEmpty) ? img.out : 'images/${img.slug}.svg';
    final outPath = _joinPaths(v1.path, outRel);
    final exists = File(outPath).existsSync();
    if (!exists || img.status != 'done') n++;
  }
  return n;
}

class _SpecImage {
  final String slug;
  final String out;
  final String status;
  _SpecImage(this.slug, this.out, this.status);
}

class _Spec {
  final List<_SpecImage> images;
  _Spec(this.images);
}

_Spec _parseSpec(List<String> lines) {
  final images = <_SpecImage>[];
  var i = 0;
  while (i < lines.length) {
    final line = lines[i].trimRight();
    if (line.trim() == 'images:') {
      i++;
      while (i < lines.length) {
        final l = lines[i];
        if (!l.startsWith('  - ')) break; // end of images block
        final header = l.trimLeft();
        final m = RegExp(r'^-\s+slug:\s*(.+)$').firstMatch(header);
        if (m == null) throw 'invalid item header at line ${i + 1}';
        final slug = _stripQuotes(m.group(1)!.trim());
        var out = 'images/$slug.svg';
        var status = '';
        i++;
        while (i < lines.length) {
          final s = lines[i];
          if (s.startsWith('  - ')) break;
          if (!s.startsWith('    ')) break;
          final t = s.trim();
          final kv = t.split(':');
          if (kv.isEmpty) {
            i++;
            continue;
          }
          final key = kv.first.trim();
          final val = _stripQuotes(t.substring(key.length + 1).trim());
          switch (key) {
            case 'out':
              if (val.isNotEmpty) out = val;
              break;
            case 'status':
              status = val;
              break;
            default:
              break;
          }
          i++;
        }
        images.add(_SpecImage(slug, out, status));
        continue;
      }
      continue;
    }
    i++;
  }
  return _Spec(images);
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

String _b(bool v) => v ? '1' : '0';
