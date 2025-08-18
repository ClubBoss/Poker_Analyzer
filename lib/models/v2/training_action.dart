class TrainingAction {
  final String spotId;
  final String chosenAction;
  final bool isCorrect;
  final DateTime timestamp;

  TrainingAction({
    required this.spotId,
    required this.chosenAction,
    required this.isCorrect,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory TrainingAction.fromJson(Map<String, dynamic> j) => TrainingAction(
    spotId: j['spotId'] as String? ?? '',
    chosenAction: j['chosenAction'] as String? ?? '',
    isCorrect: j['isCorrect'] as bool? ?? false,
    timestamp:
        DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'spotId': spotId,
    'chosenAction': chosenAction,
    'isCorrect': isCorrect,
    'timestamp': timestamp.toIso8601String(),
  };
}
