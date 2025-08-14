import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../bin/ev_rank_jam_fold_deltas.dart' as cli;

Future<String> _writeReport(
  Directory dir,
  String name, {
  double delta = 0,
  bool includeJamFold = true,
  double spr = 1.0,
}) async {
  final file = File('${dir.path}/$name.json');
  final spot = {'hand': 'As Ks', 'board': 'AhKhQd', 'spr': spr};
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
}
