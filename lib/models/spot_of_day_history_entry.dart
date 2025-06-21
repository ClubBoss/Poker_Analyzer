class SpotOfDayHistoryEntry {
  final DateTime date;
  final int spotIndex;
  final String? userAction;
  final String? recommendedAction;

  SpotOfDayHistoryEntry({
    required this.date,
    required this.spotIndex,
    this.userAction,
    this.recommendedAction,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'spotIndex': spotIndex,
        if (userAction != null) 'userAction': userAction,
        if (recommendedAction != null) 'recommendedAction': recommendedAction,
      };

  factory SpotOfDayHistoryEntry.fromJson(Map<String, dynamic> json) =>
      SpotOfDayHistoryEntry(
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        spotIndex: json['spotIndex'] as int? ?? 0,
        userAction: json['userAction'] as String?,
        recommendedAction: json['recommendedAction'] as String?,
      );

  SpotOfDayHistoryEntry copyWith({String? userAction, String? recommendedAction}) =>
      SpotOfDayHistoryEntry(
        date: date,
        spotIndex: spotIndex,
        userAction: userAction ?? this.userAction,
        recommendedAction: recommendedAction ?? this.recommendedAction,
      );
}
