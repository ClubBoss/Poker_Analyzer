import 'package:flutter/material.dart';
import '../models/player_model.dart';
import 'poker_analyzer_action_panel.dart';
import 'poker_analyzer_board_panel.dart';
import 'poker_analyzer_overlay.dart';

/// Primary poker analyzer screen.
///
/// This widget hosts the core state management and delegates UI pieces
/// to the action/board panels and overlay modules.
class PokerAnalyzerScreen extends StatefulWidget {
  const PokerAnalyzerScreen({super.key});

  @override
  PokerAnalyzerScreenState createState() => PokerAnalyzerScreenState();
}

/// Core state for [PokerAnalyzerScreen].
///
/// Only a tiny subset of the original implementation is preserved here to
/// keep the example lightweight while demonstrating the new modular
/// structure.  Services and complex logic from the original screen can be
/// reintroduced as needed.
class PokerAnalyzerScreenState extends State<PokerAnalyzerScreen> {
  /// Number of players at the table.
  int numberOfPlayers = 2;

  /// Mapping from player index to their table position (e.g. "BTN").
  final Map<int, String> playerPositions = {};

  /// Player type metadata keyed by player index.
  final Map<int, PlayerType> playerTypes = {};

  /// List of current players.  In the full application this would be managed
  /// by dedicated services; here it's only a placeholder to illustrate
  /// how the state object exposes information to the overlay widgets.
  final List<PlayerModel> players = [];

  /// Flag controlling display of debug information in the overlay.
  bool debugMode = false;

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
          PokerAnalyzerOverlay(state: this),
        ],
      ),
    );
  }
}
