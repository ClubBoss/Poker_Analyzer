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
}) async {
  final file = File('${dir.path}/$name.json');
  final spot = {'hand': 'As Ks', 'board': 'AhKhQd', 'spr': 1.0};
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
}
