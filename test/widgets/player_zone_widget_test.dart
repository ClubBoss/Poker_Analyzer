import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/player_model.dart';
import 'package:poker_analyzer/widgets/analyzer/player_zone_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PlayerAvatar shows player name', (WidgetTester tester) async {
    final player = PlayerModel(name: 'Alice', stack: 100, bet: 0);
    await tester
        .pumpWidget(MaterialApp(home: PlayerZoneWidget(player: player)));
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('PlayerStackDisplay shows stack and bet',
      (WidgetTester tester) async {
    final player = PlayerModel(name: 'Bob', stack: 50, bet: 20);
    await tester
        .pumpWidget(MaterialApp(home: PlayerZoneWidget(player: player)));
    expect(find.text('50 BB'), findsOneWidget);
    expect(find.text('Bet 20'), findsOneWidget);
  });

  testWidgets('PlayerStatusIndicator shows folded and all-in',
      (WidgetTester tester) async {
    final player = PlayerModel(name: 'Chris', stack: 100, bet: 0);
    await tester.pumpWidget(
        MaterialApp(home: PlayerZoneWidget(player: player, isFolded: true)));
    expect(find.text('FOLDED'), findsOneWidget);

    await tester.pumpWidget(
        MaterialApp(home: PlayerZoneWidget(player: player, isAllIn: true)));
    await tester.pump();
    expect(find.text('ALL-IN'), findsOneWidget);
  });

  testWidgets('onEdit and onRemove callbacks fire',
      (WidgetTester tester) async {
    final player = PlayerModel(name: 'Dave', stack: 100, bet: 0);
    var editCalled = false;
    var removeCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PlayerZoneWidget(
          player: player,
          onEdit: () => editCalled = true,
          onRemove: () => removeCalled = true,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();
    expect(editCalled, isTrue);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(removeCalled, isTrue);
  });
}
