import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_branch_node.dart';
import 'package:poker_analyzer/services/path_map_engine.dart';
import 'package:poker_analyzer/services/learning_path_validator.dart';
import 'package:poker_analyzer/models/theory_lesson_node.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('validator detects issues', () {
    const nodes = [
      TrainingStageNode(id: 'start', nextIds: ['a']),
      TrainingStageNode(id: 'a', nextIds: ['missing']),
      LearningBranchNode(
        id: 'b',
        prompt: 'Q',
        branches: {'A': 'a', 'B': 'orphan'},
      ),
      TrainingStageNode(id: 'loop', nextIds: ['loop']),
      TrainingStageNode(id: 'unref'),
    ];
    final errors = LearningPathValidator.validate(nodes);
    expect(errors, contains('Node a references missing node missing'));
    expect(errors, contains('Node b references missing node orphan'));
    expect(errors.any((e) => e.startsWith('Cycle detected')), isTrue);
    expect(errors, contains('Node unref is disconnected'));
  });

  test('validator passes for valid graph', () {
    const nodes = [
      TrainingStageNode(id: 'start', nextIds: ['end']),
      TrainingStageNode(id: 'end'),
    ];
    final errors = LearningPathValidator.validate(nodes);
    expect(errors, isEmpty);
  });

  test('validator handles theory nodes', () {
    const nodes = [
      TheoryLessonNode(
        id: 't1',
        refId: 'welcome',
        title: 'T',
        content: 'C',
        nextIds: ['end'],
      ),
      TrainingStageNode(id: 'end'),
    ];
    final errors = LearningPathValidator.validate(nodes);
    expect(errors, isEmpty);
  });
}
