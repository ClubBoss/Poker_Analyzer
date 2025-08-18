import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/theory_recap_prompt_orchestrator.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/theory_booster_candidate_picker.dart';
import 'package:poker_analyzer/services/theory_reinforcement_queue_service.dart';
import 'package:poker_analyzer/services/theory_replay_cooldown_manager.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';

class _FakeQueue implements TheoryReinforcementQueueService {
  final List<TheoryMiniLessonNode> due;
  _FakeQueue(this.due);
  @override
  Future<void> registerSuccess(String lessonId) async {}
  @override
  Future<void> registerFailure(String lessonId) async {}
  @override
  Future<List<TheoryMiniLessonNode>> getDueLessons({
    int max = 3,
    MiniLessonLibraryService? library,
  }) async {
    return due.take(max).toList();
  }
}

class _FakePicker extends TheoryBoosterCandidatePicker {
  final List<TheoryMiniLessonNode> lessons;
  const _FakePicker(this.lessons);
  @override
  Future<List<TheoryMiniLessonNode>> getTopBoosterCandidates() async => lessons;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns due lesson when available', () async {
    final dueLesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: 'A',
      content: '',
    );
    final orch = TheoryRecapPromptOrchestrator(
      queue: _FakeQueue([dueLesson]),
      boosterPicker: const _FakePicker([]),
    );
    final result = await orch.pickRecapCandidate();
    expect(result?.id, 'l1');
  });

  test('skips cooldowned lesson and picks booster', () async {
    final dueLesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: 'A',
      content: '',
    );
    await TheoryReplayCooldownManager.markSuggested('l1');
    final booster = const TheoryMiniLessonNode(
      id: 'l2',
      title: 'B',
      content: '',
    );
    final orch = TheoryRecapPromptOrchestrator(
      queue: _FakeQueue([dueLesson]),
      boosterPicker: _FakePicker([booster]),
    );
    final result = await orch.pickRecapCandidate();
    expect(result?.id, 'l2');
  });

  test('does not repeat the same lesson in one session', () async {
    final lesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: 'A',
      content: '',
    );
    final orch = TheoryRecapPromptOrchestrator(
      queue: _FakeQueue([lesson]),
      boosterPicker: const _FakePicker([]),
    );
    final first = await orch.pickRecapCandidate();
    expect(first?.id, 'l1');
    final second = await orch.pickRecapCandidate();
    expect(second, isNull);
  });
}
