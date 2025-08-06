enum AutogenPipelineStatus { idle, running, completed, failed }

class AutogenStatus {
  final AutogenPipelineStatus status;
  final String? lastTemplateSet;
  final DateTime? lastRun;
  final String? error;
  final String? activeStage;

  const AutogenStatus({
    this.status = AutogenPipelineStatus.idle,
    this.lastTemplateSet,
    this.lastRun,
    this.error,
    this.activeStage,
  });

  AutogenStatus copyWith({
    AutogenPipelineStatus? status,
    String? lastTemplateSet,
    DateTime? lastRun,
    String? error,
    String? activeStage,
  }) {
    return AutogenStatus(
      status: status ?? this.status,
      lastTemplateSet: lastTemplateSet ?? this.lastTemplateSet,
      lastRun: lastRun ?? this.lastRun,
      error: error ?? this.error,
      activeStage: activeStage ?? this.activeStage,
    );
  }
}
