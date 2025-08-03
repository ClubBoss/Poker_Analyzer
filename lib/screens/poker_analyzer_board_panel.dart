import 'package:flutter/material.dart';

import '../widgets/poker_analyzer_board_display.dart';

/// Panel responsible for board editing and visualization.
class PokerAnalyzerBoardPanel extends StatelessWidget {
  const PokerAnalyzerBoardPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green.shade800,
      child: const PokerAnalyzerBoardDisplay(),
    );
  }
}
