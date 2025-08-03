import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/services/pack_generator_service.dart';
import 'package:poker_analyzer/services/training_pack_template_ui_service.dart';
import 'package:poker_analyzer/utils/template_coverage_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ev coverage counters update', (tester) async {
    final range = PackGeneratorService.topNHands(25).take(12).toList();
    final spots = <TrainingPackSpot>[];
    for (var i = 0; i < 10; i++) {
      final acts = {
        0: [ActionEntry(0, 0, 'push', amount: 10, ev: i < 4 ? 1.0 : null)]
      };
      spots.add(
        TrainingPackSpot(
          id: 's$i',
          hand: HandData(
            heroCards: '',
            position: HeroPosition.sb,
            heroIndex: 0,
            playerCount: 2,
            stacks: const {'0': 10, '1': 10},
            actions: acts,
          ),
        ),
      );
    }
    final tpl = TrainingPackTemplate(
      id: 't',
      name: 't',
      spotCount: 12,
      playerStacksBb: const [10, 10],
      heroPos: HeroPosition.sb,
      heroRange: range,
      spots: spots,
    );
    expect(tpl.evCovered, 4);
    expect(tpl.icmCovered, 0);
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    })));
    const service = TrainingPackTemplateUiService();
    final generated = await service.generateMissingSpotsWithProgress(ctx, tpl);
    tpl.spots.addAll(generated);
    TemplateCoverageUtils.recountAll(tpl).applyTo(tpl.meta);
    expect(tpl.evCovered, 4 + generated.length);
  });
}
