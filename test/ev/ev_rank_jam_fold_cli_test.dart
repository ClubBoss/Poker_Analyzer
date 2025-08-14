import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../bin/ev_rank_jam_fold_deltas.dart' as cli;

Map<String, dynamic> _mkSpot({
  double delta = 0,
  double spr = 1.0,
  String? board = 'AhKhQd',
  String hand = 'As Ks',
}) {
  final spot = {'hand': hand, 'spr': spr};
  if (board != null) {
    spot['board'] = board;
  }
  spot['jamFold'] = {
    'evJam': delta,
    'evFold': 0,
    'bestAction': delta >= 0 ? 'jam' : 'fold',
    'delta': delta,
  };
  return spot;
}

Future<String> _writeReportMulti(
  Directory dir,
  String name,
  List<Map<String, dynamic>> spots,
) async {
  final file = File('${dir.path}/$name.json');
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert({'spots': spots}),
  );
  return file.path;
}

Future<String> _writeReport(
  Directory dir,
  String name, {
  double delta = 0,
  bool includeJamFold = true,
  double spr = 1.0,
  String? board = 'AhKhQd',
}) async {
  final file = File('${dir.path}/$name.json');
  final spot = {'hand': 'As Ks', 'spr': spr};
  if (board != null) {
    spot['board'] = board;
  }
  if (includeJamFold) {
    spot['jamFold'] = {
      'evJam': delta,
      'evFold': 0,
      'bestAction': delta >= 0 ? 'jam' : 'fold',
      'delta': delta,
    };
  }
  final map = {
    'spots': [spot],
  };
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(map));
  return file.path;
}

Future<Directory> _buildCorpus() async {
  final dir = await Directory.systemTemp.createTemp('ev_rank_cli');
  await _writeReport(dir, 'a', delta: 0.5);
  await _writeReport(dir, 'b', delta: -0.7);
  await _writeReport(dir, 'c', delta: 1.5);
  await _writeReport(dir, 'd', delta: -2.0);
  await _writeReport(dir, 'e', delta: 0.3);
  await _writeReport(dir, 'f', includeJamFold: false);
  return dir;
}

Future<Directory> _buildThresholdCorpus() async {
  final dir = await Directory.systemTemp.createTemp('ev_rank_cli_thresh');
  await _writeReport(dir, 'a', delta: 0.2);
  await _writeReport(dir, 'b', delta: 0.6);
  await _writeReport(dir, 'c', delta: -0.9);
  return dir;
}

Future<Directory> _buildSprCorpus() async {
  final dir = await Directory.systemTemp.createTemp('ev_rank_cli_spr');
  await _writeReport(dir, 'a', delta: 0.3, spr: 0.8);
  await _writeReport(dir, 'b', delta: -0.6, spr: 1.2);
  await _writeReport(dir, 'c', delta: 1.4, spr: 2.5);
  return dir;
}

Future<Directory> _buildTextureCorpus() async {
  final dir = await Directory.systemTemp.createTemp('ev_rank_cli_texture');
  await _writeReport(dir, 'wet1', delta: 0.5, board: 'AsKsQs');
  await _writeReport(dir, 'dry1', delta: 0.4, board: 'Ah7d2c');
  await _writeReport(dir, 'wet2', delta: -0.3, board: '9c8d7s');
  return dir;
}

Future<Directory> _buildCompositionCorpus() async {
  final dir = await Directory.systemTemp.createTemp('ev_rank_cli_comp');
  await _writeReport(dir, 'a', delta: 0.6, board: 'AsKsQs', spr: 1.5);
  await _writeReport(dir, 'b', delta: 0.7, board: 'Ah7d2c', spr: 1.5);
  await _writeReport(dir, 'c', delta: 0.8, board: '9c8d7s', spr: 2.5);
  return dir;
}

