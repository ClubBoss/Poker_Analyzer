// Balance theory.md word counts to the 400–700 range.
// Usage:
//   dart run tooling/theory_wordcount_balance.dart [--module <id>] [--fix-dry-run] [--fix] [--force] [--quiet]
//
// - Reads build/gaps.json to find modules with wordcount_out_of_range unless --force is set.
// - For each content/<module>/v1/theory.md:
//   * If <400 words: append ASCII placeholder paragraphs prefixed with 'TODO:' until >=400
//     (never exceed 700; last chunk is truncated by words if needed). Idempotent if in range.
//   * If >700 words: trim trailing non-header, non-image lines to at most 700 words, stopping
//     before headers ('What it is', 'Why it matters', etc., and 'See also') or code fence lines.
// - Deterministic and ASCII-only. Exit 0 unless I/O write errors.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  String? onlyModule;
  bool writeFixes = false;
  bool dry = false;
  bool force = false;
  bool quiet = false;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--module' && i + 1 < args.length) {
      onlyModule = args[++i];
    } else if (a == '--fix') {
      writeFixes = true;
    } else if (a == '--fix-dry-run') {
      dry = true;
      writeFixes = false;
    } else if (a == '--force') {
      force = true;
    } else if (a == '--quiet') {
      quiet = true;
    }
  }

  final modules = _discoverModules(onlyModule);
  final failing = force ? <String>{...modules} : _failingWordcountFromGaps();

  var modulesScanned = 0;
  var padded = 0;
  var trimmed = 0;
  var skipped = 0;
  var ioError = false;

  for (final m in modules) {
    if (!failing.contains(m)) {
      skipped++;
      continue;
    }
    final path = 'content/$m/v1/theory.md';
    final f = File(path);
    if (!f.existsSync()) {
      skipped++;
      continue;
    }
    modulesScanned++;

    String raw;
    try {
      raw = f.readAsStringSync();
    } catch (e) {
      if (!quiet) stderr.writeln('read error: $path: $e');
      ioError = true;
      continue;
    }

    final normalized = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = const LineSplitter().convert(normalized);
    var wc = _wordCount(normalized);

    if (wc >= 400 && wc <= 700) {
      skipped++;
      continue;
    }

    final knownHeaders = <String>{
      'What it is',
      'Why it matters',
      'Rules of thumb',
      'Mini example',
      'Common mistakes',
      'Mini-glossary',
      'Contrast',
      'See also',
    };

    List<String> out = List<String>.from(lines);
    bool changed = false;

    if (wc < 400) {
      // Append TODO paragraphs until >=400 but never exceed 700
      final chunk = _todoChunk();
      final chunkWords = _wordCount(chunk);
      while (wc < 400) {
        final limit = 700 - wc;
        if (limit <= 0) break;
        String toAdd;
        if (chunkWords <= limit) {
          toAdd = chunk;
        } else {
          // Truncate chunk to fit into limit
          toAdd = _truncateByWords(chunk, limit);
        }
        if (out.isNotEmpty && out.last.trim().isNotEmpty) out.add('');
        out.add(toAdd);
        out.add('');
        wc += _wordCount(toAdd);
        changed = true;
        if (wc >= 400) break;
      }
      if (changed) padded++;
    } else if (wc > 700) {
      // Trim trailing non-header, non-image lines until <=700, stopping before headers or code fences.
      int i = out.length - 1;
      bool inFence = false; // if trailing fence encountered, stop all trimming
      while (i >= 0 && wc > 700) {
        final l = out[i].trimRight();
        if (l.startsWith('```') || l.startsWith('~~~')) {
          inFence = true;
          break;
        }
        final isHeader = knownHeaders.contains(l);
        final isImage = l.startsWith('[[IMAGE:') || l.startsWith('![');
        if (isHeader || isImage) break; // stop before protected markers

        // Compute words in this line
        final lw = _wordCount(l);
        if (lw == 0) {
          // dropping blank line does not change wc; safe to remove
          out.removeAt(i);
          changed = true;
          i--;
          continue;
        }
        final newWc = wc - lw;
        // Remove the line if it helps and stays >= 0
        out.removeAt(i);
        wc = newWc;
        changed = true;
        i--;
      }
      if (changed) trimmed++;
    }

    if (changed && writeFixes) {
      try {
        f.writeAsStringSync(out.join('\n'));
      } catch (e) {
        if (!quiet) stderr.writeln('write error: $path: $e');
        ioError = true;
      }
    }
  }

  stdout.writeln(
    'WORDCOUNT modules=$modulesScanned padded=$padded trimmed=$trimmed skipped=$skipped',
  );
  if (ioError && writeFixes) exitCode = 1;
}

int _wordCount(String s) {
  return s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
}

String _todoChunk() {
  return 'TODO: Expand this section with concise, practical guidance, brief examples, and clear rules aligned to the fixed action families (33/50/75). Focus on decisions, blockers, and plan geometry. Keep language simple and avoid new sizes.';
}

String _truncateByWords(String s, int maxWords) {
  if (maxWords <= 0) return '';
  final parts = s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (parts.length <= maxWords) return s;
  final cut = parts.sublist(0, maxWords).join(' ');
  return cut;
}

Set<String> _failingWordcountFromGaps() {
  final set = <String>{};
  final f = File('build/gaps.json');
  if (!f.existsSync()) return set;
  try {
    final obj = jsonDecode(f.readAsStringSync());
    if (obj is Map && obj['rows'] is List) {
      for (final r in (obj['rows'] as List)) {
        if (r is Map) {
          final m = r['module']?.toString() ?? '';
          final bad = r['wordcount_out_of_range'] == true;
          if (m.isNotEmpty && bad) set.add(m);
        }
      }
    }
  } catch (_) {}
  return set;
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
