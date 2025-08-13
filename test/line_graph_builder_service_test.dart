import 'package:test/test.dart';
import 'package:poker_analyzer/services/line_graph_builder_service.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';

void main() {
  test('builder links lessons and spots into graph', () {
    final lessons = [
      TheoryMiniLessonNode(
          id: 'l1', title: '', content: '', tags: ['btn', 'flopCbet']),
      TheoryMiniLessonNode(
          id: 'l2', title: '', content: '', tags: ['btn', 'turnCheck']),
    ];
    final spot = TrainingPackSpot(
      id: 's1',
      hand: HandData(position: HeroPosition.btn),
      tags: ['flopCbet'],
      street: 1,
    );
    final builder = LineGraphBuilderService();
    final engine = builder.build(
      lessons: lessons,
      spots: [spot],
      lines: [
        ['flopCbet', 'turnCheck'],
      ],
    );

    final line = engine.getLine('flopCbet', 2);
    expect(line.length, 2);
    final start = line.first;
    expect(engine.findLinkedLessons(start).map((l) => l.id), contains('l1'));
    expect(engine.findLinkedPacks(start).map((s) => s.id), contains('s1'));
    final next = engine.findNextOptions(start);
    expect(next.length, 1);
    expect(
        engine.findLinkedLessons(next.first).map((l) => l.id), contains('l2'));
  });
}
