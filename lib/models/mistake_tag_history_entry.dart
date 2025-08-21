import '../models/mistake_tag.dart';

class MistakeTagHistoryEntry {
  final DateTime timestamp;
  final String packId;
  final String spotId;
  final List<MistakeTag> tags;
  final double evDiff;

  const MistakeTagHistoryEntry({
    required this.timestamp,
    required this.packId,
    required this.spotId,
    required this.tags,
    required this.evDiff,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'packId': packId,
        'spotId': spotId,
        'tags': [for (final t in tags) t.name],
        'evDiff': evDiff,
      };

  factory MistakeTagHistoryEntry.fromJson(Map<String, dynamic> j) {
    return MistakeTagHistoryEntry(
      timestamp:
          DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
      packId: j['packId'] as String? ?? '',
      spotId: j['spotId'] as String? ?? '',
      tags: [
        for (final t in (j['tags'] as List? ?? []))
          MistakeTag.values.firstWhere(
            (e) => e.name == t.toString(),
            orElse: () => MistakeTag.values.first,
          ),
      ],
      evDiff: (j['evDiff'] as num?)?.toDouble() ?? 0,
    );
  }
}
