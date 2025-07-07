import 'package:uuid/uuid.dart';
import 'v2/training_pack_spot.dart';

class TemplateSnapshot {
  final String id;
  final String comment;
  final DateTime timestamp;
  final List<TrainingPackSpot> spots;

  TemplateSnapshot({
    String? id,
    required this.comment,
    DateTime? timestamp,
    required this.spots,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'comment': comment,
        'timestamp': timestamp.toIso8601String(),
        'spots': [for (final s in spots) s.toJson()],
      };

  factory TemplateSnapshot.fromJson(Map<String, dynamic> json) => TemplateSnapshot(
        id: json['id'] as String?,
        comment: json['comment'] as String? ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
        spots: [
          for (final s in (json['spots'] as List? ?? []))
            TrainingPackSpot.fromJson(Map<String, dynamic>.from(s as Map))
        ],
      );
}
