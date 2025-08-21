class SkillBoostLogEntry {
  final String tag;
  final String packId;
  final DateTime timestamp;
  final double accuracyBefore;
  final double accuracyAfter;
  final int handsPlayed;

  SkillBoostLogEntry({
    required this.tag,
    required this.packId,
    required this.timestamp,
    required this.accuracyBefore,
    required this.accuracyAfter,
    required this.handsPlayed,
  });

  Map<String, dynamic> toJson() => {
        'tag': tag,
        'packId': packId,
        'timestamp': timestamp.toIso8601String(),
        'accuracyBefore': accuracyBefore,
        'accuracyAfter': accuracyAfter,
        'handsPlayed': handsPlayed,
      };

  factory SkillBoostLogEntry.fromJson(Map<String, dynamic> j) =>
      SkillBoostLogEntry(
        tag: j['tag'] as String? ?? '',
        packId: j['packId'] as String? ?? '',
        timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ??
            DateTime.now(),
        accuracyBefore: (j['accuracyBefore'] as num?)?.toDouble() ?? 0.0,
        accuracyAfter: (j['accuracyAfter'] as num?)?.toDouble() ?? 0.0,
        handsPlayed: (j['handsPlayed'] as num?)?.toInt() ?? 0,
      );
}
