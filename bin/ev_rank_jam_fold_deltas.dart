import 'dart:convert';
import 'dart:io';

import 'package:poker_analyzer/services/board_texture_classifier.dart';

Future<void> main(List<String> args) async {
  String? inPath;
  String? dirPath;
  String? glob;
  var limit = 20;
  var absDelta = false;
  double? minDelta;
  var action = 'any';
  var sprBucket = 'any';
  var format = 'json';
  var uniqueBy = 'none';
  var per = 'none';
  var perLimit = 1;
  List<String>? fields;
  List<String>? textures;
  List<String>? includes;
  List<String>? excludes;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--in' && i + 1 < args.length) {
      inPath = args[++i];
    } else if (arg == '--dir' && i + 1 < args.length) {
      dirPath = args[++i];
    } else if (arg == '--glob' && i + 1 < args.length) {
      glob = args[++i];
    } else if (arg == '--limit' && i + 1 < args.length) {
      final valueStr = args[++i];
      final value = int.tryParse(valueStr);
      if (value == null || value <= 0) {
        stderr.writeln('Invalid --limit value: ' + valueStr);
        exitCode = 64;
        return;
      }
      limit = value;
    } else if (arg == '--min-delta' && i + 1 < args.length) {
      final valueStr = args[++i];
      final value = double.tryParse(valueStr);
      if (value == null || value < 0) {
        stderr.writeln('Invalid --min-delta value: ' + valueStr);
        exitCode = 64;
        return;
      }
      minDelta = value;
    } else if (arg == '--action' && i + 1 < args.length) {
      final value = args[++i];
      if (value != 'jam' && value != 'fold' && value != 'any') {
        stderr.writeln('Invalid --action value: ' + value);
        exitCode = 64;
        return;
      }
      action = value;
    } else if (arg == '--spr' && i + 1 < args.length) {
      final value = args[++i];
      if (value != 'low' &&
          value != 'mid' &&
          value != 'high' &&
          value != 'any') {
        stderr.writeln('Invalid --spr value: ' + value);
        exitCode = 64;
        return;
      }
      sprBucket = value;
    } else if (arg == '--abs-delta') {
      absDelta = true;
    } else if (arg == '--format' && i + 1 < args.length) {
      format = args[++i];
    } else if (arg == '--fields' && i + 1 < args.length) {
      fields = args[++i]
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (arg == '--texture' && i + 1 < args.length) {
      final value = args[++i];
      textures = value
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (textures!.isEmpty) {
        stderr.writeln('Invalid --texture value: ' + value);
        exitCode = 64;
        return;
      }
    } else if (arg == '--include' && i + 1 < args.length) {
      final value = args[++i];
      final parts = value
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.isEmpty) {
        stderr.writeln('Invalid --include value: ' + value);
        exitCode = 64;
        return;
      }
      includes ??= <String>[];
      includes!.addAll(parts);
    } else if (arg == '--exclude' && i + 1 < args.length) {
      final value = args[++i];
      final parts = value
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.isEmpty) {
        stderr.writeln('Invalid --exclude value: ' + value);
        exitCode = 64;
        return;
      }
      excludes ??= <String>[];
      excludes!.addAll(parts);
    } else if (arg == '--per' && i + 1 < args.length) {
      final value = args[++i];
      if (value != 'none' &&
          value != 'path' &&
          value != 'hand' &&
          value != 'board') {
        stderr.writeln('Invalid --per value: ' + value);
        exitCode = 64;
        return;
      }
      per = value;
    } else if (arg == '--per-limit' && i + 1 < args.length) {
      final valueStr = args[++i];
      final value = int.tryParse(valueStr);
      if (value == null || value <= 0) {
        stderr.writeln('Invalid --per-limit value: ' + valueStr);
        exitCode = 64;
        return;
      }
      perLimit = value;
    } else if (arg == '--unique-by' && i + 1 < args.length) {
      final value = args[++i];
      if (value != 'none' &&
          value != 'path' &&
          value != 'hand' &&
          value != 'board') {
        stderr.writeln('Invalid --unique-by value: ' + value);
        exitCode = 64;
        return;
      }
      uniqueBy = value;
    } else {
      stderr.writeln('Unknown or incomplete argument: $arg');
      exitCode = 64;
      return;
    }
  }

  if (format != 'json' && format != 'jsonl' && format != 'csv') {
    stderr.writeln('Invalid --format value: ' + format);
    exitCode = 64;
    return;
  }

  const allowedFields = [
    'path',
    'spotIndex',
    'hand',
    'board',
    'spr',
    'bestAction',
    'evJam',
    'evFold',
    'delta',
  ];
  if (fields != null) {
    for (final f in fields!) {
      if (!allowedFields.contains(f)) {
        stderr.writeln('Invalid --fields entry: ' + f);
        exitCode = 64;
        return;
      }
    }
  }

  final modes = [inPath, dirPath, glob].whereType<String>();
  if (modes.length != 1) {
    stderr.writeln('Specify exactly one of --in, --dir, or --glob');
    exitCode = 64;
    return;
  }

  final root = Directory.current.path;
  final spots = <Map<String, dynamic>>[];
  final classifier = BoardTextureClassifier();

  Future<void> handle(String path) async {
    final content = await File(path).readAsString();
    final data = jsonDecode(content);
    if (data is! Map<String, dynamic>) return;
    final list = data['spots'];
    if (list is! List) return;
    for (var i = 0; i < list.length; i++) {
      final spot = list[i];
      if (spot is! Map<String, dynamic>) continue;
      final jf = spot['jamFold'];
      if (jf is! Map<String, dynamic>) continue;
      final evJam = (jf['evJam'] as num?)?.toDouble();
      final evFold = (jf['evFold'] as num?)?.toDouble();
      final best = jf['bestAction'];
      final delta = (jf['delta'] as num?)?.toDouble();
      if (evJam == null || evFold == null || best is! String || delta == null) {
        continue;
      }
      var rel = path;
      if (rel.startsWith(root)) {
        rel = rel.substring(root.length);
        if (rel.startsWith(Platform.pathSeparator)) {
          rel = rel.substring(1);
        }
      }
      rel = rel.replaceAll('\\', '/');
      final handField = (() {
        final h = spot['hand'];
        if (h is String) return h;
        if (h is Map) {
          final hc = h['heroCards'] ?? h['handCode'];
          if (hc is String) return hc;
        }
        return null;
      })();
      final board = spot['board'];
      final tags = board is String ? classifier.classify(board) : <String>{};
      spots.add({
        'path': rel,
        'spotIndex': i,
        'hand': handField,
        'board': board,
        'spr': (spot['spr'] as num?)?.toDouble(),
        'bestAction': best,
        'evJam': evJam,
        'evFold': evFold,
        'delta': delta,
        '_tags': tags,
      });
    }
  }

  if (inPath != null) {
    await handle(inPath);
  } else if (dirPath != null) {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      stderr.writeln('Directory not found: $dirPath');
      exitCode = 64;
      return;
    }
    final paths = <String>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.json')) {
        paths.add(entity.path);
      }
    }
    paths.sort();
    for (final p in paths) {
      await handle(p);
    }
  } else if (glob != null) {
    final regex = _globToRegExp(glob!);
    final paths = <String>[];
    await for (final entity in Directory.current.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      var rel = entity.path;
      if (rel.startsWith(root)) {
        rel = rel.substring(root.length);
        if (rel.startsWith(Platform.pathSeparator)) {
          rel = rel.substring(1);
        }
      }
      rel = rel.replaceAll('\\', '/');
      if (regex.hasMatch(rel)) {
        paths.add(entity.path);
      }
    }
    paths.sort();
    for (final p in paths) {
      await handle(p);
    }
  }
  if (includes != null) {
    final regs = includes!.map(_globToRegExp).toList();
    spots.removeWhere((s) {
      final p = s['path'] as String;
      for (final r in regs) {
        if (r.hasMatch(p)) return false;
      }
      return true;
    });
  }
  if (excludes != null) {
    final regs = excludes!.map(_globToRegExp).toList();
    spots.removeWhere((s) {
      final p = s['path'] as String;
      for (final r in regs) {
        if (r.hasMatch(p)) return true;
      }
      return false;
    });
  }

  if (sprBucket != 'any') {
    spots.removeWhere((s) {
      final spr = s['spr'] as double?;
      if (spr == null) return true;
      if (sprBucket == 'low') return !(spr < 1);
      if (sprBucket == 'mid') return !(spr >= 1 && spr < 2);
      return !(spr >= 2);
    });
  }

  if (action != 'any') {
    spots.removeWhere((s) => s['bestAction'] != action);
  }
  if (minDelta != null) {
    spots.removeWhere((s) {
      final d = s['delta'] as double;
      final v = absDelta ? d.abs() : d;
      return v < minDelta!;
    });
  }
  if (textures != null) {
    spots.removeWhere((s) {
      final tags = s['_tags'] as Set<String>?;
      if (tags == null) return true;
      for (final t in textures!) {
        if (tags.contains(t)) return false;
      }
      return true;
    });
  }
  for (final s in spots) {
    s.remove('_tags');
  }

  // Deterministic ordering: primary by (delta | abs(delta)) desc,
  // then by path asc, then by spotIndex asc.
  spots.sort((a, b) {
    final da = a['delta'] as double;
    final db = b['delta'] as double;
    final va = absDelta ? da.abs() : da;
    final vb = absDelta ? db.abs() : db;
    final primary = vb.compareTo(va);
    if (primary != 0) return primary;
    final pa = a['path'] as String;
    final pb = b['path'] as String;
    final sec = pa.compareTo(pb);
    if (sec != 0) return sec;
    final ia = a['spotIndex'] as int;
    final ib = b['spotIndex'] as int;
    return ia.compareTo(ib);
  });

  if (per != 'none') {
    final counts = <Object?, int>{};
    final capped = <Map<String, dynamic>>[];
    for (final spot in spots) {
      Object? key;
      if (per == 'path') {
        key = spot['path'] as Object?;
      } else if (per == 'hand') {
        key = spot['hand'] as Object?;
      } else if (per == 'board') {
        key = spot['board'] as Object?;
      }
      final count = counts[key] ?? 0;
      if (count >= perLimit) continue;
      counts[key] = count + 1;
      capped.add(spot);
    }
    spots
      ..clear()
      ..addAll(capped);
  }

  if (uniqueBy != 'none') {
    final seen = <String>{};
    final deduped = <Map<String, dynamic>>[];
    for (final spot in spots) {
      String? key;
      if (uniqueBy == 'path') {
        key = spot['path'] as String?;
      } else if (uniqueBy == 'hand') {
        key = spot['hand'] as String?;
      } else if (uniqueBy == 'board') {
        key = spot['board'] as String?;
      }
      if (key == null) {
        deduped.add(spot);
        continue;
      }
      if (seen.contains(key)) continue;
      seen.add(key);
      deduped.add(spot);
    }
    spots
      ..clear()
      ..addAll(deduped);
  }

  if (spots.length > limit) {
    spots.length = limit;
  }

  if (format == 'json') {
    print(jsonEncode(spots));
    return;
  }

  final selected = fields ?? allowedFields;
  if (format == 'jsonl') {
    for (final spot in spots) {
      final out = <String, dynamic>{};
      for (final f in selected) {
        out[f] = spot[f];
      }
      print(jsonEncode(out));
    }
    return;
  }

  // csv
  print(selected.join(','));
  for (final spot in spots) {
    final row = selected.map((f) => _csvCell(spot[f])).join(',');
    print(row);
  }
}

RegExp _globToRegExp(String pattern) {
  var escaped = RegExp.escape(pattern);
  escaped = escaped.replaceAll('\\*\\*', '::DOUBLE_STAR::');
  escaped = escaped.replaceAll('\\*', '[^/]*');
  escaped = escaped.replaceAll('::DOUBLE_STAR::', '.*');
  return RegExp('^' + escaped + r'\$');
}

String _csvCell(Object? value) {
  if (value == null) return '';
  var s = value.toString();
  var needsQuote =
      s.contains(',') || s.contains('"') || s.contains('\n') || s.contains(' ');
  if (s.contains('"')) {
    s = s.replaceAll('"', '""');
    needsQuote = true;
  }
  if (needsQuote) {
    return '"' + s + '"';
  }
  return s;
}
