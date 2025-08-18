import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/evaluation_result.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/booster_slot_allocator.dart';
import 'package:poker_analyzer/services/inbox_booster_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    InboxBoosterTrackerService.instance.resetForTest();
  });

  test('recently shown booster skipped', () async {
    await InboxBoosterTrackerService.instance.markShown('l1');
    final allocator = BoosterSlotAllocator();
    final lesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: '',
      content: '',
      tags: ['icm'],
    );
    final spot = TrainingPackSpot(id: 's1', tags: ['icm']);
    final slot = await allocator.decideSlot(lesson, spot);
    expect(slot, BoosterSlot.none);
  });

  test('critical mistake goes to recap', () async {
    final allocator = BoosterSlotAllocator();
    final lesson = const TheoryMiniLessonNode(
      id: 'l2',
      title: '',
      content: '',
      tags: ['cbet'],
    );
    final spot = TrainingPackSpot(
      id: 's2',
      tags: ['cbet'],
      priority: 1,
      evalResult: EvaluationResult(
        correct: false,
        expectedAction: '-',
        userEquity: 0,
        expectedEquity: 0,
        ev: -1.5,
      ),
    );
    final slot = await allocator.decideSlot(lesson, spot);
    expect(slot, BoosterSlot.recap);
  });

  test('missed but relevant goes to inbox', () async {
    final allocator = BoosterSlotAllocator();
    final lesson = const TheoryMiniLessonNode(
      id: 'l3',
      title: '',
      content: '',
      tags: ['postflop'],
    );
    final spot = TrainingPackSpot(
      id: 's3',
      tags: ['postflop'],
      evalResult: EvaluationResult(
        correct: false,
        expectedAction: '-',
        userEquity: 0,
        expectedEquity: 0,
        ev: -0.2,
      ),
    );
    final slot = await allocator.decideSlot(lesson, spot);
    expect(slot, BoosterSlot.inbox);
  });

  test('medium priority suggested via goal', () async {
    final allocator = BoosterSlotAllocator();
    final lesson = const TheoryMiniLessonNode(
      id: 'l4',
      title: '',
      content: '',
      tags: ['preflop'],
    );
    final spot = TrainingPackSpot(id: 's4', tags: ['preflop'], priority: 2);
    final slot = await allocator.decideSlot(lesson, spot);
    expect(slot, BoosterSlot.goal);
  });

  test('irrelevant lesson returns none', () async {
    final allocator = BoosterSlotAllocator();
    final lesson = const TheoryMiniLessonNode(
      id: 'l5',
      title: '',
      content: '',
      tags: ['river'],
    );
    final spot = TrainingPackSpot(id: 's5', tags: ['turn']);
    final slot = await allocator.decideSlot(lesson, spot);
    expect(slot, BoosterSlot.none);
  });
}
