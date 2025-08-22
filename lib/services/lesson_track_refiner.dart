import '../models/training_track.dart';
import '../models/v2/training_pack_spot.dart';

class LessonTrackRefiner {
  LessonTrackRefiner();

  TrainingTrack refineTrack(TrainingTrack original, {double minEvGap = 0.15}) {
    final refined = <TrainingPackSpot>[];

    for (final spot in original.spots) {
      final gap = _evGap(spot);
      if (gap == null || gap >= minEvGap) {
        refined.add(spot);
      }
    }

    if (refined.length < 4) return original;

    refined.sort((a, b) {
      final gapA = _evGap(a) ?? double.infinity;
      final gapB = _evGap(b) ?? double.infinity;
      return gapA.compareTo(gapB);
    });

    return TrainingTrack(
      id: original.id,
      title: original.title,
      goalId: original.goalId,
      spots: refined,
      tags: List<String>.from(original.tags),
    );
  }

  double? _evGap(TrainingPackSpot spot) {
    double? pushEv;
    double? foldEv;
    final actions = spot.hand.actions[0] ?? [];
    for (final a in actions) {
      if (a.playerIndex != spot.hand.heroIndex) continue;
      final act = a.action.toLowerCase();
      if (act == 'push') pushEv = a.ev;
      if (act == 'fold') foldEv = a.ev;
    }
    foldEv ??= 0;
    if (pushEv == null && foldEv == null) return null;
    if (pushEv == null) return foldEv.abs();
    return (pushEv - foldEv).abs();
  }
}
