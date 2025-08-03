import 'package:flutter/material.dart';

import 'poker_analyzer_action_panel.dart';
import 'poker_analyzer_board_panel.dart';
import 'poker_analyzer_overlay.dart';

/// Primary poker analyzer screen.
///
/// After refactoring, this widget is responsible solely for composing its
/// child widgets.  All state and game logic has been moved into dedicated
/// services, keeping the UI focused on layout.
class PokerAnalyzerScreen extends StatelessWidget {
  const PokerAnalyzerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: const [
          Row(
            children: [
              Expanded(child: PokerAnalyzerBoardPanel()),
              Expanded(child: PokerAnalyzerActionPanel()),
            ],
          ),
          // Overlay elements such as HUD, chip animations and debug UI.
          PokerAnalyzerOverlay(),
        ],
      ),
    );
  }
}
