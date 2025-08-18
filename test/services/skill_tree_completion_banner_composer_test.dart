import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_track_summary_builder.dart';
import 'package:poker_analyzer/services/skill_tree_track_progress_service.dart';
import 'package:poker_analyzer/services/skill_tree_completion_banner_composer.dart';
import 'package:poker_analyzer/services/skill_tree_category_banner_service.dart';
import 'package:poker_analyzer/models/skill_tree_track_summary.dart';
import 'package:poker_analyzer/models/skill_tree_category_visual.dart';

class _FakeSummaryBuilder extends SkillTreeTrackSummaryBuilder {
  final SkillTreeTrackSummary summary;
  const _FakeSummaryBuilder(this.summary);
  @override
  Future<SkillTreeTrackSummary> build(tree) async => summary;
}

class _FakeBannerService extends SkillTreeCategoryBannerService {
  final SkillTreeCategoryVisual visual;
  const _FakeBannerService(this.visual);
  @override
  SkillTreeCategoryVisual getVisual(String category) => visual;
}

class _FakeProgressService extends SkillTreeTrackProgressService {
  final TrackProgressEntry? next;
  const _FakeProgressService(this.next) : super();
  @override
  Future<TrackProgressEntry?> getNextTrack() async => next;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = SkillTreeBuilderService();

  SkillTreeNodeModel node(String id, String cat) =>
      SkillTreeNodeModel(id: id, title: id, category: cat);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('composes completion banner', () async {
    final tree = builder.build([node('a', 'A')]).tree;
    final nextTree = builder.build([node('b', 'B')]).tree;
    const summary = SkillTreeTrackSummary(
      title: 'A',
      completedCount: 1,
      avgEvLoss: null,
      motivationalLine: 'Good job!',
    );
    const visual = SkillTreeCategoryVisual(
      category: 'A',
      emoji: '🎉',
      color: Colors.red,
    );
    final model = await SkillTreeCompletionBannerComposer(
      summaryBuilder: const _FakeSummaryBuilder(summary),
      bannerService: const _FakeBannerService(visual),
      progressService: _FakeProgressService(
        TrackProgressEntry(
          tree: nextTree,
          completionRate: 0.0,
          isCompleted: false,
        ),
      ),
    ).compose(tree);
    expect(model.summary.title, 'A');
    expect(model.visual.emoji, '🎉');
    expect(model.nextTrack?.tree.nodes.containsKey('b'), isTrue);
  });
}
