// Insert Markdown image links below [[IMAGE: slug | Caption]] placeholders.
// Usage:
//   dart run tooling/link_images_in_theory.dart
//   dart run tooling/link_images_in_theory.dart --module <id>
//   dart run tooling/link_images_in_theory.dart --dry-run
//
// For each module under content/*/v1/ with theory.md and spec.yml, ensures a
// line of the form:
//   ![Caption](images/<slug>.svg)
// immediately follows the placeholder line. Caption is taken from spec.yml if
// available; otherwise from the placeholder; fallback to slug.
// Idempotent: if the exact line already follows, no change.
// ASCII-only. No external deps.

import 'dart:io';

void main(List<String> args) {
  String? onlyModule;
  var dryRun = false;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--module' && i + 1 < args.length) {
      onlyModule = args[++i];
    } else if (a == '--dry-run') {
      dryRun = true;
    }
  }

  final modules = _discoverModules(onlyModule);
  var ioError = false;

  for (final m in modules) {
    final versionDir = Directory('content/$m/v1');
    final theory = File('${versionDir.path}/theory.md');
    final specFile = File('${versionDir.path}/spec.yml');

    if (!theory.existsSync()) {
      // No theory -> skip module silently.
      continue;
    }

    final Map<String, String> captionBySlug = {};
    var missingSpecCount = 0;
    if (specFile.existsSync()) {
      try {
        final spec = _parseSpec(specFile.readAsLinesSync());
        for (final img in spec.images) {
          captionBySlug[img.slug] = img.caption;
        }
      } catch (e) {
        stderr.writeln('spec parse error in $m: $e');
        ioError = true;
        continue;
      }
    }

    List<String> lines;
    try {
      lines = theory.readAsLinesSync();
    } catch (e) {
      stderr.writeln('read error in $m/theory.md: $e');
      ioError = true;
      continue;
    }

    final ph = _findPlaceholders(lines.join('\n'));
    var linked = 0;
    var already = 0;
    var errors = 0;

    // We will insert lines by index; track offset adjustments.
    var offset = 0;
    for (final p in ph) {
      final idx = p.lineIndex + offset; // current index in lines list
      final slug = p.slug;
      var cap = captionBySlug[slug];
      if (cap == null || cap.isEmpty) {
        cap = p.caption.isNotEmpty ? p.caption : slug;
        if (!captionBySlug.containsKey(slug)) missingSpecCount++;
      }
      final expected = '![${cap}](${p.outputPath})';
      final nextIdx = idx + 1;
      final hasNext = nextIdx < lines.length;
      if (hasNext && lines[nextIdx] == expected) {
        already++;
        continue;
      }

      if (dryRun) {
        stdout.writeln('DRY ${m}: + ${expected}');
        linked++;
        continue;
      }

      try {
        lines.insert(nextIdx, expected);
        linked++;
        offset++;
      } catch (e) {
        stderr.writeln('insert error in $m at slug $slug: $e');
        errors++;
      }
    }

    if (!dryRun && linked > 0) {
      try {
        theory.writeAsStringSync(lines.join('\n'));
      } catch (e) {
        stderr.writeln('write error in $m/theory.md: $e');
        ioError = true;
        continue;
      }
    }

    stdout.writeln(
      '$m: linked=$linked, already=$already, missing_spec=$missingSpecCount, errors=$errors',
    );
  }

  if (ioError) exitCode = 1;
}

class _SpecImage {
  final String slug;
  final String caption;
  final String out;
  _SpecImage({required this.slug, required this.caption, required this.out});
}

class _Spec {
  final String module;
  final List<_SpecImage> images;
  _Spec({required this.module, required this.images});
}

_Spec _parseSpec(List<String> lines) {
  var module = '';
  final images = <_SpecImage>[];
  var i = 0;
  while (i < lines.length) {
    final line = lines[i].trimRight();
    if (line.startsWith('module:')) {
      module = _stripQuotes(line.substring('module:'.length).trim());
      i++;
      continue;
    }
    if (line.trim() == 'images:') {
      i++;
      while (i < lines.length) {
        final l = lines[i];
        if (!l.startsWith('  - ')) break;
        final slugLine = l.trimRight();
        final m = RegExp(r'^-\s+slug:\s*(.+)$').firstMatch(slugLine.trimLeft());
        if (m == null) throw 'invalid spec item header at line ${i + 1}';
        final slug = _stripQuotes(m.group(1)!.trim());
        var caption = '';
        var out = 'images/$slug.svg';
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
            case 'caption':
              caption = val;
              break;
            case 'out':
              if (val.isNotEmpty) out = val;
              break;
          }
          i++;
        }
        images.add(_SpecImage(slug: slug, caption: caption, out: out));
      }
      continue;
    }
    i++;
  }
  return _Spec(module: module, images: images);
}

class _Placeholder {
  final int lineIndex; // zero-based index in lines
  final String slug;
  final String caption;
  final String outputPath; // relative to v1 dir
  _Placeholder({
    required this.lineIndex,
    required this.slug,
    required this.caption,
    required this.outputPath,
  });
}

List<_Placeholder> _findPlaceholders(String text) {
  final re = RegExp(r'\[\[IMAGE:\s*([^|\]\s]+)\s*\|\s*([^\]]+)\]\]');
  final out = <_Placeholder>[];
  final lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final m = re.firstMatch(line);
    if (m == null) continue;
    final slug = m.group(1)!.trim();
    final cap = m.group(2)!.trim();
    // Expected out path format
    final outPath = 'images/$slug.svg';
    out.add(
      _Placeholder(lineIndex: i, slug: slug, caption: cap, outputPath: outPath),
    );
  }
  return out;
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

String _stripQuotes(String s) {
  if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
    final inner = s.substring(1, s.length - 1);
    return inner.replaceAll('\\"', '"').replaceAll('\\n', '\n');
  }
  return s;
}

String _basename(String path) {
  final norm = path.replaceAll('\\', '/');
  var s = norm;
  if (s.endsWith('/')) s = s.substring(0, s.length - 1);
  final idx = s.lastIndexOf('/');
  return idx == -1 ? s : s.substring(idx + 1);
}
