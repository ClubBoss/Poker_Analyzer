import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_learning_map_layout_service.dart';
import 'package:poker_analyzer/services/skill_tree_track_progress_service.dart';

class _FakeTrackProgressService extends SkillTreeTrackProgressService {
  final List<TrackProgressEntry> entries;
  _FakeTrackProgressService(this.entries);

  @override
  Future<List<TrackProgressEntry>> getAllTrackProgress() async => entries;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = SkillTreeBuilderService();

  SkillTreeNodeModel node(String id, String cat) =>
      SkillTreeNodeModel(id: id, title: id, category: cat);

  test('builds grid layout with 2 columns', () async {
    final treeA = builder.build([node('a1', 'A')]).tree;
    final treeB = builder.build([node('b1', 'B')]).tree;
    final treeC = builder.build([node('c1', 'C')]).tree;

    final svc = SkillTreeLearningMapLayoutService(
      tracks: _FakeTrackProgressService([
        TrackProgressEntry(
            tree: treeA, completionRate: 0.1, isCompleted: false),
        TrackProgressEntry(
            tree: treeB, completionRate: 0.2, isCompleted: false),
        TrackProgressEntry(tree: treeC, completionRate: 0.3, isCompleted: true),
      ]),
    );

    final grid = await svc.buildLayout(columns: 2);
    expect(grid.length, 2);
    expect(grid[0].length, 2);
    expect(grid[1].length, 1);
  });
}
