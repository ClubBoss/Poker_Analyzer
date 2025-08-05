import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/screens/mini_lesson_screen.dart';
import 'package:poker_analyzer/services/theory_recall_impact_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TheoryRecallImpactTracker.instance.init();
    TheoryRecallImpactTracker.instance.reset();
  });

  test('records lessons and groups by tag', () async {
    final tracker = TheoryRecallImpactTracker.instance;
    await tracker.record('a', 'l1');
    await tracker.record('a', 'l2');
    await tracker.record('b', 'l3');
    final map = tracker.tagToLessons;
    expect(map['a'], ['l1', 'l2']);
    expect(map['b'], ['l3']);
  });

  test('persists logs across sessions', () async {
    final tracker = TheoryRecallImpactTracker.instance;
    await tracker.record('tag', 'l1');
    tracker.reset();
    await tracker.init();
    expect(tracker.entries.length, 1);
    final entry = tracker.entries.first;
    expect(entry.tag, 'tag');
    expect(entry.lessonId, 'l1');
  });

  test('clear removes persisted logs', () async {
    final tracker = TheoryRecallImpactTracker.instance;
    await tracker.record('tag', 'l1');
    await tracker.clear();
    await tracker.init();
    expect(tracker.entries, isEmpty);
  });

  testWidgets('MiniLessonScreen logs lesson', (tester) async {
    const lesson = TheoryMiniLessonNode(
      id: 'l1',
      title: 'Intro',
      content: '',
      tags: [],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MiniLessonScreen(lesson: lesson, recapTag: 'tag1'),
      ),
    );
    expect(TheoryRecallImpactTracker.instance.tagToLessons['tag1'], ['l1']);
  });
}
