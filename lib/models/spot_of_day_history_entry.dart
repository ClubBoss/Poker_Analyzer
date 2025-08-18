class SpotOfDayHistoryEntry {
  final DateTime date;
  final int spotIndex;
  final String? userAction;
  final String? recommendedAction;
  final bool? correct;

  SpotOfDayHistoryEntry({
    required this.date,
    required this.spotIndex,
    this.userAction,
    this.recommendedAction,
    this.correct,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'spotIndex': spotIndex,
    if (userAction != null) 'userAction': userAction,
    if (recommendedAction != null) 'recommendedAction': recommendedAction,
    if (correct != null) 'correct': correct,
  };

  factory SpotOfDayHistoryEntry.fromJson(Map<String, dynamic> json) =>
      SpotOfDayHistoryEntry(
        date:
            DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        spotIndex: json['spotIndex'] as int? ?? 0,
        userAction: json['userAction'] as String?,
        recommendedAction: json['recommendedAction'] as String?,
        correct: json['correct'] as bool?,
      );

  SpotOfDayHistoryEntry copyWith({
    String? userAction,
    String? recommendedAction,
    bool? correct,
  }) => SpotOfDayHistoryEntry(
    date: date,
    spotIndex: spotIndex,
    userAction: userAction ?? this.userAction,
    recommendedAction: recommendedAction ?? this.recommendedAction,
    correct: correct ?? this.correct,
  );
}
