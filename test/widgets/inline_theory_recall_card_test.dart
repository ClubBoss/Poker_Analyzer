import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/widgets/inline_theory_recall_card.dart';
import 'package:poker_analyzer/models/theory_snippet.dart';

void main() {
  testWidgets('recall card renders and dismisses on tap', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: InlineTheoryRecallCard(
          snippet: const TheorySnippet(id: '1', title: 'T', bullets: ['b']),
          onDismiss: () => dismissed = true,
        ),
      ),
    );
    expect(find.text('T'), findsOneWidget);
    await tester.tap(find.byType(InlineTheoryRecallCard));
    await tester.pumpAndSettle();
    expect(dismissed, isTrue);
  });

  testWidgets('recall card auto dismiss after 12s', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: InlineTheoryRecallCard(
          snippet: const TheorySnippet(id: '1', title: 'T', bullets: ['b']),
          onDismiss: () => dismissed = true,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 12));
    expect(dismissed, isTrue);
  });
}
