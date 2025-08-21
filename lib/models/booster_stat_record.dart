class BoosterStatRecord {
  final String type;
  final int suggested;
  final int accepted;
  final int dismissed;

  const BoosterStatRecord({
    required this.type,
    this.suggested = 0,
    this.accepted = 0,
    this.dismissed = 0,
  });

  BoosterStatRecord copyWith({int? suggested, int? accepted, int? dismissed}) {
    return BoosterStatRecord(
      type: type,
      suggested: suggested ?? this.suggested,
      accepted: accepted ?? this.accepted,
      dismissed: dismissed ?? this.dismissed,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'suggested': suggested,
    'accepted': accepted,
    'dismissed': dismissed,
  };

  factory BoosterStatRecord.fromJson(Map<String, dynamic> json) =>
      BoosterStatRecord(
        type: json['type'] as String? ?? '',
        suggested: (json['suggested'] as num?)?.toInt() ?? 0,
        accepted: (json['accepted'] as num?)?.toInt() ?? 0,
        dismissed: (json['dismissed'] as num?)?.toInt() ?? 0,
      );
}
