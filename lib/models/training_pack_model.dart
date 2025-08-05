import 'v2/training_pack_spot.dart';

class TrainingPackModel {
  final String id;
  final String title;
  final List<TrainingPackSpot> spots;
  final List<String> tags;

  TrainingPackModel({
    required this.id,
    required this.title,
    required this.spots,
    List<String>? tags,
  }) : tags = tags ?? const [];
}
