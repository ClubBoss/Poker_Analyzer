import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/smart_theory_suggestion_engine.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/learning_path_stage_library.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/stage_type.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';

class _FakeMasteryService extends TagMasteryService {
  final Map<String, double> _map;
  _FakeMasteryService(this._map)
    : super(logs: SessionLogService(sessions: TrainingSessionService()));
  @override
  Future<Map<String, double>> computeMastery({bool force = false}) async =>
      _map;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('suggestMissingTheoryStages returns missing tags', () async {
    LearningPathStageLibrary.instance.clear();
    LearningPathStageLibrary.instance.add(
      const LearningPathStageModel(
        id: 'existing',
        title: 'Existing',
        description: '',
        packId: 'p1',
        requiredAccuracy: 0,
        minHands: 0,
        type: StageType.theory,
        tags: ['existing'],
      ),
    );

    final mastery = _FakeMasteryService({
      'missing': 0.2,
      'existing': 0.1,
      'strong': 0.8,
    });
    final engine = SmartTheorySuggestionEngine(mastery: mastery);
    final list = await engine.suggestMissingTheoryStages();

    expect(list, hasLength(1));
    expect(list.first.tag, 'missing');
  });
}
