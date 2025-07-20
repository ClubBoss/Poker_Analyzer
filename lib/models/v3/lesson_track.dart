import 'track_unlock_condition.dart';

class LessonTrack {
  final String id;
  final String title;
  final String description;
  final List<String> stepIds;
  final TrackUnlockCondition? unlockCondition;

  const LessonTrack({
    required this.id,
    required this.title,
    required this.description,
    required this.stepIds,
    this.unlockCondition,
  });
}
