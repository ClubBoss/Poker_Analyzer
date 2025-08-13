import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/skill_map_booster_recommender.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
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

  test('returns weakest tags under threshold', () async {
    final mastery = _FakeMasteryService({'a': 0.5, 'b': 0.9, 'c': 0.4});
    final recommender = SkillMapBoosterRecommender();
    final result = await recommender.getWeakTags(
      mastery: mastery,
      maxTags: 2,
      threshold: 0.6,
    );
    expect(result, ['c', 'a']);
  });

  test('returns empty when no weak tags', () async {
    final mastery = _FakeMasteryService({'a': 0.8});
    final recommender = SkillMapBoosterRecommender();
    final result = await recommender.getWeakTags(mastery: mastery);
    expect(result, isEmpty);
  });
}
