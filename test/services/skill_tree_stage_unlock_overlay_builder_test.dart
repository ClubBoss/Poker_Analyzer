import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/skill_tree_stage_unlock_overlay_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = SkillTreeStageUnlockOverlayBuilder();

  testWidgets('locked stage shows lock icon', (tester) async {
    final overlay = builder.buildOverlay(
      level: 1,
      isUnlocked: false,
      isCompleted: false,
    );
    await tester.pumpWidget(MaterialApp(home: Stack(children: [overlay])));
    expect(find.byIcon(Icons.lock), findsOneWidget);
  });

  testWidgets('completed stage shows check icon', (tester) async {
    final overlay = builder.buildOverlay(
      level: 1,
      isUnlocked: true,
      isCompleted: true,
    );
    await tester.pumpWidget(MaterialApp(home: Stack(children: [overlay])));
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
