import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/smart_theory_recap_engine.dart';
import 'package:poker_analyzer/services/smart_theory_booster_linker.dart';

class _StubLinker extends SmartTheoryBoosterLinker {
  final String? lessonLink;
  final String? tagLink;
  const _StubLinker({this.lessonLink});
  @override
  Future<String?> linkForLesson(String lessonId) async => lessonLink;
  @override
  Future<String?> linkForTags(List<String> tags) async => tagLink;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('getLink prefers lesson link', () async {
    const linker = _StubLinker(lessonLink: '/theory/cluster?clusterId=x');
    final engine = SmartTheoryRecapEngine(linker: linker);
    final link = await engine.getLink(lessonId: 'l1', tags: ['a']);
    expect(link, '/theory/cluster?clusterId=x');
  });

  testWidgets('maybePrompt stores dismissal', (tester) async {
    const linker = _StubLinker(lessonLink: '/theory/cluster?clusterId=x');
    final engine = SmartTheoryRecapEngine(linker: linker);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await engine.maybePrompt(lessonId: 'l1');
    await tester.pump();
    expect(find.text('Want to review related theory?'), findsOneWidget);
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('smart_theory_recap_dismissed'), isNotNull);
  });
}
