import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_variant.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/screens/v2/training_pack_template_list_screen.dart';
import 'package:poker_analyzer/screens/v2/training_pack_play_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('play button opens variant chooser', (tester) async {
    const variant1 = TrainingPackVariant(
      position: HeroPosition.btn,
      gameType: GameType.tournament,
      rangeId: 'test',
    );
    const variant2 = TrainingPackVariant(
      position: HeroPosition.sb,
      gameType: GameType.tournament,
      rangeId: 'test',
    );
    final template = TrainingPackTemplate(
      id: 't1',
      name: 'Test',
      spots: const [],
      meta: {
        'variants': [variant1.toJson(), variant2.toJson()],
      },
      createdAt: DateTime.now(),
    );
    SharedPreferences.setMockInitialValues({
      'training_pack_templates': jsonEncode([template.toJson()]),
    });
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TrainingSessionService(),
        child: const MaterialApp(home: TrainingPackTemplateListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();
    expect(find.text('BTN'), findsOneWidget);
    await tester.tap(find.text('BTN'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingPackPlayScreen), findsOneWidget);
  });
}
