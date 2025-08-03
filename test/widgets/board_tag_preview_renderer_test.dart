import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/card_model.dart';
import 'package:poker_analyzer/widgets/board_tag_preview_renderer.dart';

void main() {
  testWidgets('renders board tags', (tester) async {
    final board = [
      CardModel(rank: 'A', suit: '♠'),
      CardModel(rank: 'A', suit: '♥'),
      CardModel(rank: '9', suit: '♦'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BoardTagPreviewRenderer(board: board)),
      ),
    );

    expect(find.text('paired'), findsOneWidget);
    expect(find.text('rainbow'), findsOneWidget);
    expect(find.text('aceHigh'), findsOneWidget);
    expect(find.text('wet'), findsOneWidget);
  });
}
