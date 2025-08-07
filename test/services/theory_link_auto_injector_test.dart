import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/hand_data.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/theory_link_auto_injector.dart';

void main() {
  group('TheoryLinkAutoInjector', () {
    test('injects matching lessons with tag overlap', () {
      final spot = TrainingPackSpot(
        id: 's1',
        hand: HandData(),
        tags: ['openSB', 'early'],
      );
      final lessons = [
        TheoryMiniLessonNode(
          id: 'l1',
          title: 'SB',
          content: '',
          tags: ['openSB'],
        ),
        TheoryMiniLessonNode(
          id: 'l2',
          title: 'Early',
          content: '',
          tags: ['early'],
        ),
      ];
      const injector = TheoryLinkAutoInjector();

      injector.injectAll([spot], lessons);

      expect(spot.theoryRefs, ['l1', 'l2']);
    });

    test('respects max link limit', () {
      final spot = TrainingPackSpot(id: 's1', hand: HandData(), tags: ['t']);
      final lessons = [
        TheoryMiniLessonNode(id: 'l1', title: 'A', content: '', tags: ['t']),
        TheoryMiniLessonNode(id: 'l2', title: 'B', content: '', tags: ['t']),
        TheoryMiniLessonNode(id: 'l3', title: 'C', content: '', tags: ['t']),
      ];
      const injector = TheoryLinkAutoInjector(maxLinks: 2);

      injector.injectAll([spot], lessons);

      expect(spot.theoryRefs.length, 2);
    });

    test('strict mode requires full tag match', () {
      final spot = TrainingPackSpot(
        id: 's1',
        hand: HandData(),
        tags: ['a', 'b'],
      );
      final lessons = [
        TheoryMiniLessonNode(id: 'l1', title: 'A', content: '', tags: ['a']),
        TheoryMiniLessonNode(
          id: 'l2',
          title: 'AB',
          content: '',
          tags: ['a', 'b'],
        ),
      ];
      const injector = TheoryLinkAutoInjector(strict: true);

      injector.injectAll([spot], lessons);

      expect(spot.theoryRefs, ['l2']);
    });
  });
}
