import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/screens/skill_tree_track_launcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows intro when track not started', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SkillTreeTrackLauncher(trackId: 't1'),
    ));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump();
    // After future completes, should show intro screen widget
    expect(find.byType(SkillTreeTrackLauncher), findsOneWidget);
    expect(find.text('Начать'), findsOneWidget);
  });

  testWidgets('shows path when track started', (tester) async {
    SharedPreferences.setMockInitialValues({'skill_track_started_t2': true});
    await tester.pumpWidget(const MaterialApp(
      home: SkillTreeTrackLauncher(trackId: 't2'),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.byType(SkillTreeTrackLauncher), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
