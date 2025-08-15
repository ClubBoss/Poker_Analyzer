import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../bin/ev_report_jam_fold.dart' as cli;

Future<String> _writeReport(
  Directory dir,
  String name, {
  bool includeJamFold = true,
}) async {
  final file = File('${dir.path}/$name.json');
  final spot = <String, dynamic>{};
  if (includeJamFold) {
    spot['jamFold'] = {
      'evJam': 1,
      'evFold': 0,
      'bestAction': 'jam',
      'delta': 1,
    };
  }
  final map = {
    'spots': [spot],
  };
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(map));
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
    final dir = await Directory.systemTemp.createTemp('ev_summary');
    try {
      await _writeReport(dir, 'a');
      await _writeReport(dir, 'b');
      await _writeReport(dir, 'c');

      final output = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path]);
      });
      expect(exitCode, 0);
      final summary = jsonDecode(output.trim()) as Map<String, dynamic>;
      expect(summary['files'], 3);
      expect(summary['spots'], 3);
      expect(summary['withJamFold'], 3);
      expect(summary['jamRate'], 1.0);
      expect(summary['changed'], 0);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('validate missing jamFold exits 1', () async {
    final dir = await Directory.systemTemp.createTemp('ev_validate');
    try {
      final path = await _writeReport(dir, 'one', includeJamFold: false);
      await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--in', path, '--validate']);
      });
      expect(exitCode, 1);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('fail-under passes at threshold', () async {
    final dir = await Directory.systemTemp.createTemp('ev_fail_under_ok');
    try {
      final path = await _writeReport(dir, 'one');
      final output = await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--in', path, '--fail-under', '1.0']);
      });
      expect(exitCode, 0);
      final summary = jsonDecode(output.trim()) as Map<String, dynamic>;
      expect(summary['jamRate'], 1.0);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('fail-under exits 1 when jam rate too low', () async {
    final dir = await Directory.systemTemp.createTemp('ev_fail_under_bad');
    try {
      await _writeReport(dir, 'a');
      await _writeReport(dir, 'b');
      await _writeReport(dir, 'c', includeJamFold: false);
      await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path, '--fail-under', '0.9']);
      });
      expect(exitCode, 1);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('invalid fail-under exits 64', () async {
    await _capturePrint(() async {
      exitCode = 0;
      await cli.main(['--dir', '.', '--fail-under', 'nope']);
    });
    expect(exitCode, 64);
  });

  test('idempotent no writes', () async {
    final dir = await Directory.systemTemp.createTemp('ev_idem');
    try {
      final path = await _writeReport(dir, 'one');
      final before = await File(path).readAsString();
      await _capturePrint(() async {
        exitCode = 0;
        await cli.main(['--dir', dir.path]);
      });
      expect(exitCode, 0);
      final after = await File(path).readAsString();
      expect(after, before);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
