import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  String? inPath;
  String? dirPath;
  String? glob;
  var validate = false;
  double? failUnder;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--in' && i + 1 < args.length) {
      inPath = args[++i];
    } else if (arg == '--dir' && i + 1 < args.length) {
      dirPath = args[++i];
    } else if (arg == '--glob' && i + 1 < args.length) {
      glob = args[++i];
    } else if (arg == '--validate') {
      validate = true;
    } else if (arg == '--fail-under' && i + 1 < args.length) {
      final valueStr = args[++i];
      final value = double.tryParse(valueStr);
      if (value == null || value < 0 || value > 1) {
        stderr.writeln('Invalid --fail-under value: ' + valueStr);
        exitCode = 64;
        return;
      }
      failUnder = value;
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

  var files = 0;
  var spots = 0;
  var withJamFold = 0;
  var invalid = false;

  Future<void> handle(String path) async {
    files++;
    final content = await File(path).readAsString();
    final data = jsonDecode(content);
    if (data is Map<String, dynamic>) {
      final list = data['spots'];
      if (list is List) {
        spots += list.length;
        for (final spot in list) {
          if (spot is Map<String, dynamic>) {
            final jf = spot['jamFold'];
            if (jf is Map<String, dynamic>) {
              withJamFold++;
              final best = jf['bestAction'];
              if (validate && best != 'jam' && best != 'fold') {
                invalid = true;
              }
            } else {
              if (validate) invalid = true;
            }
          } else {
            if (validate) invalid = true;
          }
        }
      }
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
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.json')) {
        await handle(entity.path);
      }
    }
  } else if (glob != null) {
    final regex = _globToRegExp(glob);
    final root = Directory.current.path;
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
        await handle(entity.path);
      }
    }
  }

  final rate = spots == 0 ? 0.0 : withJamFold / spots;
  final summary = {
    'files': files,
    'spots': spots,
    'withJamFold': withJamFold,
    'jamRate': double.parse(rate.toStringAsFixed(2)),
    'changed': 0,
  };
  print(jsonEncode(summary));
  if ((validate && invalid) || (failUnder != null && rate < failUnder)) {
    exitCode = 1;
  }
}

RegExp _globToRegExp(String pattern) {
  var escaped = RegExp.escape(pattern);
  escaped = escaped.replaceAll('\\*\\*', '::DOUBLE_STAR::');
  escaped = escaped.replaceAll('\\*', '[^/]*');
  escaped = escaped.replaceAll('::DOUBLE_STAR::', '.*');
  return RegExp('^' + escaped + r'\$');
}
