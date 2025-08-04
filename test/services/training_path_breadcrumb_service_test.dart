import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/training_path_node.dart';
import 'package:poker_analyzer/services/training_path_breadcrumb_service.dart';
import 'package:poker_analyzer/services/training_path_node_definition_service.dart';

void main() {
  const definitions = TrainingPathNodeDefinitionService();
  const service = TrainingPathBreadcrumbService();

  final root = definitions.getNode('starter_pushfold_10bb')!;
  final mid = definitions.getNode('starter_postflop_basics')!;
  final leaf = definitions.getNode('advanced_pushfold_15bb')!;

  test('breadcrumb for root node includes only itself', () {
    expect(service.getBreadcrumb(root).map((e) => e.id), [root.id]);
  });

  test('breadcrumb for intermediate node follows prerequisite chain', () {
    expect(service.getBreadcrumb(mid).map((e) => e.id), [root.id, mid.id]);
  });

  test('breadcrumb for leaf node includes all ancestors', () {
    expect(service.getBreadcrumb(leaf).map((e) => e.id), [
      root.id,
      mid.id,
      leaf.id,
    ]);
  });
}
