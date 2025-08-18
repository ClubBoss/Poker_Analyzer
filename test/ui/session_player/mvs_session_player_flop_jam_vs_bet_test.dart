import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/ui/session_player/mvs_player.dart';
import 'package:poker_analyzer/ui/session_player/models.dart';

void main() {
  testWidgets('renders Flop Jam vs Bet spot', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final spot = UiSpot(
      kind: SpotKind.l3_flop_jam_vs_bet,
      hand: 'A\\u2660K\\u2660',
      pos: 'BTN',
      stack: '20bb',
      vsPos: 'BB',
      action: 'jam',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MvsSessionPlayer(spots: [spot])),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Flop Jam vs Bet'), findsOneWidget);
    expect(find.text('jam'), findsOneWidget);
    expect(find.text('fold'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNWidgets(2));
  });
}
