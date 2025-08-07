class AutogenStatus {
  final bool isRunning;
  final String currentStage;
  final double progress;
  final String? lastError;

  const AutogenStatus({
    this.isRunning = false,
    this.currentStage = '',
    this.progress = 0.0,
    this.lastError,
  });

  AutogenStatus copyWith({
    bool? isRunning,
    String? currentStage,
    double? progress,
    String? lastError,
  }) {
    return AutogenStatus(
      isRunning: isRunning ?? this.isRunning,
      currentStage: currentStage ?? this.currentStage,
      progress: progress ?? this.progress,
      lastError: lastError ?? this.lastError,
    );
  }
}
