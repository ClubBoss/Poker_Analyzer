// Generate or update per-module image spec.yml from theory.md placeholders.
// Usage:
//   dart run tooling/gen_image_specs.dart            # process all modules
//   dart run tooling/gen_image_specs.dart <module>   # single module
//
// Parses [[IMAGE: slug | Caption]] in content/<module>/v1/theory.md and
// creates/updates content/<module>/v1/spec.yml with a deterministic schema.
// No external deps. ASCII-only output. Exit 0 on success; exit 1 only on
// I/O or write errors (invalid slugs are reported but do not change exit).

import 'dart:io';

void main(List<String> args) {
  final only = args.isNotEmpty && args.first.trim() != 'all'
      ? args.first.trim()
      : null;

  final modules = _discoverModules(only);
  var created = 0;
  var updated = 0;
  var unchanged = 0;
  var errors = 0;
  var ioError = false;

  for (final m in modules) {
    final dir = Directory('content/$m/v1');
    final theory = File('${dir.path}/theory.md');
    if (!theory.existsSync()) {
      // No theory -> nothing to do for this module.
      unchanged++;
      continue;
    }

    final text = theory.readAsStringSync();
    final placeholders = _parsePlaceholders(text);

    // Filter by slug validity and collect in first-seen order.
    final seen = <String>{};
    final wanted = <_ImagePlaceholder>[];
    for (final p in placeholders) {
      if (!_isValidSlug(p.slug)) {
        stderr.writeln('invalid slug "${p.slug}" in $m/theory.md (skipped)');
        errors++;
        continue;
      }
      if (seen.add(p.slug)) wanted.add(p);
    }

    final specPath = '${dir.path}/spec.yml';
    final specFile = File(specPath);
    _Spec spec;
    var existed = false;
    if (specFile.existsSync()) {
      // Parse existing (best-effort for our own generated shape).
      try {
        spec = _parseSpec(specFile.readAsLinesSync());
        existed = true;
        // Ensure module id is set (keep existing if present, else fill).
        if (spec.module.isEmpty) spec = spec.copyWith(module: m);
      } catch (e) {
        stderr.writeln('failed to parse spec.yml for $m: $e');
        ioError = true;
        continue;
      }
    } else {
      spec = _Spec(module: m, images: <_SpecImage>[]);
    }

    final beforeCount = spec.images.length;
    var captionFilled = 0;

    // Fill empty captions for existing entries and track present slugs
    final present = <String>{};
    for (final img in spec.images) {
      present.add(img.slug);
      if (img.caption.isEmpty) {
        final src = wanted.firstWhere(
          (w) => w.slug == img.slug,
          orElse: () => _ImagePlaceholder(img.slug, ''),
        );
        if (src.caption.isNotEmpty) {
          img.caption = src.caption;
          captionFilled++;
        }
      }
    }

    // Append missing slugs in first-seen order
    for (final p in wanted) {
      if (!present.contains(p.slug)) {
        spec.images.add(
          _SpecImage(
            slug: p.slug,
            caption: p.caption,
            engine: 'unknown',
            src: '',
            out: 'images/${p.slug}.svg',
            status: 'todo',
            notes: '',
          ),
        );
      }
    }

    final changed = spec.images.length != beforeCount || captionFilled > 0;
    if (!changed) {
      unchanged++;
      continue;
    }

    // Write spec.yml
    try {
      final yaml = _emitSpec(spec);
      specFile.writeAsStringSync(yaml);
      if (existed) {
        updated++;
      } else {
        created++;
      }
    } catch (e) {
      stderr.writeln('write error for $specPath: $e');
      ioError = true;
    }
  }

  stdout.writeln(
    'created=$created, updated=$updated, unchanged=$unchanged, errors=$errors',
  );
  if (ioError) exitCode = 1;
}

class _ImagePlaceholder {
  final String slug;
  final String caption;
  const _ImagePlaceholder(this.slug, this.caption);
}

bool _isValidSlug(String s) => RegExp(r'^[a-z0-9_]+$').hasMatch(s);

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