Future<Directory> _buildPathFilterCorpus() async {
  final dir = await Directory('${Directory.current.path}/pf_corpus_'
          '${DateTime.now().microsecondsSinceEpoch}')
      .create();
  await _writeReport(dir, 'a', delta: 0.6, spr: 1.5);
  await _writeReport(dir, 'b', delta: -0.7, spr: 1.5);
  final sub = Directory('${dir.path}/sub');
  await sub.create();
  await _writeReport(sub, 'c', delta: 0.9, spr: 1.5);
  return dir;
}

Future<Directory> _buildPathDedupCorpus() async {
  final dir = await Directory.systemTemp.createTemp('ev_rank_cli_path');
  final file = File('${dir.path}/multi.json');
  final spot1 = {
    'hand': 'As Ks',
    'board': 'AhKhQd',
    'spr': 1.0,
    'jamFold': {'evJam': 0.5, 'evFold': 0, 'bestAction': 'jam', 'delta': 0.5},
  };
  final spot2 = {
    'hand': 'Qs Js',
    'board': 'AhKhQd',
    'spr': 1.0,
    'jamFold': {'evJam': 0.7, 'evFold': 0, 'bestAction': 'jam', 'delta': 0.7},
  };
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'spots': [spot1, spot2],
    }),
  );
  await _writeReport(dir, 'b', delta: 0.6);
  return dir;
}

Future<Directory> _buildBoardDedupCorpus() async {
  final dir = await Directory.systemTemp.createTemp('ev_rank_cli_board');
  await _writeReport(dir, 'a', delta: 0.5, board: 'AhKhQd');
  await _writeReport(dir, 'b', delta: 0.7, board: 'AhKhQd');
  return dir;
}

Future<Directory> _buildHandDedupCorpus() async {
  final dir = await Directory.systemTemp.createTemp('ev_rank_cli_hand');
  await _writeReport(dir, 'a', delta: 0.4, board: 'AhKhQd');
  await _writeReport(dir, 'b', delta: 0.9, board: 'QcJhTs');
  return dir;
}

Future<Directory> _buildNullBoardCorpus() async {
  final dir = await Directory.systemTemp.createTemp('ev_rank_cli_null');
  await _writeReport(dir, 'a', delta: 0.5, board: null);
  await _writeReport(dir, 'b', delta: 0.7, board: null);
  return dir;
}

Future<Directory> _buildFilterFormatCorpus() async {
  final dir = await Directory.systemTemp.createTemp('ev_rank_cli_ff');
  await _writeReport(dir, 'a', delta: 1.2, board: 'AhKhQd', spr: 2.5);
  await _writeReport(dir, 'b', delta: -1.1, board: 'AhKhQd', spr: 2.5);
  await _writeReport(dir, 'c', delta: 0.9, board: 'QcJhTs', spr: 2.5);
  return dir;
}

Future<Directory> _buildPerPathCapCorpus() async {
  final dir = await Directory.systemTemp.createTemp('ev_rank_cli_per_path');
  await _writeReportMulti(dir, 'multi', [
    _mkSpot(delta: 1.0),
    _mkSpot(delta: 0.9),
    _mkSpot(delta: 0.8),
    _mkSpot(delta: 0.7),
  ]);
  await _writeReport(dir, 'single', delta: 0.5);
  return dir;
}

Future<Directory> _buildPerHandCapCorpus() async {
  final dir = await Directory.systemTemp.createTemp('ev_rank_cli_per_hand');
  await _writeReportMulti(dir, 'a', [
    _mkSpot(hand: 'As Ks', delta: 0.5),
    _mkSpot(hand: 'Qc Jc', delta: -0.6),
  ]);
  await _writeReportMulti(dir, 'b', [
    _mkSpot(hand: 'As Ks', delta: -0.8),
    _mkSpot(hand: 'Qc Jc', delta: 0.7),
  ]);
  return dir;
}

Future<Directory> _buildPerBoardCapCorpus() async {
  final dir = await Directory.systemTemp.createTemp('ev_rank_cli_per_board');
  await _writeReport(dir, 'a', delta: 0.6, board: null);
  await _writeReport(dir, 'b', delta: 0.4, board: null);
  await _writeReport(dir, 'c', delta: 0.7, board: 'AhKhQd');
  return dir;
}

