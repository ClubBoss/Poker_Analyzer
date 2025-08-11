import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/auto_theory_stage_seeder.dart';
import 'package:poker_analyzer/services/learning_path_stage_library.dart';
import 'package:poker_analyzer/services/smart_theory_suggestion_engine.dart';
import 'package:poker_analyzer/models/stage_type.dart';

class _FakeEngine extends SmartTheorySuggestionEngine {
  final List<TheorySuggestion> list;
  _FakeEngine(this.list) : super(mastery: throw UnimplementedError());
  @override
  Future<List<TheorySuggestion>> suggestMissingTheoryStages({double threshold = 0.3}) async => list;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exportYamlFile writes file and injects stages', () async {
    final dir = await Directory.systemTemp.createTemp('auto_theory');
    final engine = _FakeEngine(const [
      TheorySuggestion(tag: 'aggr', proposedTitle: 'Теория: aggr', proposedPackId: 'theory_aggr'),
    ]);
    final seeder = AutoTheoryStageSeeder(
      engine: engine,
      outputDir: dir.path,
      now: () => DateTime(2024, 1, 1, 12, 0),
    );
    final path = await seeder.exportYamlFile(inject: true);
    expect(path, isNotNull);
    final file = File(path!);
    expect(file.existsSync(), isTrue);
    final text = await file.readAsString();
    expect(text, contains('theory_aggr'));
    final stages = LearningPathStageLibrary.instance.stages;
    expect(stages, hasLength(1));
    expect(stages.first.type, StageType.theory);
  });

  test('generateYamlForMissingTheoryStages returns yaml', () async {
    final engine = _FakeEngine(const [
      TheorySuggestion(tag: 'test', proposedTitle: 'Теория: test', proposedPackId: 'theory_test'),
    ]);
    final seeder = AutoTheoryStageSeeder(engine: engine);
    final yaml = await seeder.generateYamlForMissingTheoryStages();
    expect(yaml, contains('stages:'));
    expect(yaml, contains('theory_test'));
  });
}
