import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/poker_analyzer_controller.dart';
import 'poker_analyzer_action_panel.dart';
import 'poker_analyzer_board_panel.dart';
import 'poker_analyzer_overlay.dart';

/// Primary poker analyzer screen.
///
/// Provides a [PokerAnalyzerController] to the widget subtree and composes the
/// high level panels responsible for board interaction, action controls and
/// overlays.
class PokerAnalyzerScreen extends StatelessWidget {
  const PokerAnalyzerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PokerAnalyzerController(),
      child: const _PokerAnalyzerView(),
    );
  }
}

class _PokerAnalyzerView extends StatelessWidget {
  const _PokerAnalyzerView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: const [
              Expanded(child: PokerAnalyzerBoardPanel()),
              Expanded(child: PokerAnalyzerActionPanel()),
            ],
          ),
          // Overlay elements such as HUD, chip animations and debug UI.
          const PokerAnalyzerOverlay(),
        ],
      ),
    );
  }
}

