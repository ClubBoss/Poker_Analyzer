import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_track_progress_service.dart';
import 'package:poker_analyzer/services/skill_tree_path_progress_overview_service.dart';

class _FakeTrackProgressService extends SkillTreeTrackProgressService {
  final List<TrackProgressEntry> entries;
  const _FakeTrackProgressService(this.entries);

  @override
  Future<List<TrackProgressEntry>> getAllTrackProgress() async => entries;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = SkillTreeBuilderService();

  SkillTreeNodeModel node(String id, String cat) =>
      SkillTreeNodeModel(id: id, title: id, category: cat);

  test('aggregates overall path progress', () async {
    final treeA = builder.build([node('a1', 'A')]).tree;
    final treeB = builder.build([node('b1', 'B')]).tree;
    final treeC = builder.build([node('c1', 'C')]).tree;

    final svc = SkillTreePathProgressOverviewService(
      tracks: _FakeTrackProgressService([
        const TrackProgressEntry(
          tree: treeA,
          completionRate: 1.0,
          isCompleted: true,
        ),
        const TrackProgressEntry(
          tree: treeB,
          completionRate: 0.5,
          isCompleted: false,
        ),
        const TrackProgressEntry(
          tree: treeC,
          completionRate: 0.75,
          isCompleted: true,
        ),
      ]),
    );

    final overview = await svc.computeOverview();
    expect(overview.totalTracks, 3);
    expect(overview.completedTracks, 2);
    expect(
      overview.averageCompletionRate,
      closeTo((1.0 + 0.5 + 0.75) / 3, 1e-6),
    );
  });
}
