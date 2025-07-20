import 'v2/training_pack_spot.dart';

class TrainingTrack {
  final String id;
  final String title;
  final String goalId;
  final List<TrainingPackSpot> spots;
  final List<String> tags;

  const TrainingTrack({
    required this.id,
    required this.title,
    required this.goalId,
    required this.spots,
    required this.tags,
  });
}
