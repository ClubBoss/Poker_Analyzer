import '../models/v3/lesson_track.dart';

class LearningTrackEngine {
  const LearningTrackEngine();

  static final List<LessonTrack> _tracks = [
    LessonTrack(
      id: 'mtt_pro',
      title: 'MTT Pro Track',
      description: 'Become a tournament crusher',
      stepIds: const ['lesson1'],
    ),
    LessonTrack(
      id: 'live_exploit',
      title: 'Live Exploit Track',
      description: 'Exploitative lines for live games',
      stepIds: const ['lesson1'],
    ),
    LessonTrack(
      id: 'leak_fixer',
      title: 'Leak Fixer',
      description: 'Fix your weakest spots using tags',
      stepIds: const ['lesson1'],
    ),
  ];

  List<LessonTrack> getTracks() => List.unmodifiable(_tracks);
}
