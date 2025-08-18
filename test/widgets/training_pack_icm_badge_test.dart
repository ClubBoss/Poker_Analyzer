import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/pack_generator_service.dart';
import 'package:poker_analyzer/widgets/v2/training_pack_spot_preview_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('icm badge colors', (tester) async {
    final tpl = PackGeneratorService.generateFinalTablePack();
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            for (final s in tpl.spots.take(10))
              TrainingPackSpotPreviewCard(spot: s),
          ],
        ),
      ),
    );
    await tester.pump();
    final icmBadges = tester
        .widgetList<Container>(find.byKey(const ValueKey('icmBadge')))
        .toList();
    expect(icmBadges.isNotEmpty, true);
    final first = (icmBadges.first.decoration as BoxDecoration).color;
    final last = (icmBadges.last.decoration as BoxDecoration).color;
    expect(first, Colors.purple);
    expect(last, Colors.purple);
  });
}
