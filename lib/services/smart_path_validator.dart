import '../models/learning_path_template_v2.dart';
import '../models/path_validation_issue.dart';

class SmartPathValidator {
  const SmartPathValidator();

  List<PathValidationIssue> validateAll(List<LearningPathTemplateV2> paths) {
    final issues = <PathValidationIssue>[];
    for (final path in paths) {
      final stageIds = <String>{};
      final subStageIds = <String>{};
      final orders = <int>[];
      final sectionStages = <String>{
        for (final s in path.sections) ...s.stageIds,
      };

      for (final stage in path.stages) {
        if (!stageIds.add(stage.id)) {
          issues.add(
            PathValidationIssue(
              pathId: path.id,
              stageId: stage.id,
              issueType: PathIssueType.duplicateId,
              message: 'duplicate stage id',
            ),
          );
        }
        if (stage.packId.trim().isEmpty) {
          issues.add(
            PathValidationIssue(
              pathId: path.id,
              stageId: stage.id,
              issueType: PathIssueType.missingPack,
              message: 'missing packId',
            ),
          );
        }
        if (stage.title.trim().isEmpty) {
          issues.add(
            PathValidationIssue(
              pathId: path.id,
              stageId: stage.id,
              issueType: PathIssueType.unlinkedStage,
              message: 'missing title',
            ),
          );
        }
        orders.add(stage.order);
        final cond = stage.unlockCondition;
        if (cond?.dependsOn != null) {
          final dep = cond!.dependsOn!;
          if (!stageIds.contains(dep) && !subStageIds.contains(dep)) {
            issues.add(
              PathValidationIssue(
                pathId: path.id,
                stageId: stage.id,
                issueType: PathIssueType.unlinkedStage,
                message: 'bad unlock reference: $dep',
              ),
            );
          }
        }
        for (final sub in stage.subStages) {
          if (!subStageIds.add(sub.id)) {
            issues.add(
              PathValidationIssue(
                pathId: path.id,
                stageId: stage.id,
                subStageId: sub.id,
                issueType: PathIssueType.duplicateId,
                message: 'duplicate subStage id',
              ),
            );
          }
          if (sub.packId.trim().isEmpty) {
            issues.add(
              PathValidationIssue(
                pathId: path.id,
                stageId: stage.id,
                subStageId: sub.id,
                issueType: PathIssueType.missingPack,
                message: 'missing packId',
              ),
            );
          }
          final sc = sub.unlockCondition;
          if (sc?.dependsOn != null) {
            final dep = sc!.dependsOn!;
            if (!stageIds.contains(dep) && !subStageIds.contains(dep)) {
              issues.add(
                PathValidationIssue(
                  pathId: path.id,
                  stageId: stage.id,
                  subStageId: sub.id,
                  issueType: PathIssueType.unlinkedStage,
                  message: 'bad unlock reference: $dep',
                ),
              );
            }
          }
        }
      }

      if (orders.isNotEmpty) {
        final sorted = List<int>.from(orders)..sort();
        for (var i = 0; i < sorted.length; i++) {
          final expected = sorted.first + i;
          if (sorted[i] != expected) {
            issues.add(
              PathValidationIssue(
                pathId: path.id,
                issueType: PathIssueType.invalidStageOrder,
                message: 'order values should be sequential',
              ),
            );
            break;
          }
        }
      }

      for (final id in stageIds) {
        if (!sectionStages.contains(id)) {
          issues.add(
            PathValidationIssue(
              pathId: path.id,
              stageId: id,
              issueType: PathIssueType.unlinkedStage,
              message: 'stage not in any section',
            ),
          );
        }
      }
    }
    return issues;
  }
}
