class MistakeHistoryEntry {
  final String spotId;
  final DateTime timestamp;
  final String decayStage;
  final String tag;
  final bool wasRecovered;

  const MistakeHistoryEntry({
    required this.spotId,
    required this.timestamp,
    required this.decayStage,
    required this.tag,
    required this.wasRecovered,
  });
}

