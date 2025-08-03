import '../models/learning_path_node_v2.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/learning_graph_engine.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/pack_library_service.dart';

class LearningPathLoadResult {
  final List<LearningPathNodeV2> nodes;
  final LearningPathNodeV2? current;
  final Map<String, TrainingPackTemplateV2> packs;

  LearningPathLoadResult({
    required this.nodes,
    required this.current,
    required this.packs,
  });
}

Future<LearningPathLoadResult> loadLearningPathData() async {
  await LearningPathEngine.instance.initialize();
  await MiniLessonLibraryService.instance.loadAll();
  final nodes = LearningPathEngine.instance
      .getAllNodes()
      .whereType<LearningPathNodeV2>()
      .toList();
  final current =
      LearningPathEngine.instance.getCurrentNode() as LearningPathNodeV2?;
  final packIds = <String>{};
  for (final n in nodes) {
    if (n.type == LearningPathNodeType.training &&
        n.trainingPackTemplateId != null) {
      packIds.add(n.trainingPackTemplateId!);
    }
  }
  final packs = <String, TrainingPackTemplateV2>{};
  for (final id in packIds) {
    final tpl = await PackLibraryService.instance.getById(id);
    if (tpl != null) packs[id] = tpl;
  }
  return LearningPathLoadResult(nodes: nodes, current: current, packs: packs);
}

