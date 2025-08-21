import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

void main() {
  final modules = <String>[
    'core_flop_play',
    'core_turn_river_play',
    'core_blockers_combos',
  ];

  test('content/ exists', () {
    expect(Directory('content').existsSync(), true);
  });

  for (final m in modules) {
    group('content schema for $m', () {
      final v1 = Directory('content/$m/v1');
      final theory = File('content/$m/v1/theory.md');
      final demos = File('content/$m/v1/demos.jsonl');
      final drills = File('content/$m/v1/drills.jsonl');

      test('required files present', () {
        if (!v1.existsSync()) fail('missing folder: ${v1.path}');
        expect(theory.existsSync(), true);
        expect(demos.existsSync(), true);
        expect(drills.existsSync(), true);
      });

      test('demos.jsonl: 2–3 valid JSON lines', () {
        final lines =
            demos.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
        expect(lines.length >= 2 && lines.length <= 3, true);
        for (final l in lines) {
          json.decode(l);
        }
      });

      test('drills.jsonl: 10–20 valid JSON lines with required fields', () {
        final lines =
            drills.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
        expect(lines.length >= 10 && lines.length <= 20, true);
        for (final l in lines) {
          final obj = json.decode(l);
          expect(obj is Map, true);
          expect(obj['id'] is String, true);
          expect(obj['spotKind'] is String, true);
          expect(obj['params'] is Map, true);
          expect(obj['target'] is List, true);
          expect(obj['rationale'] is String, true);
        }
      });
    });
  }
}
