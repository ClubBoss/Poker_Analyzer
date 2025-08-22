enum PathIssueType {
  missingPack,
  invalidStageOrder,
  duplicateId,
  unlinkedStage,
}

class PathValidationIssue {
  final String pathId;
  final String? stageId;
  final String? subStageId;
  final PathIssueType issueType;
  final String message;

  const PathValidationIssue({
    required this.pathId,
    this.stageId,
    this.subStageId,
    required this.issueType,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
    'pathId': pathId,
    if (stageId != null) 'stageId': stageId,
    if (subStageId != null) 'subStageId': subStageId,
    'issueType': issueType.name,
    'message': message,
  };

  factory PathValidationIssue.fromJson(Map<String, dynamic> json) =>
      PathValidationIssue(
        pathId: json['pathId']?.toString() ?? '',
        stageId: json['stageId'] as String?,
        subStageId: json['subStageId'] as String?,
        issueType: PathIssueType.values.firstWhere(
          (e) => e.name == json['issueType'],
          orElse: () => PathIssueType.missingPack,
        ),
        message: json['message']?.toString() ?? '',
      );
}
