import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/skill_loss_feed_engine.dart';
import 'package:poker_analyzer/services/skill_loss_detector.dart';
import 'package:poker_analyzer/services/tag_goal_tracker_service.dart';
import 'package:poker_analyzer/services/pack_library_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/services/tag_review_history_service.dart';

class _FakeGoals implements TagGoalTrackerService {
  final Map<String, DateTime?> map;
  _FakeGoals(this.map);
  @override
  Future<TagGoalProgress> getProgress(String tagId) async {
    return TagGoalProgress(
      trainings: 0,
      xp: 0,
      streak: 0,
      lastTrainingDate: map[tagId],
    );
  }

  @override
  Future<void> logTraining(String tagId) async {}
}

class _FakeLibrary implements PackLibraryService {
  final Map<String, TrainingPackTemplateV2> byTag;
  _FakeLibrary(this.byTag);
  @override
  Future<TrainingPackTemplateV2?> recommendedStarter() async => null;
  @override
  Future<TrainingPackTemplateV2?> getById(String id) async => byTag.values
      .firstWhere((p) => p.id == id, orElse: () => byTag.values.first);
  @override
  Future<TrainingPackTemplateV2?> findByTag(String tag) async => byTag[tag];
  @override
  Future<List<String>> findBoosterCandidates(String tag) async => const [];
}

class _FakeReviews implements TagReviewHistoryService {
  final Map<String, TagReviewRecord> map;
  _FakeReviews(this.map);
  @override
  Future<void> logReview(String tag, double accuracy) async {}

  @override
  Future<TagReviewRecord?> getRecord(String tag) async => map[tag];
}

TrainingPackTemplateV2 _tpl(String id, String tag) {
  return TrainingPackTemplateV2(
    id: id,
    name: id,
    trainingType: TrainingType.pushFold,
    gameType: GameType.tournament,
    tags: [tag],
    spots: const [],
    spotCount: 0,
    created: DateTime.now(),
    positions: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildFeed ranks losses by urgency', () async {
    final goals = _FakeGoals({
      'a': DateTime.now().subtract(const Duration(days: 10)),
      'b': DateTime.now().subtract(const Duration(days: 1)),
    });
    final library = _FakeLibrary({'a': _tpl('pa', 'a'), 'b': _tpl('pb', 'b')});
    final engine = SkillLossFeedEngine(goals: goals, library: library);
    final losses = [
      SkillLoss(tag: 'a', drop: 0.5, trend: ''),
      SkillLoss(tag: 'b', drop: 0.6, trend: ''),
    ];
    final result = await engine.buildFeed(losses);
    expect(result.length, 2);
    expect(result.first.tag, 'a');
    expect(result.first.suggestedPackId, 'pa');
    expect(result.last.tag, 'b');
  });

  test('recent high accuracy lowers urgency', () async {
    final goals = _FakeGoals({
      'a': DateTime.now().subtract(const Duration(days: 5)),
      'b': DateTime.now().subtract(const Duration(days: 5)),
    });
    final library = _FakeLibrary({'a': _tpl('pa', 'a'), 'b': _tpl('pb', 'b')});
    final reviews = _FakeReviews({
      'a': TagReviewRecord(accuracy: 0.9, timestamp: DateTime.now()),
    });
    final engine = SkillLossFeedEngine(
      goals: goals,
      library: library,
      reviews: reviews,
    );
    final losses = [
      SkillLoss(tag: 'a', drop: 0.6, trend: ''),
      SkillLoss(tag: 'b', drop: 0.6, trend: ''),
    ];
    final result = await engine.buildFeed(losses);
    expect(result.first.tag, 'b');
  });
}
