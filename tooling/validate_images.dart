// Validate image readiness across modules.
// Usage: dart run tooling/validate_images.dart
//
// For each content/<mod>/v1/spec.yml (if present), reads image items and checks:
// - engine in {mermaid, pyplot}
// - out file exists
// - status == "done"
// Counts per-item issues: TODO (status != done), UNKNOWN_ENGINE, MISSING_OUT.
// Output (exact 7 lines), deterministic:
//
// IMAGES
// MODULES <N>
// SPEC_WITH_IMAGES <M>
// RENDERED <R>
// TODO <T>
// UNKNOWN_ENGINE <U>
// MISSING_OUT <X>
// OK <0|1>
//
// Exit 0 iff OK 1, else 1. ASCII-only. No deps.

import 'dart:io';

void main(List<String> args) {
  final modules = _discoverModules();
  final totalModules = modules.length;

  var modulesWithImages = 0;
  var rendered = 0;
  var todo = 0;
  var unknown = 0;
  var missingOut = 0;

  var parseError = false;

  for (final m in modules) {
    final v1 = Directory('content/$m/v1');
    final specFile = File('${v1.path}/spec.yml');
    if (!specFile.existsSync()) continue; // skip module without spec

    _Spec spec;
    try {
      spec = _parseSpec(specFile.readAsLinesSync());
      if (spec.images.isEmpty) continue;
      modulesWithImages++;
    } catch (_) {
      parseError = true;
      continue;
    }

    for (final img in spec.images) {
      final engine = (img.engine.isEmpty
          ? 'unknown'
          : img.engine.toLowerCase());
      final validEngine = engine == 'mermaid' || engine == 'pyplot';
      if (!validEngine) unknown++;

      final outRel = (img.out.isNotEmpty) ? img.out : 'images/${img.slug}.svg';
      final outPath = _joinPaths(v1.path, outRel);
      final outExists = File(outPath).existsSync();
      if (!outExists) missingOut++;

      final isDone = img.status == 'done';
      if (!isDone) todo++;

      if (validEngine && outExists && isDone) rendered++;
    }
  }

  final ok = !parseError && todo == 0 && unknown == 0 && missingOut == 0;

  stdout.writeln('IMAGES');
  stdout.writeln('MODULES $totalModules');
  stdout.writeln('SPEC_WITH_IMAGES $modulesWithImages');
  stdout.writeln('RENDERED $rendered');
  stdout.writeln('TODO $todo');
  stdout.writeln('UNKNOWN_ENGINE $unknown');
  stdout.writeln('MISSING_OUT $missingOut');
  stdout.writeln('OK ${ok ? 1 : 0}');

  if (!ok) exitCode = 1;
}

class _SpecImage {
  final String slug;
  final String engine;
  final String out;
  final String status;
  _SpecImage({
    required this.slug,
    required this.engine,
    required this.out,
    required this.status,
  });
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
        if (!l.startsWith('  - ')) break;
        final header = l.trimLeft();
        final m = RegExp(r'^-\s+slug:\s*(.+)$').firstMatch(header);
        if (m == null) throw 'invalid item header at line ${i + 1}';
        final slug = _stripQuotes(m.group(1)!.trim());
        var engine = 'unknown';
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
            case 'engine':
              engine = val;
              break;
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
        images.add(
          _SpecImage(slug: slug, engine: engine, out: out, status: status),
        );
        continue;
      }
      continue;
    }
    i++;
  }
  return _Spec(images);
}

List<String> _discoverModules() {
  final root = Directory('content');
  if (!root.existsSync()) return <String>[];
  final out = <String>[];
  for (final e in root.listSync()) {
    if (e is! Directory) continue;
    final id = _basename(e.path);
    if (id.isEmpty || id.startsWith('_')) continue;
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
