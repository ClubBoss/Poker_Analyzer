import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/booster_theory_injector.dart';
import 'package:poker_analyzer/models/mistake_tag.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/widgets/theory_recap_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
  }

  testWidgets('shows recap when tag matches weakness', (tester) async {
    await pump(tester);
    final spot =
        TrainingPackSpot(id: 's1', hand: HandData(), tags: ['overfoldBtn']);
    const injector = BoosterTheoryInjector();
    await injector.maybeInject(
      tester.element(find.byType(SizedBox)),
      spot: spot,
      weakTags: [MistakeTag.overfoldBtn],
    );
    await tester.pump();
    expect(find.byType(TheoryRecapDialog), findsOneWidget);
  });

  testWidgets('respects cooldown per tag', (tester) async {
    await pump(tester);
    final spot =
        TrainingPackSpot(id: 's1', hand: HandData(), tags: ['overfoldBtn']);
    const injector = BoosterTheoryInjector();
    await injector.maybeInject(
      tester.element(find.byType(SizedBox)),
      spot: spot,
      weakTags: [MistakeTag.overfoldBtn],
    );
    await tester.pump();
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    await injector.maybeInject(
      tester.element(find.byType(SizedBox)),
      spot: spot,
      weakTags: [MistakeTag.overfoldBtn],
    );
    await tester.pump();
    expect(find.byType(TheoryRecapDialog), findsNothing);
  });
}
