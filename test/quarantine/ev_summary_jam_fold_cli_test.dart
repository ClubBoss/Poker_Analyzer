import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:collection';

import 'package:test/test.dart';
import 'package:poker_analyzer/services/board_texture_classifier.dart';

import '../../bin/ev_summary_jam_fold.dart' as cli;

Future<String> _writeReport(
  Directory dir,
  String name,
  String board,
  double spr,
  String bestAction,
) async {
  final file = File('${dir.path}/$name.json');
  final spot = {
    'board': board,
    'spr': spr,
    'jamFold': {
      'evJam': 1,
      'evFold': 0,
      'bestAction': bestAction,
      'delta': bestAction == 'jam' ? 1 : -1,
    },
  };
  final map = {
    'spots': [spot],
  };
  await file.writeAsString(jsonEncode(map));
  return file.path;
}

Future<String> _capturePrint(Future<void> Function() fn) async {
  final buffer = StringBuffer();
  await runZoned(
    () async {
      await fn();
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        buffer.writeln(line);
      },
    ),
  );
  return buffer.toString();
}

void main() {
  test('directory summary counts', () async {
    final dir = await Directory.systemTemp.createTemp('ev_sum');
    try {
      await _writeReport(dir, 'a', 'AsKsQs', 0.8, 'jam');
      await _writeReport(dir, 'b', 'Ah7d2c', 1.5, 'fold');
      await _writeReport(dir, 'c', '9c8d7s', 2.5, 'jam');

      final output = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path]);
      });
      expect(exitCode, 0);
      final summary = jsonDecode(output.trim()) as Map<String, dynamic>;
      expect(summary['files'], 3);
      expect(summary['spots'], 3);
      expect(summary['withJamFold'], 3);
      expect(summary['jamRate'], closeTo(0.67, 0.01));
      final bySpr = summary['bySPR'] as Map<String, dynamic>;
      expect(bySpr['spr_low'], 1.0);
      expect(bySpr['spr_mid'], 0.0);
      expect(bySpr['spr_high'], 1.0);
      final byTexture = summary['byTexture'] as Map<String, dynamic>;
      expect(byTexture['wet'], 1.0);
      expect(byTexture['dry'], 0.0);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('idempotent output', () async {
    final dir = await Directory.systemTemp.createTemp('ev_sum_idem');
    try {
      await _writeReport(dir, 'a', 'AsKsQs', 0.8, 'jam');
      final out1 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path]);
      });
      final out2 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path]);
      });
      expect(out1, out2);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('deterministic JSON output', () async {
    final dir = await Directory.systemTemp.createTemp('ev_sum_det');
    try {
      await _writeReport(dir, 'a', 'AsKsQs', 0.8, 'jam');
      await _writeReport(dir, 'b', 'Ah7d2c', 1.5, 'fold');
      await _writeReport(dir, 'c', '9c8d7s', 2.5, 'jam');
      final classifier = const BoardTextureClassifier();
      final textureCounts = <String, List<int>>{};
      final spots = [
        {'board': 'AsKsQs', 'spr': 0.8, 'best': 'jam'},
        {'board': 'Ah7d2c', 'spr': 1.5, 'best': 'fold'},
        {'board': '9c8d7s', 'spr': 2.5, 'best': 'jam'},
      ];
      final bySpr = {
        'spr_low': [1, 1],
        'spr_mid': [0, 1],
        'spr_high': [1, 1],
      };
      for (final s in spots) {
        final tags = classifier.classify(s['board'] as String);
        final isJam = s['best'] == 'jam';
        for (final t in tags) {
          final entry = textureCounts.putIfAbsent(t, () => [0, 0]);
          entry[1]++;
          if (isJam) entry[0]++;
        }
      }
      double rate(int jam, int total) =>
          total == 0 ? 0.0 : double.parse((jam / total).toStringAsFixed(2));
      final byTexture = SplayTreeMap<String, double>();
      for (final e in textureCounts.entries) {
        byTexture[e.key] = rate(e.value[0], e.value[1]);
      }
      final expected = {
        'files': 3,
        'spots': 3,
        'withJamFold': 3,
        'jamRate': rate(2, 3),
        'bySPR': {
          for (final e in bySpr.entries) e.key: rate(e.value[0], e.value[1]),
        },
        'byTexture': byTexture,
      };
      final output = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path]);
      });
      expect(output.trim(), jsonEncode(expected));
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
