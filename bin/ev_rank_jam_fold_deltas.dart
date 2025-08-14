import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  String? inPath;
  String? dirPath;
  String? glob;
  var limit = 20;
  var absDelta = false;

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
    } else if (arg == '--abs-delta') {
      absDelta = true;
    } else {
      stderr.writeln('Unknown or incomplete argument: $arg');
      exitCode = 64;
      return;
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
      spots.add({
        'path': rel,
        'spotIndex': i,
        'hand': spot['hand'],
        'board': spot['board'],
        'spr': (spot['spr'] as num?)?.toDouble(),
        'bestAction': best,
        'evJam': evJam,
        'evFold': evFold,
        'delta': delta,
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
    final regex = _globToRegExp(glob);
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

  spots.sort((a, b) {
    final da = a['delta'] as double;
    final db = b['delta'] as double;
    final va = absDelta ? da.abs() : da;
    final vb = absDelta ? db.abs() : db;
    return vb.compareTo(va);
  });

  if (spots.length > limit) {
    spots.length = limit;
  }

  print(jsonEncode(spots));
}

RegExp _globToRegExp(String pattern) {
  var escaped = RegExp.escape(pattern);
  escaped = escaped.replaceAll('\\*\\*', '::DOUBLE_STAR::');
  escaped = escaped.replaceAll('\\*', '[^/]*');
  escaped = escaped.replaceAll('::DOUBLE_STAR::', '.*');
  return RegExp('^' + escaped + r'\$');
}
