import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_ai_analyzer/widgets/poker_table_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cycles player action on double tap', (tester) async {
    final actions = [PlayerAction.none, PlayerAction.none];
    PlayerAction? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: PokerTableView(
          heroIndex: 0,
          playerCount: 2,
          playerNames: const ['A', 'B'],
          playerStacks: const [0.0, 0.0],
          playerActions: actions,
          onHeroSelected: (_) {},
          onStackChanged: (_, __) {},
          onNameChanged: (_, __) {},
          onActionChanged: (i, a) {
            actions[i] = a;
            changed = a;
          },
          potSize: 0,
          onPotChanged: (_) {},
        ),
      ),
    );

    await tester.pump();
    expect(find.text('F'), findsNothing);

    final finder = find.text('A');
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(finder);
    await tester.pump();

    expect(changed, PlayerAction.fold);
    expect(find.text('F'), findsOneWidget);
  });
}
