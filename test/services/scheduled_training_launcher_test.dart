import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/scheduled_training_launcher.dart';
import 'package:poker_analyzer/services/scheduled_training_queue_service.dart';
import 'package:poker_analyzer/services/pack_library_service.dart';
import 'package:poker_analyzer/services/training_session_launcher.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLibrary implements PackLibraryService {
  final Map<String, TrainingPackTemplateV2> packs;
  _FakeLibrary(this.packs);
  @override
  Future<TrainingPackTemplateV2?> recommendedStarter() async => null;
  @override
  Future<TrainingPackTemplateV2?> getById(String id) async => packs[id];
  @override
  Future<TrainingPackTemplateV2?> findByTag(String tag) async => null;
  @override
  Future<List<String>> findBoosterCandidates(String tag) async => const [];
}

class _FakeLauncher extends TrainingSessionLauncher {
  TrainingPackTemplateV2? launched;
  _FakeLauncher() : super();
  @override
  Future<void> launch(TrainingPackTemplateV2 template) async {
    launched = template;
  }
}

TrainingPackTemplateV2 _tpl(String id) {
  return TrainingPackTemplateV2(
    id: id,
    name: id,
    trainingType: TrainingType.pushFold,
    gameType: GameType.tournament,
    tags: ['tag'],
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

  testWidgets('launchNext starts queued pack', (tester) async {
    final queue = ScheduledTrainingQueueService.instance;
    await queue.load();
    await queue.add('p1');
    final library = _FakeLibrary({'p1': _tpl('p1')});
    final launcher = _FakeLauncher();
    final service = ScheduledTrainingLauncher(
      queue: queue,
      library: library,
      launcher: launcher,
    );
    final key = GlobalKey();
    await tester
        .pumpWidget(MaterialApp(home: Scaffold(body: Container(key: key))));
    await service.launchNext();
    expect(launcher.launched?.id, 'p1');
    expect(queue.queue.isEmpty, true);
  });
}
