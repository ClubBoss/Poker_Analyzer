import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/pack_generator_service.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/widgets/v2/training_pack_spot_preview_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('badge colors reflect EV', (tester) async {
    final tpl = PackGeneratorService.generatePushFoldPackSync(
      id: 't',
      name: 't',
      heroBbStack: 10,
      playerStacksBb: [10, 10],
      heroPos: HeroPosition.sb,
      heroRange: ['A8s', 'Q4o'],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            for (final s in tpl.spots) TrainingPackSpotPreviewCard(spot: s),
          ],
        ),
      ),
    );
    await tester.pump();
    final badges = tester
        .widgetList<Container>(find.byKey(const ValueKey('evBadge')))
        .toList();
    expect((badges.first.decoration as BoxDecoration).color, Colors.green);
    expect((badges.last.decoration as BoxDecoration).color, Colors.red);
  });
}
