import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/theory_booster_training_launcher.dart';
import 'package:poker_analyzer/services/theory_booster_queue_service.dart';
import 'package:poker_analyzer/services/theory_training_launcher.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/user_action_logger.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/theory_pack_model.dart';

class _FakeLauncher extends TheoryTrainingLauncher {
  TheoryPackModel? launched;
  const _FakeLauncher();
  @override
  Future<void> launch(TheoryPackModel pack) async {
    launched = pack;
  }
}

class _FakeLibrary implements MiniLessonLibraryService {
  final Map<String, List<TheoryMiniLessonNode>> lessons;
  int loadCount = 0;
  _FakeLibrary(this.lessons);

  @override
  List<TheoryMiniLessonNode> get all => [for (final l in lessons.values) ...l];

  @override
  TheoryMiniLessonNode? getById(String id) =>
      all.firstWhere((e) => e.id == id, orElse: () => null);

  @override
  Future<void> loadAll() async {
    loadCount++;
  }

  @override
  Future<void> reload() async {}

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) {
    final result = <TheoryMiniLessonNode>[];
    for (final t in tags) {
      result.addAll(lessons[t] ?? const []);
    }
    return result;
  }

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserActionLogger.instance.load();
    TheoryBoosterQueueService.instance.clear();
  });

  test('launch builds pack and clears queue', () async {
    final l1 = const TheoryMiniLessonNode(
      id: 'l1',
      title: 'A',
      content: '',
      tags: ['a'],
    );
    final l2 = const TheoryMiniLessonNode(
      id: 'l2',
      title: 'B',
      content: '',
      tags: ['b'],
    );
    final library = _FakeLibrary({
      'a': [l1],
      'b': [l2],
    });
    await TheoryBoosterQueueService.instance.enqueue('a');
    await TheoryBoosterQueueService.instance.enqueue('b');
    final launcher = _FakeLauncher();
    final service = TheoryBoosterTrainingLauncher(
      queue: TheoryBoosterQueueService.instance,
      library: library,
      launcher: launcher,
    );
    await service.launch();
    expect(launcher.launched?.sections.length, 2);
    expect(TheoryBoosterQueueService.instance.getQueue(), isEmpty);
    expect(library.loadCount, 1);
    expect(
      UserActionLogger.instance.events.last['event'],
      'theory_booster_launched',
    );
  });
}
