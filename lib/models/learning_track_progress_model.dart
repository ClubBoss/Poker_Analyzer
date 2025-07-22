enum StageStatus { locked, unlocked, completed }

class StageProgressStatus {
  final String stageId;
  final StageStatus status;

  const StageProgressStatus({required this.stageId, required this.status});
}

class LearningTrackProgressModel {
  final List<StageProgressStatus> stages;

  const LearningTrackProgressModel({required this.stages});

  StageProgressStatus? statusFor(String stageId) =>
      stages.firstWhere((e) => e.stageId == stageId, orElse: () => null);
}
