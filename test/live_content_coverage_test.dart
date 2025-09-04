// ASCII-only; pure Dart test for live content coverage.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:poker_analyzer/live/live_ids.dart';
import 'package:poker_analyzer/content/jsonl_validator.dart';
import 'package:poker_analyzer/content/jsonl_loader.dart';

void main() {
  group('Live content coverage', () {
    for (final id in kLiveModuleIds) {
      test('module $id has required files and valid JSONL', () {
        final root = Directory('content/$id/v1');

        // 1. Required files exist
        final theory = File('${root.path}/theory.md');
        final demos = File('${root.path}/demos.jsonl');
        final drills = File('${root.path}/drills.jsonl');

        expect(
          theory.existsSync(),
          isTrue,
          reason: 'missing theory.md for $id under ${root.path}',
        );
        expect(
          demos.existsSync(),
          isTrue,
          reason: 'missing demos.jsonl for $id under ${root.path}',
        );
        expect(
          drills.existsSync(),
          isTrue,
          reason: 'missing drills.jsonl for $id under ${root.path}',
        );

        // 2. Files are ASCII-only
        _expectAsciiOnly(theory);
        _expectAsciiOnly(demos);
        _expectAsciiOnly(drills);

        // 3. validateJsonl(...) passes for JSONL files
        final demosSrc = demos.readAsStringSync();
        final drillsSrc = drills.readAsStringSync();

        final demosReport = validateJsonl(
          demosSrc,
          idField: 'id',
          asciiOnly: true,
        );
        final drillsReport = validateJsonl(
          drillsSrc,
          idField: 'id',
          asciiOnly: true,
        );

        expect(
          demosReport.ok,
          isTrue,
          reason: _formatReportReason('$id demos.jsonl', demosReport),
        );
        expect(
          drillsReport.ok,
          isTrue,
          reason: _formatReportReason('$id drills.jsonl', drillsReport),
        );

        // 4. parseJsonl(...) and assert id prefix consistency
        final demosObjs = parseJsonl(demosSrc, idField: 'id', asciiOnly: true);
        final drillsObjs = parseJsonl(
          drillsSrc,
          idField: 'id',
          asciiOnly: true,
        );

        final allIds = <String>[];
        for (final obj in [...demosObjs, ...drillsObjs]) {
          final objId = obj['id'];
          expect(objId, isA<String>(), reason: 'id must be a string in $id');
          final s = objId as String;
          expect(
            s.startsWith('${id}_'),
            isTrue,
            reason: 'id prefix mismatch: expected to start with "${id}_"',
          );
          allIds.add(s);
        }

        // 5. Global-unique IDs within module (no duplicates across demos/drills)
        final idsSet = allIds.toSet();
        expect(
          idsSet.length,
          allIds.length,
          reason: 'duplicate ids across demos/drills for $id',
        );
      });
    }
  });
}

void _expectAsciiOnly(File file) {
  final bytes = file.readAsBytesSync();
  final allAscii = bytes.every((b) => b <= 0x7F);
  expect(allAscii, isTrue, reason: 'non-ASCII content in ${file.path}');
  // Also validate that decoding as UTF-8 does not introduce replacement chars
  // and remains ASCII-only, which matches text processing paths.
  final text = utf8.decode(bytes, allowMalformed: false);
  final asciiText = text.codeUnits.every((c) => c <= 0x7F);
  expect(asciiText, isTrue, reason: 'non-ASCII code unit in ${file.path}');
}

String _formatReportReason(String label, JsonlReport report) {
  if (report.ok) return '$label is OK';
  final first = report.issues.first;
  return '$label invalid at line ${first.line}: ${first.message}';
}