Future<Directory> _buildPerUniqueCorpus() async {
  final dir = await Directory.systemTemp.createTemp('ev_rank_cli_per_unique');
  await _writeReportMulti(dir, 'multi', [
    _mkSpot(delta: 1.0, board: 'AhKhQd'),
    _mkSpot(delta: 0.9, board: 'AsAdKd'),
    _mkSpot(delta: 0.8, board: 'AsAdKd'),
    _mkSpot(delta: 0.7, board: 'QcJhTs'),
  ]);
  await _writeReportMulti(dir, 'single', [
    _mkSpot(delta: 0.6, board: 'AsAdKd'),
    _mkSpot(delta: 0.5, board: '9c8d7s'),
  ]);
  return dir;
}

Future<Directory> _buildPerFilterFormatCapCorpus() async {
  final dir = await Directory.systemTemp.createTemp('ev_rank_cli_per_ff');
  await _writeReportMulti(dir, 'a', [
    _mkSpot(delta: -0.6, board: 'AsKsQs', spr: 2.5),
    _mkSpot(delta: -0.7, board: 'AsKsQs', spr: 2.5),
  ]);
  await _writeReportMulti(dir, 'b', [
    _mkSpot(delta: -0.8, board: '9c8d7s', spr: 2.5),
  ]);
  return dir;
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
  test('include only path filter', () async {
    final dir = await _buildPathFilterCorpus();
    try {
      final prev = Directory.current;
      Directory.current = dir;
      final run1 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', '.', '--include', 'sub/**']);
      });
      final run2 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', '.', '--include', 'sub/**']);
      });
      expect(run1, run2);
      expect(exitCode, 0);
      final list = jsonDecode(run1.trim()) as List;
      expect(list.length, 1);
      final first = list.first as Map<String, dynamic>;
      expect(first['path'], 'sub/c.json');
      Directory.current = prev;
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('exclude only path filter', () async {
    final dir = await _buildPathFilterCorpus();
    try {
      final prev = Directory.current;
      Directory.current = dir;
      final out = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', '.', '--exclude', '**/b.json']);
      });
      expect(exitCode, 0);
      final list = jsonDecode(out.trim()) as List;
      for (final spot in list) {
        final p = (spot as Map<String, dynamic>)['path'] as String;
        expect(p.endsWith('b.json'), false);
      }
      Directory.current = prev;
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('include and exclude combo', () async {
    final dir = await _buildPathFilterCorpus();
    try {
      final prev = Directory.current;
      Directory.current = dir;
      final out = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          '.',
          '--include',
          '**/*.json',
          '--exclude',
          '**/a.json,sub/**',
        ]);
      });
      expect(exitCode, 0);
      final list = jsonDecode(out.trim()) as List;
      expect(list.length, 1);
      final first = list.first as Map<String, dynamic>;
      expect(first['path'], 'b.json');
      expect(
        first.keys.toSet().containsAll([
          'path',
          'spotIndex',
          'hand',
          'board',
          'spr',
          'bestAction',
          'evJam',
          'evFold',
          'delta',
        ]),
        true,
      );
      Directory.current = prev;
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('multiple include flags merged', () async {
    final dir = await _buildPathFilterCorpus();
    try {
      final prev = Directory.current;
      Directory.current = dir;
      final out = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          '.',
          '--include',
          'sub/**',
          '--include',
          '**/a.json',
        ]);
      });
      expect(exitCode, 0);
      final list = jsonDecode(out.trim()) as List;
      final paths = list
          .map((e) => (e as Map<String, dynamic>)['path'] as String)
          .toSet();
      expect(paths.length, 2);
      expect(paths.contains('a.json'), true);
      expect(paths.contains('sub/c.json'), true);
      Directory.current = prev;
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('invalid include/exclude args', () async {
    final dir = await _buildPathFilterCorpus();
    try {
      final prev = Directory.current;
      Directory.current = dir;
      await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', '.', '--include', '']);
      });
      expect(exitCode, 64);

      await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', '.', '--exclude', ' ,  ']);
      });
      expect(exitCode, 64);
      Directory.current = prev;
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('path filters with other filters determinism', () async {
    final dir = await _buildPathFilterCorpus();
    try {
      final prev = Directory.current;
      Directory.current = dir;
      final run1 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          '.',
          '--include',
          '**/*.json',
          '--exclude',
          '**/b.json',
          '--spr',
          'mid',
          '--action',
          'jam',
          '--abs-delta',
          '--min-delta',
          '0.5',
        ]);
      });
      final run2 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          '.',
          '--include',
          '**/*.json',
          '--exclude',
          '**/b.json',
          '--spr',
          'mid',
          '--action',
          'jam',
          '--abs-delta',
          '--min-delta',
          '0.5',
        ]);
      });
      expect(run1, run2);
      expect(exitCode, 0);
      Directory.current = prev;
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('ranking by delta honors limit', () async {
    final dir = await _buildCorpus();
    try {
      final output = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--limit', '2']);
      });
      expect(exitCode, 0);
      final list = jsonDecode(output.trim()) as List;
      expect(list.length, 2);
      final first = list.first as Map<String, dynamic>;
      expect((first['delta'] as num).toDouble(), 1.5);
      expect((first['path'] as String).endsWith('c.json'), true);
      expect(first['hand'], isNotNull);
      expect(first['board'], isNotNull);
      expect(first['spr'], isNotNull);
      expect(first['bestAction'], 'jam');
      expect(first['evJam'], 1.5);
      expect(first['evFold'], 0);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('ranking by absolute delta', () async {
    final dir = await _buildCorpus();
    try {
      final output = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--limit', '1', '--abs-delta']);
      });
      expect(exitCode, 0);
      final list = jsonDecode(output.trim()) as List;
      final first = list.first as Map<String, dynamic>;
      expect((first['delta'] as num).toDouble(), -2.0);
      expect((first['path'] as String).endsWith('d.json'), true);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('deterministic output', () async {
    final dir = await _buildCorpus();
    try {
      final run1 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path]);
      });
      final run2 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path]);
      });
      expect(run1, run2);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('skips files without jamFold', () async {
    final dir = await _buildCorpus();
    try {
      final output = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--limit', '20']);
      });
      expect(exitCode, 0);
      final list = jsonDecode(output.trim()) as List;
      expect(list.length, 5);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('min-delta filter uses raw delta', () async {
    final dir = await _buildThresholdCorpus();
    try {
      final output = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--min-delta', '0.5']);
      });
      expect(exitCode, 0);
      final list = jsonDecode(output.trim()) as List;
      expect(list.length, 1);
      final first = list.first as Map<String, dynamic>;
      expect((first['delta'] as num).toDouble(), 0.6);
      expect((first['path'] as String).endsWith('b.json'), true);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('min-delta filter respects abs-delta', () async {
    final dir = await _buildThresholdCorpus();
    try {
      final output = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--abs-delta',
          '--min-delta',
          '0.7',
        ]);
      });
      expect(exitCode, 0);
      final list = jsonDecode(output.trim()) as List;
      expect(list.length, 1);
      final first = list.first as Map<String, dynamic>;
      expect((first['delta'] as num).toDouble(), -0.9);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('action filter', () async {
    final dir = await _buildCorpus();
    try {
      final jamOut = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--action', 'jam']);
      });
      expect(exitCode, 0);
      final jamList = jsonDecode(jamOut.trim()) as List;
      for (final spot in jamList) {
        expect((spot as Map<String, dynamic>)['bestAction'], 'jam');
      }

      final foldOut = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--action', 'fold']);
      });
      expect(exitCode, 0);
      final foldList = jsonDecode(foldOut.trim()) as List;
      for (final spot in foldList) {
        expect((spot as Map<String, dynamic>)['bestAction'], 'fold');
      }
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('spr=low filter', () async {
    final dir = await _buildSprCorpus();
    try {
      final run1 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--spr', 'low']);
      });
      expect(exitCode, 0);
      final list = jsonDecode(run1.trim()) as List;
      expect(list.length, 1);
      final spot = list.first as Map<String, dynamic>;
      expect((spot['spr'] as num).toDouble(), 0.8);
      expect((spot['path'] as String).endsWith('a.json'), true);
      final run2 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--spr', 'low']);
      });
      expect(run1, run2);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('spr mid & high filters', () async {
    final dir = await _buildSprCorpus();
    try {
      final midOut = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--spr', 'mid']);
      });
      expect(exitCode, 0);
      final midList = jsonDecode(midOut.trim()) as List;
      expect(midList.length, 1);
      expect((midList.first as Map<String, dynamic>)['spr'], 1.2);

      final highOut = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--spr', 'high']);
      });
      expect(exitCode, 0);
      final highList = jsonDecode(highOut.trim()) as List;
      expect(highList.length, 1);
      expect((highList.first as Map<String, dynamic>)['spr'], 2.5);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('spr any behaves like no filter', () async {
    final dir = await _buildSprCorpus();
    try {
      final base = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path]);
      });
      expect(exitCode, 0);
      final anyOut = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--spr', 'any']);
      });
      expect(exitCode, 0);
      expect(anyOut, base);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('spr invalid arg', () async {
    final dir = await _buildSprCorpus();
    try {
      await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--spr', 'nope']);
      });
      expect(exitCode, 64);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('spr with other filters and formats', () async {
    final dir = await _buildSprCorpus();
    try {
      final out = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--spr',
          'mid',
          '--action',
          'fold',
          '--abs-delta',
          '--min-delta',
          '0.5',
          '--format',
          'jsonl',
        ]);
      });
      expect(exitCode, 0);
      final lines = out.trim().split('\\n');
      for (final line in lines) {
        final map = jsonDecode(line) as Map<String, dynamic>;
        final spr = (map['spr'] as num).toDouble();
        expect(spr >= 1 && spr < 2, true);
        expect(map['bestAction'], 'fold');
        final d = (map['delta'] as num).toDouble();
        expect(d.abs() >= 0.5, true);
      }
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('invalid args', () async {
    final dir = await _buildCorpus();
    try {
      await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--min-delta', 'nope']);
      });
      expect(exitCode, 64);

      await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--action', 'lol']);
      });
      expect(exitCode, 64);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('determinism with filters', () async {
    final dir = await _buildCorpus();
    try {
      final run1 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--action',
          'jam',
          '--min-delta',
          '0.4',
        ]);
      });
      final run2 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--action',
          'jam',
          '--min-delta',
          '0.4',
        ]);
      });
      expect(run1, run2);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('jsonl basics', () async {
    final dir = await _buildCorpus();
    try {
      final output = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--format',
          'jsonl',
          '--limit',
          '2',
        ]);
      });
      expect(exitCode, 0);
      final lines = output.trim().split('\n');
      expect(lines.length, 2);
      final first = jsonDecode(lines.first) as Map<String, dynamic>;
      expect((first['delta'] as num).toDouble(), 1.5);
      final run2 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--format',
          'jsonl',
          '--limit',
          '2',
        ]);
      });
      expect(output, run2);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('csv basics', () async {
    final dir = await _buildCorpus();
    try {
      final output = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--format', 'csv', '--limit', '3']);
      });
      expect(exitCode, 0);
      final lines = output.trim().split('\n');
      expect(lines.length, 4);
      expect(
        lines.first,
        'path,spotIndex,hand,board,spr,bestAction,evJam,evFold,delta',
      );
      final row = lines[1].split(',');
      expect(row[0].endsWith('c.json'), true);
      expect(row[1], '0');
      expect(row[2], '"As Ks"');
      expect(row.last, '1.5');
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('fields subset', () async {
    final dir = await _buildCorpus();
    try {
      final csvOut = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--format',
          'csv',
          '--fields',
          'path,delta',
        ]);
      });
      expect(exitCode, 0);
      final csvLines = csvOut.trim().split('\n');
      expect(csvLines.first, 'path,delta');
      expect(csvLines[1].split(',').length, 2);

      final jsonlOut = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--format',
          'jsonl',
          '--fields',
          'path,delta',
        ]);
      });
      expect(exitCode, 0);
      final jsonlLines = jsonlOut.trim().split('\n');
      final map = jsonDecode(jsonlLines.first) as Map<String, dynamic>;
      expect(map.keys.toList(), ['path', 'delta']);
      expect(map.length, 2);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('invalid new args', () async {
    final dir = await _buildCorpus();
    try {
      await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--format', 'yaml']);
      });
      expect(exitCode, 64);

      await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--fields', 'path,delta,wat']);
      });
      expect(exitCode, 64);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('filters with formats', () async {
    final dir = await _buildCorpus();
    try {
      final out = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--abs-delta',
          '--min-delta',
          '1.0',
          '--action',
          'fold',
          '--format',
          'jsonl',
        ]);
      });
      expect(exitCode, 0);
      final lines = out.trim().split('\n');
      for (final line in lines) {
        final map = jsonDecode(line) as Map<String, dynamic>;
        expect(map['bestAction'], 'fold');
        final d = (map['delta'] as num).toDouble();
        expect(d.abs() >= 1.0, true);
      }
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('determinism with csv fields', () async {
    final dir = await _buildCorpus();
    try {
      final run1 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--format',
          'csv',
          '--fields',
          'path,spotIndex,delta',
        ]);
      });
      final run2 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--format',
          'csv',
          '--fields',
          'path,spotIndex,delta',
        ]);
      });
      expect(run1, run2);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('texture=wet', () async {
    final dir = await _buildTextureCorpus();
    try {
      final run1 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--texture', 'wet']);
      });
      expect(exitCode, 0);
      final run2 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--texture', 'wet']);
      });
      expect(exitCode, 0);
      expect(run1, run2);
      final list = jsonDecode(run1.trim()) as List;
      final boards =
          list.map((e) => (e as Map<String, dynamic>)['board']).toSet();
      expect(boards, {'AsKsQs', '9c8d7s'});
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('texture=dry', () async {
    final dir = await _buildTextureCorpus();
    try {
      final output = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--texture', 'dry']);
      });
      expect(exitCode, 0);
      final list = jsonDecode(output.trim()) as List;
      expect(list.length, 1);
      final first = list.first as Map<String, dynamic>;
      expect(first['board'], 'Ah7d2c');
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('texture union wet,paired', () async {
    final dir = await _buildTextureCorpus();
    try {
      final wetOut = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--texture', 'wet']);
      });
      expect(exitCode, 0);
      final unionOut = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--texture', 'wet,paired']);
      });
      expect(exitCode, 0);
      final wetList = jsonDecode(wetOut.trim()) as List;
      final unionList = jsonDecode(unionOut.trim()) as List;
      expect(unionList.length, wetList.length);
      for (final e in wetList) {
        expect(unionList.contains(e), true);
      }
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('empty texture value invalid', () async {
    final dir = await _buildTextureCorpus();
    try {
      await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--texture', '']);
      });
      expect(exitCode, 64);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('texture with other filters and formats', () async {
    final dir = await _buildCompositionCorpus();
    try {
      final out = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--texture',
          'wet',
          '--spr',
          'mid',
          '--action',
          'jam',
          '--abs-delta',
          '--min-delta',
          '0.5',
          '--format',
          'jsonl',
        ]);
      });
      expect(exitCode, 0);
      final lines = out.trim().split('\n');
      for (final line in lines) {
        final map = jsonDecode(line) as Map<String, dynamic>;
        expect(map['board'], 'AsKsQs');
        expect(map['bestAction'], 'jam');
        final d = (map['delta'] as num).toDouble();
        expect(d.abs() >= 0.5, true);
        final spr = (map['spr'] as num).toDouble();
        expect(spr >= 1 && spr < 2, true);
      }
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('unique-by path', () async {
    final dir = await _buildPathDedupCorpus();
    try {
      final noDedup = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path]);
      });
      expect(exitCode, 0);
      final list = jsonDecode(noDedup.trim()) as List;
      expect(list.length, 3);

      final out = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--unique-by', 'path']);
      });
      expect(exitCode, 0);
      final list2 = jsonDecode(out.trim()) as List;
      expect(list2.length, 2);
      final first = list2.first as Map<String, dynamic>;
      expect((first['delta'] as num).toDouble(), 0.7);
      expect((first['path'] as String).endsWith('multi.json'), true);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('unique-by board', () async {
    final dir = await _buildBoardDedupCorpus();
    try {
      final run1 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--unique-by', 'board']);
      });
      expect(exitCode, 0);
      final run2 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--unique-by', 'board']);
      });
      expect(run1, run2);
      final list = jsonDecode(run1.trim()) as List;
      expect(list.length, 1);
      final first = list.first as Map<String, dynamic>;
      expect((first['delta'] as num).toDouble(), 0.7);
      expect((first['path'] as String).endsWith('b.json'), true);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('unique-by hand', () async {
    final dir = await _buildHandDedupCorpus();
    try {
      final out = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--unique-by', 'hand']);
      });
      expect(exitCode, 0);
      final list = jsonDecode(out.trim()) as List;
      expect(list.length, 1);
      final first = list.first as Map<String, dynamic>;
      expect((first['delta'] as num).toDouble(), 0.9);
      expect((first['path'] as String).endsWith('b.json'), true);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('null keys are unique for board', () async {
    final dir = await _buildNullBoardCorpus();
    try {
      final out = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--unique-by', 'board']);
      });
      expect(exitCode, 0);
      final list = jsonDecode(out.trim()) as List;
      expect(list.length, 2);
      for (final spot in list) {
        expect((spot as Map<String, dynamic>)['board'], isNull);
      }
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('invalid unique-by arg', () async {
    final dir = await _buildCorpus();
    try {
      await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--unique-by', 'wat']);
      });
      expect(exitCode, 64);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('unique-by with filters and formats', () async {
    final dir = await _buildFilterFormatCorpus();
    try {
      final run1 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--spr',
          'high',
          '--abs-delta',
          '--min-delta',
          '1.0',
          '--unique-by',
          'board',
          '--format',
          'jsonl',
        ]);
      });
      expect(exitCode, 0);
      final run2 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--spr',
          'high',
          '--abs-delta',
          '--min-delta',
          '1.0',
          '--unique-by',
          'board',
          '--format',
          'jsonl',
        ]);
      });
      expect(run1, run2);
      final lines = run1.trim().split('\n');
      for (final line in lines) {
        final map = jsonDecode(line) as Map<String, dynamic>;
        final spr = (map['spr'] as num).toDouble();
        expect(spr >= 2, true);
        final d = (map['delta'] as num).toDouble();
        expect(d.abs() >= 1.0, true);
        expect(map['board'], 'AhKhQd');
      }
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('per=path limit=2', () async {
    final dir = await _buildPerPathCapCorpus();
    try {
      final run1 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--per',
          'path',
          '--per-limit',
          '2',
        ]);
      });
      expect(exitCode, 0);
      final run2 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--per',
          'path',
          '--per-limit',
          '2',
        ]);
      });
      expect(run1, run2);
      final list = jsonDecode(run1.trim()) as List;
      expect(list.length, 3);
      final first = list[0] as Map<String, dynamic>;
      final second = list[1] as Map<String, dynamic>;
      final third = list[2] as Map<String, dynamic>;
      expect((first['path'] as String).endsWith('multi.json'), true);
      expect((second['path'] as String).endsWith('multi.json'), true);
      expect((third['path'] as String).endsWith('single.json'), true);
      expect((first['delta'] as num).toDouble(), 1.0);
      expect((second['delta'] as num).toDouble(), 0.9);
      expect((third['delta'] as num).toDouble(), 0.5);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('per=hand abs-delta', () async {
    final dir = await _buildPerHandCapCorpus();
    try {
      final out = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--abs-delta',
          '--per',
          'hand',
          '--per-limit',
          '1',
        ]);
      });
      expect(exitCode, 0);
      final list = jsonDecode(out.trim()) as List;
      expect(list.length, 2);
      final hands =
          list.map((e) => (e as Map<String, dynamic>)['hand']).toSet();
      expect(hands.length, 2);
      final deltas =
          list.map((e) => (e as Map<String, dynamic>)['delta']).toList();
      expect(deltas.contains(-0.8), true);
      expect(deltas.contains(0.7), true);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('per=board with nulls', () async {
    final dir = await _buildPerBoardCapCorpus();
    try {
      final out = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--per',
          'board',
          '--per-limit',
          '1',
        ]);
      });
      expect(exitCode, 0);
      final list = jsonDecode(out.trim()) as List;
      int nullCount = 0;
      for (final spot in list) {
        final map = spot as Map<String, dynamic>;
        if (map['board'] == null) {
          nullCount++;
          expect((map['delta'] as num).toDouble(), 0.6);
        }
      }
      expect(nullCount, 1);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('per with unique-by', () async {
    final dir = await _buildPerUniqueCorpus();
    try {
      final run1 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--per',
          'path',
          '--per-limit',
          '2',
          '--unique-by',
          'board',
        ]);
      });
      expect(exitCode, 0);
      final run2 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--per',
          'path',
          '--per-limit',
          '2',
          '--unique-by',
          'board',
        ]);
      });
      expect(run1, run2);
      final list = jsonDecode(run1.trim()) as List;
      final paths = <String, int>{};
      final boards = <String?>{};
      for (final spot in list) {
        final map = spot as Map<String, dynamic>;
        final p = map['path'] as String;
        paths[p] = (paths[p] ?? 0) + 1;
        expect(boards.add(map['board'] as String?), true);
      }
      for (final count in paths.values) {
        expect(count <= 2, true);
      }
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('invalid per args', () async {
    final dir = await _buildCorpus();
    try {
      await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--per', 'wat']);
      });
      expect(exitCode, 64);

      await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--per',
          'path',
          '--per-limit',
          '0',
        ]);
      });
      expect(exitCode, 64);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('per with filters and formats', () async {
    final dir = await _buildPerFilterFormatCapCorpus();
    try {
      final run1 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--texture',
          'wet',
          '--spr',
          'high',
          '--action',
          'fold',
          '--abs-delta',
          '--min-delta',
          '0.5',
          '--per',
          'path',
          '--per-limit',
          '1',
          '--format',
          'jsonl',
        ]);
      });
      expect(exitCode, 0);
      final run2 = await _capturePrint(() async {
        exitCode = 0;
        await cli.main([
          '--dir',
          dir.path,
          '--texture',
          'wet',
          '--spr',
          'high',
          '--action',
          'fold',
          '--abs-delta',
          '--min-delta',
          '0.5',
          '--per',
          'path',
          '--per-limit',
          '1',
          '--format',
          'jsonl',
        ]);
      });
      expect(run1, run2);
      final lines = run1.trim().split('\n');
      expect(lines.length, 2);
      for (final line in lines) {
        final map = jsonDecode(line) as Map<String, dynamic>;
        expect(map['bestAction'], 'fold');
        final spr = (map['spr'] as num).toDouble();
        expect(spr >= 2, true);
        final d = (map['delta'] as num).toDouble();
        expect(d.abs() >= 0.5, true);
        final path = map['path'] as String;
        expect(path.endsWith('a.json') || path.endsWith('b.json'), true);
      }
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
