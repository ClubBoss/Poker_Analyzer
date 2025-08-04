import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/training_path_node.dart';
import 'package:poker_analyzer/services/node_recommendation_service.dart';
import 'package:poker_analyzer/services/training_path_node_definition_service.dart';
import 'package:poker_analyzer/services/training_path_progress_tracker_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestDefinitions extends TrainingPathNodeDefinitionService {
  final List<TrainingPathNode> _nodes;
  const _TestDefinitions(this._nodes);

  @override
  List<TrainingPathNode> getPath() => _nodes;

  @override
  TrainingPathNode? getNode(String id) {
    for (final n in _nodes) {
      if (n.id == id) return n;
    }
    return null;
  }
}

void main() {
  final nodes = [
    const TrainingPathNode(
      id: 'a',
      title: 'A',
      packIds: ['a'],
      prerequisiteNodeIds: [],
    ),
    const TrainingPathNode(
      id: 'b',
      title: 'B',
      packIds: ['b'],
      prerequisiteNodeIds: ['a'],
    ),
    const TrainingPathNode(
      id: 'c',
      title: 'C',
      packIds: ['c'],
      prerequisiteNodeIds: ['a'],
    ),
    const TrainingPathNode(
      id: 'd',
      title: 'D',
      packIds: ['d'],
      prerequisiteNodeIds: ['b'],
    ),
  ];

  final definitions = _TestDefinitions(nodes);

  late NodeRecommendationService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final progress = TrainingPathProgressTrackerService(
      definitions: definitions,
      prefs: prefs,
    );
    service = NodeRecommendationService(
      definitions: definitions,
      progress: progress,
    );
    await progress.markCompleted('a');
  });

  test('recommends sibling nodes with same prerequisites', () async {
    final recs = await service.getRecommendations(nodes[1]); // node b
    expect(recs.map((e) => e.node.id), ['c']);
    expect(recs.first.reason, 'parallel topic');
  });

  test('recommends unmet prerequisite nodes', () async {
    final recs = await service.getRecommendations(nodes[3]); // node d
    expect(recs.map((e) => e.node.id), ['b']);
    expect(recs.first.reason, 'unmet prerequisite');
  });
}
