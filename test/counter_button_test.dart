import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/widgets/counter_button.dart';

void main() {
  testWidgets('CounterButton increments counter on tap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CounterButton()));
    expect(find.text('Count: 0'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text('Count: 1'), findsOneWidget);
  });
}
