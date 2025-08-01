import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/decay_heatmap_model_generator.dart';
import 'package:poker_analyzer/widgets/decay_heatmap_ui_surface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders entries as colored chips', (tester) async {
    final entries = [
      DecayHeatmapEntry(tag: 'A', decay: 10, level: DecayLevel.ok),
      DecayHeatmapEntry(tag: 'B', decay: 40, level: DecayLevel.warning),
      DecayHeatmapEntry(tag: 'C', decay: 70, level: DecayLevel.critical),
    ];
    await tester.pumpWidget(
      MaterialApp(home: DecayHeatmapUISurface(data: entries)),
    );
    await tester.pump();

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    final chips = tester.widgetList<Chip>(find.byType(Chip)).toList();
    expect(chips.length, 3);
  });
}
