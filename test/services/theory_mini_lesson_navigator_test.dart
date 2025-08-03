import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/main.dart' show navigatorKey;
import 'package:poker_analyzer/services/theory_mini_lesson_navigator.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/screens/mini_lesson_screen.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';

class _FakeLibrary implements MiniLessonLibraryService {
  final Map<String, TheoryMiniLessonNode> byTag;
  _FakeLibrary(this.byTag);

  @override
  List<TheoryMiniLessonNode> get all => byTag.values.toList();

  @override
  TheoryMiniLessonNode? getById(String id) =>
      all.firstWhere((e) => e.id == id, orElse: () => null);

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => [
        for (final t in tags)
          if (byTag[t] != null) byTag[t]!,
      ];

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => [
        for (final t in tags)
          if (byTag[t] != null) byTag[t]!,
      ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('opens lesson using provided context', (tester) async {
    const lesson =
        TheoryMiniLessonNode(id: 'l1', title: 'Intro', content: '', tags: ['t']);
    final library = _FakeLibrary({'t': lesson});
    final nav = TheoryMiniLessonNavigator(library: library);

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () => nav.openLessonByTag('t', ctx),
          child: const Text('open'),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(MiniLessonScreen), findsOneWidget);
  });

  testWidgets('opens lesson using global navigator when no context', (tester) async {
    const lesson =
        TheoryMiniLessonNode(id: 'l1', title: 'Intro', content: '', tags: ['t']);
    final library = _FakeLibrary({'t': lesson});
    final nav = TheoryMiniLessonNavigator(library: library);

    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      home: const SizedBox.shrink(),
    ));

    await nav.openLessonByTag('t');
    await tester.pumpAndSettle();
    expect(find.byType(MiniLessonScreen), findsOneWidget);
  });

  testWidgets('no-op when lesson not found', (tester) async {
    final library = _FakeLibrary({});
    final nav = TheoryMiniLessonNavigator(library: library);

    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      home: const SizedBox.shrink(),
    ));

    await nav.openLessonByTag('missing');
    await tester.pumpAndSettle();
    expect(find.byType(MiniLessonScreen), findsNothing);
  });
}

