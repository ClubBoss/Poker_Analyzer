import 'dart:async';

import '../models/training_spot.dart';
import '../services/training_import_export_service.dart';
import 'playback_manager_service.dart';
import 'board_manager_service.dart';
import 'pot_sync_service.dart';

/// Coordinates the demo playback sequence.
class DemoPlaybackController {
  DemoPlaybackController({
    required this.playbackManager,
    required this.boardManager,
    required this.importExportService,
    required this.potSync,
  });

  final PlaybackManagerService playbackManager;
  final BoardManagerService boardManager;
  final TrainingImportExportService importExportService;
  final PotSyncService potSync;

  void playSpot({
    required TrainingSpot spot,
    required void Function(TrainingSpot spot) loadSpot,
    required VoidCallback playAll,
    required void Function(Map<int, int> winnings) announceWinner,
  }) {
    loadSpot(spot);
    Future.delayed(const Duration(seconds: 1), () {
      playAll();
      void listener() {
        if (playbackManager.playbackIndex == spot.actions.length) {
          playbackManager.removeListener(listener);
          final pot = potSync.pots[boardManager.boardStreet];
          announceWinner({spot.heroIndex: pot});
        }
      }

      playbackManager.addListener(listener);
    });
  }

  /// Starts the demo using the provided callbacks for screen interaction.
  void startDemo({
    required void Function(TrainingSpot spot) loadSpot,
    required VoidCallback playAll,
    required void Function(Map<int, int> winnings) announceWinner,
  }) {
    final spot = TrainingSpot.fromJson(Map<String, dynamic>.from(_demoData));
    playSpot(
      spot: spot,
      loadSpot: loadSpot,
      playAll: playAll,
      announceWinner: announceWinner,
    );
  }

  /// Static demo spot data.
  static const Map<String, Object> _demoData = {
    'playerCards': [
      [
        {'rank': '9', 'suit': 'h'},
        {'rank': '9', 'suit': 'd'},
      ],
      [
        {'rank': 'T', 'suit': 's'},
        {'rank': 'T', 'suit': 'c'},
      ],
      [
        {'rank': 'J', 'suit': 'h'},
        {'rank': 'J', 'suit': 'd'},
      ],
      [
        {'rank': 'A', 'suit': 'h'},
        {'rank': 'K', 'suit': 'h'},
      ],
      [
        {'rank': 'Q', 'suit': 's'},
        {'rank': 'Q', 'suit': 'd'},
      ],
      [
        {'rank': '8', 'suit': 'c'},
        {'rank': '8', 'suit': 's'},
      ],
    ],
    'boardCards': [
      {'rank': '7', 'suit': 'h'},
      {'rank': '5', 'suit': 's'},
      {'rank': '2', 'suit': 'c'},
      {'rank': 'K', 'suit': 'd'},
      {'rank': '9', 'suit': 'd'},
    ],
    'actions': [
      {'street': 0, 'playerIndex': 0, 'action': 'fold'},
      {'street': 0, 'playerIndex': 1, 'action': 'fold'},
      {'street': 0, 'playerIndex': 2, 'action': 'fold'},
      {'street': 0, 'playerIndex': 3, 'action': 'raise', 'amount': 4},
      {'street': 0, 'playerIndex': 4, 'action': 'call', 'amount': 4},
      {'street': 0, 'playerIndex': 5, 'action': 'call', 'amount': 4},
      {'street': 1, 'playerIndex': 4, 'action': 'check'},
      {'street': 1, 'playerIndex': 5, 'action': 'check'},
      {'street': 1, 'playerIndex': 3, 'action': 'bet', 'amount': 6},
      {'street': 1, 'playerIndex': 4, 'action': 'call', 'amount': 6},
      {'street': 1, 'playerIndex': 5, 'action': 'fold'},
      {'street': 2, 'playerIndex': 4, 'action': 'check'},
      {'street': 2, 'playerIndex': 3, 'action': 'bet', 'amount': 12},
      {'street': 2, 'playerIndex': 4, 'action': 'call', 'amount': 12},
      {'street': 3, 'playerIndex': 4, 'action': 'check'},
      {'street': 3, 'playerIndex': 3, 'action': 'bet', 'amount': 24},
      {'street': 3, 'playerIndex': 4, 'action': 'call', 'amount': 24},
    ],
    'positions': ['UTG', 'HJ', 'CO', 'BTN', 'SB', 'BB'],
    'heroIndex': 3,
    'numberOfPlayers': 6,
    'stacks': [100, 100, 100, 100, 100, 100],
  };
}
