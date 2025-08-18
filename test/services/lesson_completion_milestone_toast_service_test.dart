import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/lesson_completion_milestone_toast_service.dart';

void main() {
  testWidgets('shows milestone toast only once per day', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );
    final context = tester.element(find.byType(SizedBox));

    await LessonCompletionMilestoneToastService.instance.showIfMilestoneReached(
      context,
      1,
    );
    await tester.pump();
    expect(find.text('Nice start!'), findsOneWidget);

    await LessonCompletionMilestoneToastService.instance.showIfMilestoneReached(
      context,
      1,
    );
    await tester.pump();
    expect(find.text('Nice start!'), findsOneWidget);
  });
}
