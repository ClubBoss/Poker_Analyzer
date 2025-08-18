import 'package:flutter/material.dart';

/// Renders the current board state for the poker analyzer.
///
/// Separated from [PokerAnalyzerBoardPanel] so that the visualisation can grow
/// independently from layout and styling concerns.
class PokerAnalyzerBoardDisplay extends StatelessWidget {
  const PokerAnalyzerBoardDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Board Panel', style: TextStyle(color: Colors.white)),
    );
  }
}
