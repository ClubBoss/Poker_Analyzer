import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:poker_analyzer/services/board_texture_classifier.dart';

import '../../bin/ev_enrich_jam_fold.dart' as ev_enrich;
import '../../bin/ev_report_jam_fold.dart' as ev_report;
import '../../bin/ev_summary_jam_fold.dart' as ev_summary;

Map<String, dynamic> _spot(String cards, String board, double spr) {
  return {
    'hand': {
      'heroCards': cards,
      'heroIndex': 0,
      'playerCount': 2,
      'stacks': {'0': 10, '1': 10},
      'actions': {
        '0': [
          {'street': 0, 'playerIndex': 0, 'action': 'push', 'amount': 10},
          {'street': 0, 'playerIndex': 1, 'action': 'fold'},
        ],
      },
      'anteBb': 0,
    },
    'board': board,
    'spr': spr,
  };
}

Future<void> _writeReport(
  Directory dir,
  String name,
  Map<String, dynamic> spot,
) async {
  final file = File('${dir.path}${Platform.pathSeparator}$name.json');
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert({'spots': [spot]}),
  );
}

class _RunResult {
  final String out;
  final int code;
  _RunResult(this.out, this.code);
}

Future<_RunResult> _runCapture(Future<void> Function() fn) async {
  final buffer = StringBuffer();
  final prev = exitCode;
  exitCode = 0;
  try {
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
    return _RunResult(buffer.toString().trim(), exitCode);
  } finally {
    exitCode = prev;
  }
}

Future<Map<String, dynamic>> _expectedSummary(Directory dir) async {
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
  const classifier = const BoardTextureClassifier();

  await for (final entity in dir.list(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    files++;
    final content = await entity.readAsString();
    final data = jsonDecode(content);
    if (data is! Map<String, dynamic>) continue;
    final list = data['spots'];
    if (list is! List) continue;
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
        final bucket =
            sprVal < 1 ? 'spr_low' : (sprVal < 2 ? 'spr_mid' : 'spr_high');
        final sprEntry = bySpr[bucket]!;
        sprEntry[1]++; // total
        if (isJam) sprEntry[0]++; // jam
      }

      final board = spot['board'];
      if (board is String) {
        final tags = classifier.classify(board);
        for (final t in tags) {
          final textureEntry = byTextureCounts.putIfAbsent(t, () => [0, 0]);
          textureEntry[1]++; // total
          if (isJam) textureEntry[0]++; // jam
        }
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

  return {
    'files': files,
    'spots': spots,
    'withJamFold': withJamFold,
    'jamRate': rate(jamCount, withJamFold),
    'bySPR': bySprRates,
    'byTexture': byTextureRates,
  };
}

void main() {
  test('jam/fold end-to-end golden', () async {
    final tmp = await Directory.systemTemp.createTemp('ev_golden');
    final corpus = Directory('${tmp.path}${Platform.pathSeparator}corpus');
    await corpus.create();

    try {
      // Единый формат кейсов: список списков (без records)
      final List<List<dynamic>> cases = [
        ['As Ks', 'AhKhQd', 0.5],
        ['7c 2d', '7c5s2h', 0.8],
        ['Qh Jd', 'QcQdQs', 0.9],
        ['9c 9d', 'AsTs2s', 1.2],
        ['2c 3d', '4h5s6d', 1.5],
        ['Kd Qd', 'JcTc9c', 1.9],
        ['5h 5c', '9d9h2c', 2.1],
        ['Ac 2c', 'Ah2h3h', 2.5],
        ['Jh Th', 'Qh9h2d', 3.0],
        ['8s 7s', '8s7d6c', 4.0],
      ];

      for (var i = 0; i < cases.length; i++) {
        final c = cases[i];
        await _writeReport(
          corpus,
          'spot_$i',
          _spot(c[0] as String, c[1] as String, c[2] as double),
        );
      }

      // Flow A: enrichment + идемпотентность
      await ev_enrich.main(['--dir', corpus.path]);

      final snapshots = <String, String>{};
      await for (final entity in corpus.list()) {
        if (entity is! File) continue;
        final content = await entity.readAsString();
        snapshots[entity.path] = content;

        final json = jsonDecode(content) as Map<String, dynamic>;
        final spot = (json['spots'] as List).first as Map<String, dynamic>;
        final jf = spot['jamFold'] as Map<String, dynamic>?;
        expect(jf, isNotNull);
        expect(
          jf!.keys.toSet(),
          containsAll(['evJam', 'evFold', 'bestAction', 'delta']),
        );
        expect(jf['bestAction'], anyOf('jam', 'fold'));
      }

      await ev_enrich.main(['--dir', corpus.path]);
      await for (final entity in corpus.list()) {
        if (entity is! File) continue;
        expect(await entity.readAsString(), snapshots[entity.path]);
      }

      // Flow B: validator (валидный корпус)
      final rValid = await _runCapture(() async {
        await ev_report.main([
          '--dir',
          corpus.path,
          '--validate',
          '--fail-under',
          '0.0',
        ]);
      });
      expect(rValid.code, 0);
      final reportJson = jsonDecode(rValid.out) as Map<String, dynamic>;
      expect(reportJson['changed'], 0);

      // Невалидный одиночный отчёт (без jamFold)
      await _writeReport(tmp, 'missing', _spot('7c 2d', '7c5s2h', 1.0));
      final invalidFile =
          File('${tmp.path}${Platform.pathSeparator}missing.json');
      final rInvalid = await _runCapture(() async {
        await ev_report.main(['--in', invalidFile.path, '--validate']);
      });
      expect(rInvalid.code, 1);

      // Flow C: summary golden
      final rSummary = await _runCapture(() async {
        await ev_summary.main(['--dir', corpus.path]);
      });
      expect(rSummary.code, 0);
      final expected = await _expectedSummary(corpus);
      // Сравниваем строки JSON для строгой детерминированности
      expect(rSummary.out, jsonEncode(expected));
    } finally {
      await tmp.delete(recursive: true);
    }
  });
}
