enum AutogenRunState { idle, running, paused }

/// Status information for the autogen pipeline.
class AutogenStatus {
  /// Legacy fields kept for backwards compatibility.
  final bool isRunning;
  final String currentStage;
  final double progress;
  final String? lastError;
  final String? file;
  final String? action;
  final String? prevHash;
  final String? newHash;

  // New dashboard fields.
  final AutogenRunState state;
  final String currentStep;
  final int queueDepth;
  final int processed;
  final int errorsCount;
  final DateTime? startedAt;
  final DateTime? updatedAt;
  final Duration? eta;
  final String? lastErrorMsg;

  const AutogenStatus({
    this.isRunning = false,
    this.currentStage = '',
    this.progress = 0.0,
    this.lastError,
    this.file,
    this.action,
    this.prevHash,
    this.newHash,
    this.state = AutogenRunState.idle,
    this.currentStep = '',
    this.queueDepth = 0,
    this.processed = 0,
    this.errorsCount = 0,
    this.startedAt,
    this.updatedAt,
    this.eta,
    this.lastErrorMsg,
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
    AutogenRunState? state,
    String? currentStep,
    int? queueDepth,
    int? processed,
    int? errorsCount,
    DateTime? startedAt,
    DateTime? updatedAt,
    Duration? eta,
    String? lastErrorMsg,
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
      state: state ?? this.state,
      currentStep: currentStep ?? this.currentStep,
      queueDepth: queueDepth ?? this.queueDepth,
      processed: processed ?? this.processed,
      errorsCount: errorsCount ?? this.errorsCount,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      eta: eta ?? this.eta,
      lastErrorMsg: lastErrorMsg ?? this.lastErrorMsg,
    );
  }

  Map<String, dynamic> toJson() => {
    'state': state.name,
    'currentStep': currentStep,
    'queueDepth': queueDepth,
    'processed': processed,
    'errorsCount': errorsCount,
    'startedAt': startedAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'eta': eta?.inMilliseconds,
    'lastErrorMsg': lastErrorMsg,
  };

  factory AutogenStatus.fromJson(Map<String, dynamic> json) {
    return AutogenStatus(
      state: AutogenRunState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => AutogenRunState.idle,
      ),
      currentStep: json['currentStep'] ?? '',
      queueDepth: json['queueDepth'] ?? 0,
      processed: json['processed'] ?? 0,
      errorsCount: json['errorsCount'] ?? 0,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      eta: json['eta'] != null
          ? Duration(milliseconds: json['eta'] as int)
          : null,
      lastErrorMsg: json['lastErrorMsg'] as String?,
    );
  }
}
