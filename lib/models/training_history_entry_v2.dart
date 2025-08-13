import '../core/training/engine/training_type_engine.dart';
import 'package:uuid/uuid.dart';

class TrainingHistoryEntryV2 {
  final String id;
  final DateTime timestamp;
  final List<String> tags;
  final String packId;
  final TrainingType type;

  TrainingHistoryEntryV2({
    String? id,
    required this.timestamp,
    required this.tags,
    required this.packId,
    required this.type,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        if (tags.isNotEmpty) 'tags': tags,
        'packId': packId,
        'type': type.name,
      };

  factory TrainingHistoryEntryV2.fromJson(Map<String, dynamic> j) =>
      TrainingHistoryEntryV2(
        id: j['id'] as String?,
        timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ??
            DateTime.now(),
        tags: [for (final t in (j['tags'] as List? ?? [])) t.toString()],
        packId: j['packId'] as String? ?? '',
        type: TrainingType.values.firstWhere(
          (e) => e.name == j['type'],
          orElse: () => TrainingType.pushFold,
        ),
      );
}
