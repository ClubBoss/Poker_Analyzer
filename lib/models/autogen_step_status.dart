class AutoGenStepStatus {
  final String stepName;
  final String status;
  final String? errorMessage;

  const AutoGenStepStatus({
    required this.stepName,
    required this.status,
    this.errorMessage,
  });

  AutoGenStepStatus copyWith({
    String? stepName,
    String? status,
    String? errorMessage,
  }) {
    return AutoGenStepStatus(
      stepName: stepName ?? this.stepName,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
