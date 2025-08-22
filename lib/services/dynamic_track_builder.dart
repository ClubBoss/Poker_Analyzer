import '../models/learning_goal.dart';
import '../models/training_track.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';

class DynamicTrackBuilder {
  DynamicTrackBuilder();

  List<TrainingTrack> buildTracks({
    required List<LearningGoal> goals,
    required List<TrainingPackTemplateV2> sourcePacks,
    int spotsPerTrack = 8,
  }) {
    final tracks = <TrainingTrack>[];
    var index = 0;
    for (final goal in goals) {
      final tag = goal.tag.toLowerCase();
      final spots = <TrainingPackSpot>[];
      for (final pack in sourcePacks) {
        for (final spot in pack.spots) {
          final spotTags = <String>{
            ...pack.tags.map((e) => e.toLowerCase()),
            ...spot.tags.map((e) => e.toLowerCase()),
            ...spot.categories.map((e) => e.toLowerCase()),
          }..removeWhere((e) => e.isEmpty);
          if (spotTags.contains(tag)) {
            spots.add(spot);
          }
        }
      }
      if (spots.isEmpty) continue;
      spots.sort((a, b) {
        final evA = a.heroEv ?? 0;
        final evB = b.heroEv ?? 0;
        return evA.compareTo(evB);
      });
      final selected = spots.take(spotsPerTrack).toList();
      final title = _titleFor(goal);
      tracks.add(
        TrainingTrack(
          id: 'track_${goal.id}_$index',
          title: title,
          goalId: goal.id,
          spots: selected,
          tags: [goal.tag],
        ),
      );
      index++;
    }
    return tracks;
  }

  String _titleFor(LearningGoal goal) {
    if (goal.title.isNotEmpty) return goal.title;
    final words = goal.tag
        .split(RegExp(r'[\s_-]+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .toList();
    return 'Fix ${words.join(' ')} Mistakes';
  }
}
