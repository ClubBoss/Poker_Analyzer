import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/widgets/inline_theory_link_chip.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/inline_theory_linker.dart';
import 'package:poker_analyzer/services/theory_mini_lesson_navigator.dart';

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

class _FakeNavigator extends TheoryMiniLessonNavigator {
  String? openedTag;

  @override
  Future<void> openLessonByTag(String tag, [BuildContext? context]) async {
    openedTag = tag;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows chip and navigates via navigator', (tester) async {
    const lesson = TheoryMiniLessonNode(
      id: 'l1',
      title: 'Intro',
      content: '',
      tags: ['t'],
    );
    final library = _FakeLibrary({'t': lesson});
    final nav = _FakeNavigator();
    await tester.pumpWidget(
      MaterialApp(
        home: InlineTheoryLinkChip(
          theoryTag: 't',
          linker: InlineTheoryLinker(library: library, navigator: nav),
        ),
      ),
    );
    expect(find.byType(ActionChip), findsOneWidget);
    expect(find.text('Theory: Intro'), findsOneWidget);
    await tester.tap(find.byType(ActionChip));
    expect(nav.openedTag, 't');
  });

  testWidgets('renders nothing for missing tag', (tester) async {
    final library = _FakeLibrary({});
    await tester.pumpWidget(
      MaterialApp(
        home: InlineTheoryLinkChip(
          theoryTag: null,
          linker: InlineTheoryLinker(
            library: library,
            navigator: _FakeNavigator(),
          ),
        ),
      ),
    );
    expect(find.byType(ActionChip), findsNothing);
  });
}
