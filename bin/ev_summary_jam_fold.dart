import 'dart:convert';
import 'dart:io';
import 'dart:collection';

import 'package:poker_analyzer/services/board_texture_classifier.dart';

Future<void> main(List<String> args) async {
  String? inPath;
  String? dirPath;
  String? glob;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--in' && i + 1 < args.length) {
      inPath = args[++i];
    } else if (arg == '--dir' && i + 1 < args.length) {
      dirPath = args[++i];
    } else if (arg == '--glob' && i + 1 < args.length) {
      glob = args[++i];
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
  var jamCount = 0;

  final bySpr = {
    'spr_low': [0, 0],
    'spr_mid': [0, 0],
    'spr_high': [0, 0],
  };
  final byTextureCounts = <String, List<int>>{};
  const classifier = BoardTextureClassifier();

  Future<void> handle(String path) async {
    files++;
    final content = await File(path).readAsString();
    final data = jsonDecode(content);
    if (data is! Map<String, dynamic>) return;
    final list = data['spots'];
    if (list is! List) return;
    spots += list.length;
    for (final spot in list) {
      if (spot is! Map<String, dynamic>) continue;
      final jf = spot['jamFold'];
      if (jf is! Map<String, dynamic>) continue;
      withJamFold++;
      final best = jf['bestAction'];
      final isJam = best == 'jam';
      if (isJam) jamCount++;
      final sprVal = (spot['spr'] as num?)?.toDouble();
      if (sprVal != null) {
        final bucket = sprVal < 1
            ? 'spr_low'
            : sprVal < 2
            ? 'spr_mid'
            : 'spr_high';
        final entry = bySpr[bucket]!;
        entry[1]++;
        if (isJam) entry[0]++;
      }
      final board = spot['board'];
      if (board is String) {
        final tags = classifier.classify(board);
        for (final t in tags) {
          final entry = byTextureCounts.putIfAbsent(t, () => [0, 0]);
          entry[1]++;
          if (isJam) entry[0]++;
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

  double rate(int jam, int total) {
    if (total == 0) return 0.0;
    return double.parse((jam / total).toStringAsFixed(2));
  }

  final bySprRates = <String, double>{
    for (final e in bySpr.entries) e.key: rate(e.value[0], e.value[1]),
  };

  final byTextureRates = SplayTreeMap<String, double>();
  for (final e in byTextureCounts.entries) {
    byTextureRates[e.key] = rate(e.value[0], e.value[1]);
  }

  final summary = {
    'files': files,
    'spots': spots,
    'withJamFold': withJamFold,
    'jamRate': rate(jamCount, withJamFold),
    'bySPR': bySprRates,
    'byTexture': byTextureRates,
  };
  print(jsonEncode(summary));
}

RegExp _globToRegExp(String pattern) {
  var escaped = RegExp.escape(pattern);
  escaped = escaped.replaceAll('\\*\\*', '::DOUBLE_STAR::');
  escaped = escaped.replaceAll('\\*', '[^/]*');
  escaped = escaped.replaceAll('::DOUBLE_STAR::', '.*');
  return RegExp('^' + escaped + r'\$');
}
