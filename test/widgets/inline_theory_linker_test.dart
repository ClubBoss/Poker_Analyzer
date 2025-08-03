import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/widgets/inline_theory_linker.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/screens/mini_lesson_screen.dart';

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

  testWidgets('shows chip and triggers callback', (tester) async {
    const lesson = TheoryMiniLessonNode(id: 'l1', title: 'Intro', content: '', tags: ['t']);
    final library = _FakeLibrary({'t': lesson});
    TheoryMiniLessonNode? tapped;
    await tester.pumpWidget(MaterialApp(
      home: InlineTheoryLinker(
        theoryTag: 't',
        library: library,
        onTap: (l) => tapped = l,
      ),
    ));
    expect(find.byType(ActionChip), findsOneWidget);
    expect(find.text('Theory: Intro'), findsOneWidget);
    await tester.tap(find.byType(ActionChip));
    expect(tapped, lesson);
  });

  testWidgets('navigates to lesson screen by default', (tester) async {
    const lesson = TheoryMiniLessonNode(id: 'l1', title: 'Intro', content: '', tags: ['t']);
    final library = _FakeLibrary({'t': lesson});
    await tester.pumpWidget(MaterialApp(
      home: InlineTheoryLinker(
        theoryTag: 't',
        library: library,
      ),
    ));
    await tester.tap(find.byType(ActionChip));
    await tester.pumpAndSettle();
    expect(find.byType(MiniLessonScreen), findsOneWidget);
  });

  testWidgets('renders nothing for missing tag', (tester) async {
    final library = _FakeLibrary({});
    await tester.pumpWidget(const MaterialApp(
      home: InlineTheoryLinker(theoryTag: null),
    ));
    expect(find.byType(ActionChip), findsNothing);
  });
}
