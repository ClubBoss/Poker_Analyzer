import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/scheduled_training_queue_service.dart';
import 'package:poker_analyzer/services/pack_library_service.dart';
import 'package:poker_analyzer/services/review_path_recommender.dart';
import 'package:poker_analyzer/services/skill_loss_detector.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLibrary implements PackLibraryService {
  final Map<String, TrainingPackTemplateV2> byTag;
  _FakeLibrary(this.byTag);
  @override
  Future<TrainingPackTemplateV2?> recommendedStarter() async => null;
  @override
  Future<TrainingPackTemplateV2?> getById(String id) async => byTag.values
      .firstWhere((p) => p.id == id, orElse: () => byTag.values.first);
  @override
  Future<TrainingPackTemplateV2?> findByTag(String tag) async => byTag[tag];
  @override
  Future<List<String>> findBoosterCandidates(String tag) async => const [];
}

TrainingPackTemplateV2 _tpl(String id, String tag) {
  return TrainingPackTemplateV2(
    id: id,
    name: id,
    trainingType: TrainingType.pushFold,
    gameType: GameType.tournament,
    tags: [tag],
    spots: const [],
    spotCount: 0,
    created: DateTime.now(),
    positions: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('autoSchedule queues recommended packs', () async {
    final queue = ScheduledTrainingQueueService();
    await queue.load();
    final library = _FakeLibrary({'a': _tpl('pa', 'a'), 'c': _tpl('pc', 'c')});
    await queue.autoSchedule(
      losses: [SkillLoss(tag: 'a', drop: 0.2, trend: '')],
      mistakeClusters: const [MistakeCluster(tag: 'c', count: 4)],
      goalMissRatesByTag: {'a': 0.5, 'c': 0.6},
      library: library,
    );
    expect(queue.queue, ['pa', 'pc']);
  });

  test('autoSchedule avoids duplicates', () async {
    final queue = ScheduledTrainingQueueService();
    await queue.load();
    final library = _FakeLibrary({'a': _tpl('pa', 'a')});
    await queue.add('pa');
    await queue.autoSchedule(
      losses: [SkillLoss(tag: 'a', drop: 0.3, trend: '')],
      mistakeClusters: const [],
      goalMissRatesByTag: {'a': 0.5},
      library: library,
    );
    expect(queue.queue, ['pa']);
  });
}
