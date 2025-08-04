import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/training_path_node_definition_service.dart';

void main() {
  const service = TrainingPathNodeDefinitionService();

  test('returns the defined path nodes', () {
    final path = service.getPath();
    expect(path.map((e) => e.id), [
      'starter_pushfold_10bb',
      'starter_postflop_basics',
      'advanced_pushfold_15bb',
    ]);
  });

  test('lookup by id', () {
    final node = service.getNode('starter_postflop_basics');
    expect(node, isNotNull);
    expect(node!.packIds, ['starter_postflop_basics']);
    expect(service.getNode('missing'), isNull);
  });
}
