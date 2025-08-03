class SpotAttemptSummary {
  final String spotId;
  final String userAction;
  final bool isCorrect;
  final double evDiff;
  final List<String> shownTheoryTags;

  SpotAttemptSummary({
    required this.spotId,
    required this.userAction,
    required this.isCorrect,
    required this.evDiff,
    List<String>? shownTheoryTags,
  }) : shownTheoryTags = shownTheoryTags ?? const [];

  Map<String, dynamic> toJson() => {
        'spotId': spotId,
        'userAction': userAction,
        'isCorrect': isCorrect,
        'evDiff': evDiff,
        if (shownTheoryTags.isNotEmpty) 'shownTheoryTags': shownTheoryTags,
      };

  factory SpotAttemptSummary.fromJson(Map<String, dynamic> json) {
    return SpotAttemptSummary(
      spotId: json['spotId'] as String? ?? '',
      userAction: json['userAction'] as String? ?? '',
      isCorrect: json['isCorrect'] == true,
      evDiff: (json['evDiff'] as num?)?.toDouble() ?? 0,
      shownTheoryTags: [
        for (final t in (json['shownTheoryTags'] as List? ?? [])) t.toString(),
      ],
    );
  }
}

