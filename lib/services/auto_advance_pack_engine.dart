import 'package:collection/collection.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'learning_path_progress_service.dart';
import 'pack_library_service.dart';

/// Provides the next training pack along the learning path.
class AutoAdvancePackEngine {
  AutoAdvancePackEngine._();
  static final instance = AutoAdvancePackEngine._();

  /// When true, templates are taken from [_mockTemplates] instead of assets.
  bool mock = false;
  final Map<String, TrainingPackTemplateV2> _mockTemplates = {};

  /// Registers a template used when [mock] is true.
  void registerMockTemplate(TrainingPackTemplateV2 tpl) {
    _mockTemplates[tpl.id] = tpl;
  }

  /// Clears all registered mock templates.
  void resetMock() => _mockTemplates.clear();

  /// Returns the next recommended training pack or `null` if all are done.
  Future<TrainingPackTemplateV2?> getNextRecommendedPack() async {
    final stages = await LearningPathProgressService.instance
        .getCurrentStageState();
    final activeStage = stages.firstWhereOrNull(
      (s) => !LearningPathProgressService.instance.isStageCompleted(s.items),
    );
    if (activeStage == null) return null;
    final item = activeStage.items.firstWhereOrNull(
      (i) => i.templateId != null && i.status != LearningItemStatus.completed,
    );
    if (item == null || item.templateId == null) return null;
    final id = item.templateId!;
    if (mock) return _mockTemplates[id];
    return PackLibraryService.instance.getById(id);
  }
}
