import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/widgets/ev_summary_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders percent and toggles', (tester) async {
    bool toggled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: EvSummaryCard(
          values: const [1, -0.5, 0, 0.2],
          isIcm: false,
          onToggle: () => toggled = true,
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('+EV: 50'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.swap_horiz));
    expect(toggled, true);
  });
}
