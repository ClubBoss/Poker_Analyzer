class AutogenStatus {
  final bool isRunning;
  final String currentStage;
  final double progress;
  final String? lastError;
  final String? file;
  final String? action;
  final String? prevHash;
  final String? newHash;

  const AutogenStatus({
    this.isRunning = false,
    this.currentStage = '',
    this.progress = 0.0,
    this.lastError,
    this.file,
    this.action,
    this.prevHash,
    this.newHash,
  });

  AutogenStatus copyWith({
    bool? isRunning,
    String? currentStage,
    double? progress,
    String? lastError,
    String? file,
    String? action,
    String? prevHash,
    String? newHash,
  }) {
    return AutogenStatus(
      isRunning: isRunning ?? this.isRunning,
      currentStage: currentStage ?? this.currentStage,
      progress: progress ?? this.progress,
      lastError: lastError ?? this.lastError,
      file: file ?? this.file,
      action: action ?? this.action,
      prevHash: prevHash ?? this.prevHash,
      newHash: newHash ?? this.newHash,
    );
  }
}
