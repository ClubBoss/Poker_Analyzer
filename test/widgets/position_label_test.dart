import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/widgets/position_label.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows label text', (WidgetTester tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: PositionLabel(label: 'BTN', isHero: false)));
    expect(find.text('BTN'), findsOneWidget);
  });

  testWidgets('uses hero style', (WidgetTester tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: PositionLabel(label: 'BTN', isHero: true)));
    final text = tester.widget<Text>(find.text('BTN'));
    expect(text.style?.fontWeight, FontWeight.bold);
  });
}