List<_ImagePlaceholder> _parsePlaceholders(String text) {
  final re = RegExp(r'\[\[IMAGE:\s*([^|\]\s]+)\s*\|\s*([^\]]+)\]\]');
  final out = <_ImagePlaceholder>[];
  for (final m in re.allMatches(text)) {
    final slug = m.group(1)!.trim();
    final cap = m.group(2)!.trim();
    out.add(_ImagePlaceholder(slug, cap));
  }
  return out;
}

class _SpecImage {
  final String slug;
  String caption;
  String engine;
  String src;
  String out;
  String status;
  String notes;
  _SpecImage({
    required this.slug,
    required this.caption,
    required this.engine,
    required this.src,
    required this.out,
    required this.status,
    required this.notes,
  });
}

class _Spec {
  final String module;
  final List<_SpecImage> images;
  _Spec({required this.module, required this.images});
  _Spec copyWith({String? module, List<_SpecImage>? images}) =>
      _Spec(module: module ?? this.module, images: images ?? this.images);
}

_Spec _parseSpec(List<String> lines) {
  var module = '';
  final images = <_SpecImage>[];
  var i = 0;
  while (i < lines.length) {
    final line = lines[i].trimRight();
    if (line.startsWith('module:')) {
      module = line.substring('module:'.length).trim();
      module = _stripQuotes(module);
      i++;
      continue;
    }
    if (line.trim() == 'images:') {
      i++;
      while (i < lines.length) {
        final l = lines[i];
        if (!l.startsWith('  - ')) break; // end of images block
        // Expect: '  - slug: <slug>'
        final slugLine = l.trimRight();
        final m = RegExp(r'^-\s+slug:\s*(.+)$').firstMatch(slugLine.trimLeft());
        if (m == null) {
          throw 'invalid spec item header at line ${i + 1}';
        }
        final slug = _stripQuotes(m.group(1)!.trim());
        // Defaults; may be overwritten by following indented lines
        var caption = '';
        var engine = 'unknown';
        var src = '';
        var out = 'images/$slug.svg';
        var status = 'todo';
        var notes = '';
        i++;
        while (i < lines.length) {
          final s = lines[i];
          if (s.startsWith('  - ')) break; // next item
          if (!s.startsWith('    ')) break; // end of this block
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
            case 'engine':
              engine = val;
              break;
            case 'src':
              src = val;
              break;
            case 'out':
              out = val;
              break;
            case 'status':
              status = val;
              break;
            case 'notes':
              notes = val;
              break;
            default:
              // ignore unknown keys
              break;
          }
          i++;
        }
        images.add(
          _SpecImage(
            slug: slug,
            caption: caption,
            engine: engine,
            src: src,
            out: out,
            status: status,
            notes: notes,
          ),
        );
      }
      continue;
    }
    i++;
  }
  return _Spec(module: module, images: images);
}

String _emitSpec(_Spec spec) {
  final b = StringBuffer();
  b.writeln('module: ${spec.module}');
  b.writeln('images:');
  for (final img in spec.images) {
    b.writeln('  - slug: ${img.slug}');
    b.writeln('    caption: "${_escape(img.caption)}"');
    b.writeln('    engine: ${img.engine}');
    b.writeln('    src: "${_escape(img.src)}"');
    b.writeln('    out: ${img.out}');
    b.writeln('    status: ${img.status}');
    b.writeln('    notes: "${_escape(img.notes)}"');
  }
  return b.toString();
}

String _stripQuotes(String s) {
  if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
    final inner = s.substring(1, s.length - 1);
    return inner.replaceAll('\\"', '"').replaceAll('\\n', '\n');
  }
  return s;
}

String _escape(String s) {
  final oneLine = s.replaceAll('\n', ' ');
  return oneLine.replaceAll('\\', r'\\').replaceAll('"', r'\"');
}

String _basename(String path) {
  final norm = path.replaceAll('\\', '/');
  var s = norm;
  if (s.endsWith('/')) s = s.substring(0, s.length - 1);
  final idx = s.lastIndexOf('/');
  return idx == -1 ? s : s.substring(idx + 1);
}
