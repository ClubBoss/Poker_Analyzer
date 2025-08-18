import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/pack_import_service.dart';
import 'package:poker_analyzer/widgets/v2/training_pack_spot_preview_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('handed badge appears', (tester) async {
    const csv =
        'Title,HeroPosition,HeroHand,StacksBB\nA,SB,AA,10/10/10/10/10\n';
    final tpl = PackImportService.importFromCsv(
      csv: csv,
      templateId: 't',
      templateName: 't',
    );
    await tester.pumpWidget(
      MaterialApp(home: TrainingPackSpotPreviewCard(spot: tpl.spots.first)),
    );
    await tester.pump();
    expect(find.text('5-handed'), findsOneWidget);
  });
}
