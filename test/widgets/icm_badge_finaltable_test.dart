import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/pack_generator_service.dart';
import 'package:poker_analyzer/widgets/v2/training_pack_spot_preview_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('icm badge reflects sign', (tester) async {
    final tpl = PackGeneratorService.generateFinalTablePack();
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
    final aa = find.widgetWithText(TrainingPackSpotPreviewCard, 'AA push');
    final k8 = find.widgetWithText(TrainingPackSpotPreviewCard, 'K8o push');
    final aaBadge = tester.widget<Container>(
      find.descendant(of: aa, matching: find.byKey(const ValueKey('icmBadge'))),
    );
    final k8Badge = tester.widget<Container>(
      find.descendant(of: k8, matching: find.byKey(const ValueKey('icmBadge'))),
    );
    final aaText = ((aaBadge.child as Text).data ?? '').toString();
    final k8Text = ((k8Badge.child as Text).data ?? '').toString();
    expect(aaText.startsWith('+'), true);
    expect(k8Text.startsWith('-'), true);
  });
}
