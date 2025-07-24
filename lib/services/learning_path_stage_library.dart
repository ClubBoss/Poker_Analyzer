import '../models/learning_path_stage_model.dart';

class LearningPathStageLibrary {
  LearningPathStageLibrary._();

  static final instance = LearningPathStageLibrary._();

  final List<LearningPathStageModel> _stages = [];
  final Map<String, LearningPathStageModel> _index = {};

  List<LearningPathStageModel> get stages => List.unmodifiable(_stages);

  void clear() {
    _stages.clear();
    _index.clear();
  }

  void add(LearningPathStageModel stage) {
    if (_index.containsKey(stage.id)) return;
    _stages.add(stage);
    _index[stage.id] = stage;
  }

  LearningPathStageModel? getById(String id) => _index[id];
}
