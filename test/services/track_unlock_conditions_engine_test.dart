import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/models/player_profile.dart';
import 'package:poker_analyzer/models/skill_level.dart';
import 'package:poker_analyzer/models/v3/lesson_track.dart';
import 'package:poker_analyzer/models/v3/track_unlock_condition.dart';
import 'package:poker_analyzer/services/track_unlock_conditions_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final profile = PlayerProfile(
    xp: 1500,
    tags: {'push_fold', 'icm'},
    gameType: GameType.tournament,
    skillLevel: SkillLevel.intermediate,
    completedLessonIds: {'intro'},
  );

  LessonTrack track(TrackUnlockCondition? cond) => LessonTrack(
        id: 't',
        title: 'Track',
        description: '',
        stepIds: const ['lesson1'],
        unlockCondition: cond,
      );

  test('unlocked by minXp', () {
    final t = track(TrackUnlockCondition(minXp: 1000));
    expect(
      const TrackUnlockConditionsEngine().isTrackUnlocked(t, profile),
      isTrue,
    );
  });

  test('locked by minXp', () {
    final t = track(TrackUnlockCondition(minXp: 2000));
    expect(
      const TrackUnlockConditionsEngine().isTrackUnlocked(t, profile),
      isFalse,
    );
  });

  test('locked by tag', () {
    final t = track(TrackUnlockCondition(requiredTags: {'mtt'}));
    expect(
      const TrackUnlockConditionsEngine().isTrackUnlocked(t, profile),
      isFalse,
    );
  });

  test('locked by completedLessonId', () {
    final t = track(TrackUnlockCondition(completedLessonIds: {'other'}));
    expect(
      const TrackUnlockConditionsEngine().isTrackUnlocked(t, profile),
      isFalse,
    );
  });
}
