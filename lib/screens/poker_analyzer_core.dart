import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/poker_analyzer_controller.dart';
import '../demo_controllable.dart';
import '../models/training_spot.dart';
import 'poker_analyzer_action_panel.dart';
import 'poker_analyzer_board_panel.dart';
import 'poker_analyzer_overlay.dart';

/// Primary poker analyzer screen.
///
/// Provides a [PokerAnalyzerController] to the widget subtree and composes the
/// high level panels responsible for board interaction, action controls and
/// overlays.
class PokerAnalyzerScreen extends StatefulWidget {
  const PokerAnalyzerScreen({super.key});

  @override
  PokerAnalyzerScreenState createState() => PokerAnalyzerScreenState();
}

class PokerAnalyzerScreenState extends State<PokerAnalyzerScreen>
    with DemoControllable {
  late final PokerAnalyzerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PokerAnalyzerController();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: const _PokerAnalyzerView(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void loadTrainingSpot(TrainingSpot spot) {
    _controller.loadSpot(spot);
  }

  @override
  void playAll() {
    // TODO: Implement playback control logic
  }

  @override
  void resolveWinner(Map<int, int> winnings) {
    // TODO: Implement winner resolution logic
  }
}

class _PokerAnalyzerView extends StatelessWidget {
  const _PokerAnalyzerView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
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
