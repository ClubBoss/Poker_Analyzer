import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/booster_summary.dart';
import 'package:poker_analyzer/widgets/booster_feedback_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('lists boosters sorted by effectiveness', (tester) async {
    final summaries = [
      BoosterSummary(id: 'b1', avgDeltaEV: 0.02, totalSpots: 10, injections: 3),
      BoosterSummary(id: 'b2', avgDeltaEV: -0.01, totalSpots: 8, injections: 5),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: BoosterFeedbackWidget(
          summaries: summaries,
          namesById: const {'b1': 'Booster 1', 'b2': 'Booster 2'},
          sortByEffectiveness: true,
        ),
      ),
    );
    await tester.pump();
    final tiles = tester.widgetList<Text>(find.byType(Text)).toList();
    expect(tiles.where((t) => t.data == 'Booster 1').length, 1);
    expect(tiles.where((t) => t.data == 'Booster 2').length, 1);
    final firstText = (tiles.firstWhere((t) => t.data == 'Booster 1')).data;
    expect(firstText, 'Booster 1');
  });
}
