import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/pack_generator_service.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/helpers/hand_utils.dart';
import 'package:poker_analyzer/services/training_pack_template_ui_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('generateMissingSpotsWithProgress adds missing hands', (
    tester,
  ) async {
    final range = PackGeneratorService.topNHands(25).toList();
    final initial = PackGeneratorService.generatePushFoldPackSync(
      id: 'i',
      name: 'i',
      heroBbStack: 10,
      playerStacksBb: const [10, 10],
      heroPos: HeroPosition.sb,
      heroRange: range.take(5).toList(),
    ).spots;
    final tpl = TrainingPackTemplate(
      id: 't',
      name: 't',
      spotCount: 8,
      playerStacksBb: const [10, 10],
      heroPos: HeroPosition.sb,
      heroRange: range,
      spots: List<TrainingPackSpot>.from(initial),
    );
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    const service = TrainingPackTemplateUiService();
    final future = service.generateMissingSpotsWithProgress(ctx, tpl);
    await tester.pumpAndSettle();
    final missing = await future;
    expect(missing.length, 3);
    final existing = {for (final s in initial) handCode(s.hand.heroCards)!};
    for (final s in missing) {
      final code = handCode(s.hand.heroCards)!;
      expect(existing.contains(code), isFalse);
    }
  });
}
