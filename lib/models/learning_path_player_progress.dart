/// Progress tracking for the Learning Path Player.
///
/// Stores per-stage statistics and overall state for a learning path.
class LearningPathProgress {
  final Map<String, StageProgress> stages;
  final String? currentStageId;
  final DateTime updatedAt;

  LearningPathProgress({
    Map<String, StageProgress>? stages,
    this.currentStageId,
    DateTime? updatedAt,
  })  : stages = stages ?? {},
        updatedAt = updatedAt ?? DateTime.now();

  LearningPathProgress copyWith({
    Map<String, StageProgress>? stages,
    String? currentStageId,
    DateTime? updatedAt,
  }) {
    return LearningPathProgress(
      stages: stages ?? this.stages,
      currentStageId: currentStageId ?? this.currentStageId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'stages': stages.map((k, v) => MapEntry(k, v.toJson())),
        'currentStageId': currentStageId,
        'updatedAt': updatedAt.toIso8601String(),
        'version': 1,
      };

  factory LearningPathProgress.fromJson(Map<String, dynamic> json) {
    final stagesJson = json['stages'] as Map? ?? {};
    final stages = <String, StageProgress>{};
    stagesJson.forEach((key, value) {
      stages[key] = StageProgress.fromJson(Map<String, dynamic>.from(value));
    });
    return LearningPathProgress(
      stages: stages,
      currentStageId: json['currentStageId'] as String?,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class StageProgress {
  final int attempts;
  final int handsPlayed;
  final int correct;
  final double accuracy;
  final bool completed;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const StageProgress({
    this.attempts = 0,
    this.handsPlayed = 0,
    this.correct = 0,
    this.accuracy = 0,
    this.completed = false,
    this.startedAt,
    this.completedAt,
  });

  /// Records a hand outcome and returns updated [StageProgress].
  StageProgress recordHand({required bool correct}) {
    final newHands = handsPlayed + 1;
    final newCorrect = correct ? this.correct + 1 : this.correct;
    final acc = newHands == 0 ? 0.0 : newCorrect / newHands;
    return copyWith(
      handsPlayed: newHands,
      correct: newCorrect,
      accuracy: acc,
    );
  }

  StageProgress copyWith({
    int? attempts,
    int? handsPlayed,
    int? correct,
    double? accuracy,
    bool? completed,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return StageProgress(
      attempts: attempts ?? this.attempts,
      handsPlayed: handsPlayed ?? this.handsPlayed,
      correct: correct ?? this.correct,
      accuracy: accuracy ?? this.accuracy,
      completed: completed ?? this.completed,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'attempts': attempts,
        'handsPlayed': handsPlayed,
        'correct': correct,
        'accuracy': accuracy,
        'completed': completed,
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory StageProgress.fromJson(Map<String, dynamic> json) {
    return StageProgress(
      attempts: json['attempts'] as int? ?? 0,
      handsPlayed: json['handsPlayed'] as int? ?? 0,
      correct: json['correct'] as int? ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      completed: json['completed'] as bool? ?? false,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }
}

