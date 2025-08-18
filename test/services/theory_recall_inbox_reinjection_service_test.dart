import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/inbox_booster_tracker_service.dart';
import 'package:poker_analyzer/services/theory_booster_recall_engine.dart';
import 'package:poker_analyzer/services/theory_recall_inbox_reinjection_service.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/theory_prompt_dismiss_tracker.dart';
import 'package:poker_analyzer/services/inbox_booster_service.dart';

class _FakeLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> lessons;
  _FakeLibrary(this.lessons);
  @override
  List<TheoryMiniLessonNode> get all => lessons;
  @override
  Future<void> loadAll() async {}
  @override
  Future<void> reload() async {}
  @override
  TheoryMiniLessonNode? getById(String id) =>
      lessons.firstWhere((l) => l.id == id, orElse: () => null);
  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => [];
  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    InboxBoosterTrackerService.instance.resetForTest();
    TheoryBoosterRecallEngine.instance.resetForTest();
    TheoryPromptDismissTracker.instance.resetForTest();
  });

  test('reinjects oldest dismissed booster to inbox', () async {
    final lessons = [
      const TheoryMiniLessonNode(id: 'l1', title: 'L1', content: ''),
      const TheoryMiniLessonNode(id: 'l2', title: 'L2', content: ''),
    ];
    final engine = TheoryBoosterRecallEngine(library: _FakeLibrary(lessons));
    final old1 = DateTime.now().subtract(const Duration(days: 5));
    final old2 = DateTime.now().subtract(const Duration(days: 4));
    await engine.recordSuggestion('l1', timestamp: old1);
    await engine.recordSuggestion('l2', timestamp: old2);
    await TheoryPromptDismissTracker.instance.markDismissed(
      'l1',
      timestamp: old1,
    );
    await TheoryPromptDismissTracker.instance.markDismissed(
      'l2',
      timestamp: old2,
    );

    final inbox = InboxBoosterService(
      tracker: InboxBoosterTrackerService.instance,
    );
    final service = TheoryRecallInboxReinjectionService(
      recall: engine,
      inbox: inbox,
      cooldown: const Duration(days: 3),
    );
    await service.start();

    final queue = await InboxBoosterTrackerService.instance.getInbox();
    expect(queue, ['l1']);
  });
}
