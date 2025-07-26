import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/booster_preview_launcher.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/main.dart';
import 'package:poker_analyzer/screens/training_session_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launch starts session and opens screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final tpl = TrainingPackTemplateV2(
      id: 'b',
      name: 'Booster',
      trainingType: TrainingType.pushFold,
      gameType: GameType.tournament,
      spots: const [TrainingPackSpot(id: 's')],
      spotCount: 1,
      created: DateTime.now(),
      positions: const [],
    );
    final service = TrainingSessionService();
    final key = GlobalKey();
    await tester.pumpWidget(
      ChangeNotifierProvider<TrainingSessionService>.value(
        value: service,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: Scaffold(body: Container(key: key)),
        ),
      ),
    );
    await const BoosterPreviewLauncher().launch(key.currentContext!, tpl);
    await tester.pumpAndSettle();
    expect(service.session?.templateId, tpl.id);
    expect(find.byType(TrainingSessionScreen), findsOneWidget);
  });
}
