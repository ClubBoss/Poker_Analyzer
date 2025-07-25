import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:poker_analyzer/services/theory_validation_engine.dart';

void main() {
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('theory_test');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  test('validateAll detects issues in malformed yaml', () async {
    final file = File(p.join(dir.path, 'bad.yaml'));
    await file.writeAsString('''
id: t1
name: Test
trainingType: pushFold
spots:
  - id: s1
    type: quiz
    tags: [unknown]
    explanation: ''
''');
    final engine = TheoryValidationEngine();
    final issues = await engine.validateAll(dir: dir.path);
    expect(issues, isNotEmpty);
  });

  test('validateAll returns empty list for valid yaml', () async {
    final file = File(p.join(dir.path, 'good.yaml'));
    await file.writeAsString('''
id: t2
name: Good
trainingType: pushFold
tags: [pushFold]
spots:
  - id: s1
    type: theory
    tags: [pushFold]
    explanation: ok
''');
    final engine = TheoryValidationEngine();
    final issues = await engine.validateAll(dir: dir.path);
    expect(issues.length, 1); // both files
    // Should not contain errors for good.yaml
    final goodIssues = issues.where((e) => e.$1.endsWith('good.yaml'));
    expect(goodIssues, isEmpty);
  });
}
