import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../bin/ev_enrich_jam_fold.dart' as cli;

Map<String, dynamic> spotForHand(String cards) {
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
  };
}

Future<String> _writeReport(Directory dir, String name, String hand) async {
  final file = File('${dir.path}/$name.json');
  final map = {
    'spots': [spotForHand(hand)],
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
  test('batch directory idempotence', () async {
    final dir = await Directory.systemTemp.createTemp('ev_batch');
    try {
      await _writeReport(dir, 'a', 'As Ks');
      await _writeReport(dir, 'b', '7c 2d');
      await _writeReport(dir, 'c', 'Qh Jd');

      await cli.main(['--dir', dir.path]);
      final first = <String, String>{};
      await for (final e in dir.list()) {
        if (e is File) {
          first[e.path] = await e.readAsString();
        }
      }
      await cli.main(['--dir', dir.path]);
      await for (final e in dir.list()) {
        if (e is File) {
          expect(await e.readAsString(), first[e.path]);
        }
      }
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('backward compat deep compare', () async {
    final dir = await Directory.systemTemp.createTemp('ev_single');
    try {
      final path = await _writeReport(dir, 'one', 'As Ks');
      final original = jsonDecode(await File(path).readAsString());
      await cli.main(['--in', path]);
      final merged = jsonDecode(await File(path).readAsString());
      final spot = (merged['spots'] as List).first as Map<String, dynamic>;
      expect(spot['jamFold'], isNotNull);
      spot.remove('jamFold');
      expect(merged, original);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('dry-run summary', () async {
    final dir = await Directory.systemTemp.createTemp('ev_dry');
    try {
      await _writeReport(dir, 'a', 'As Ks');
      await _writeReport(dir, 'b', '7c 2d');
      await _writeReport(dir, 'c', 'Qh Jd');

      final output = await _capturePrint(() async {
        await cli.main(['--dir', dir.path, '--dry-run']);
      });
      expect(output, contains('Scanned 3 files: 3 changed, 0 skipped'));
      await for (final e in dir.list()) {
        if (e is File) {
          final json = jsonDecode(await e.readAsString());
          final spot = (json['spots'] as List).first as Map<String, dynamic>;
          expect(spot['jamFold'], isNull);
        }
      }
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
