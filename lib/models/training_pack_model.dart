import 'v2/training_pack_spot.dart';

class TrainingPackModel {
  final String id;
  final String title;
  final List<TrainingPackSpot> spots;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  TrainingPackModel({
    required this.id,
    required this.title,
    required this.spots,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  })  : tags = tags ?? const [],
        metadata = metadata ?? const {};
}
