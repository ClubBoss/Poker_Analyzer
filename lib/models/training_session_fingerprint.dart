import 'dart:convert';

class TrainingSessionFingerprint {
  final String sessionId;
  final DateTime startedAt;
  final String packId;
  final String trainingType;
  final List<String> includedTags;
  final List<String> involvedLines;
  final String source;

  TrainingSessionFingerprint({
    required this.sessionId,
    required this.startedAt,
    required this.packId,
    required this.trainingType,
    List<String>? includedTags,
    List<String>? involvedLines,
    this.source = '',
  })  : includedTags = includedTags ?? const [],
        involvedLines = involvedLines ?? const [];

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'startedAt': startedAt.toIso8601String(),
        'packId': packId,
        'trainingType': trainingType,
        'includedTags': includedTags,
        'involvedLines': involvedLines,
        'source': source,
      };

  @override
  String toString() => jsonEncode(toJson());
}

