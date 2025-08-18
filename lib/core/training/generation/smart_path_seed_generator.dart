import 'learning_path_library_generator.dart';
import 'learning_path_stage_template_generator.dart';

/// Utility generating stage templates from simple string descriptions.
class SmartPathSeedGenerator {
  final int minHands;
  final double requiredAccuracy;
  final Map<String, String> packIdMap;

  const SmartPathSeedGenerator({
    this.minHands = 10,
    this.requiredAccuracy = 80,
    this.packIdMap = const {},
  });

  /// Parses [lines] into a list of [LearningPathStageTemplateInput].
  /// Each line has format `stageId:A,B,C` where `A,B,C` are sub stages.
  List<LearningPathStageTemplateInput> generateFromStringList(
    List<String> lines,
  ) {
    final result = <LearningPathStageTemplateInput>[];
    String? prevStageId;

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      final parts = line.split(':');
      final stageId = parts.first.trim();
      final packId = packIdMap[stageId] ?? '${stageId}_main';
      final subTokens = parts.length > 1
          ? parts[1]
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : <String>[];

      final subStages = <SubStageTemplateInput>[];
      String? prevSubId;
      for (final token in subTokens) {
        final subId = '${stageId}_$token';
        final unlock = prevSubId == null
            ? null
            : UnlockConditionInput(dependsOn: prevSubId);
        subStages.add(
          SubStageTemplateInput(
            id: subId,
            packId: packId,
            title: token,
            description: '',
            minHands: minHands,
            requiredAccuracy: requiredAccuracy,
            unlockCondition: unlock,
          ),
        );
        prevSubId = subId;
      }

      final stageUnlock = prevStageId == null
          ? null
          : UnlockConditionInput(dependsOn: prevStageId);
      result.add(
        LearningPathStageTemplateInput(
          id: stageId,
          title: stageId,
          packId: packId,
          minHands: minHands,
          requiredAccuracy: requiredAccuracy,
          subStages: subStages,
          unlockCondition: stageUnlock,
        ),
      );
      prevStageId = stageId;
    }

    return result;
  }
}
