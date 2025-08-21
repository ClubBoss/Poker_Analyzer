import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/models/player_profile.dart';
import 'package:poker_analyzer/models/skill_level.dart';
import 'package:poker_analyzer/models/v3/lesson_step.dart';
import 'package:poker_analyzer/models/v3/lesson_step_filter.dart';
import 'package:poker_analyzer/services/lesson_step_filter_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final profile = PlayerProfile(
    xp: 1500,
    tags: {'push_fold', 'icm'},
    gameType: GameType.tournament,
    skillLevel: SkillLevel.intermediate,
    completedLessonIds: {'intro'},
  );

  LessonStep step(String id, LessonStepFilter? filter) => LessonStep(
        id: id,
        title: id,
        introText: '',
        linkedPackId: 'p',
        filter: filter,
        meta: const {'schemaVersion': '3.0.0'},
      );

  test('filters by minXp', () {
    final steps = [
      step('a', LessonStepFilter(minXp: 1000)),
      step('b', LessonStepFilter(minXp: 2000)),
    ];
    final result = const LessonStepFilterEngine().applyFilters(
      steps,
      profile: profile,
    );
    expect(result.map((s) => s.id), ['a']);
  });

  test('filters by tag', () {
    final steps = [
      step('a', LessonStepFilter(tags: {'push_fold'})),
      step('b', LessonStepFilter(tags: {'mtt'})),
    ];
    final result = const LessonStepFilterEngine().applyFilters(
      steps,
      profile: profile,
    );
    expect(result.map((s) => s.id), ['a']);
  });

  test('filters by completedLessonIds', () {
    final steps = [
      step('a', LessonStepFilter(completedLessonIds: {'intro'})),
      step('b', LessonStepFilter(completedLessonIds: {'other'})),
    ];
    final result = const LessonStepFilterEngine().applyFilters(
      steps,
      profile: profile,
    );
    expect(result.map((s) => s.id), ['a']);
  });

  test('filters by gameType', () {
    final steps = [
      step('a', LessonStepFilter(gameType: GameType.tournament)),
      step('b', LessonStepFilter(gameType: GameType.cash)),
    ];
    final result = const LessonStepFilterEngine().applyFilters(
      steps,
      profile: profile,
    );
    expect(result.map((s) => s.id), ['a']);
  });

  test('filters by skillLevel', () {
    final steps = [
      step('a', LessonStepFilter(skillLevel: SkillLevel.intermediate)),
      step('b', LessonStepFilter(skillLevel: SkillLevel.advanced)),
    ];
    final result = const LessonStepFilterEngine().applyFilters(
      steps,
      profile: profile,
    );
    expect(result.map((s) => s.id), ['a']);
  });

  test('filters by multiple conditions', () {
    final steps = [
      step(
        'a',
        LessonStepFilter(
          minXp: 1000,
          tags: {'push_fold'},
          gameType: GameType.tournament,
        ),
      ),
      step(
        'b',
        LessonStepFilter(
          minXp: 1600,
          tags: {'push_fold'},
          gameType: GameType.tournament,
        ),
      ),
    ];
    final result = const LessonStepFilterEngine().applyFilters(
      steps,
      profile: profile,
    );
    expect(result.map((s) => s.id), ['a']);
  });
}
