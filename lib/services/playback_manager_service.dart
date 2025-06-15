import 'package:flutter/foundation.dart';

import '../helpers/pot_calculator.dart';
import '../models/action_entry.dart';
import '../models/street_investments.dart';
import 'action_sync_service.dart';
import 'playback_service.dart';
import 'stack_manager_service.dart';

/// Manages playback state updates and delegates to [PlaybackService].
class PlaybackManagerService extends ChangeNotifier {
  final PlaybackService _playbackService;
  final List<ActionEntry> actions;
  StackManagerService stackService;
  final PotCalculator _potCalculator;
  final ActionSyncService actionSync;

  /// Current pot size for each street.
  final List<int> pots = List.filled(4, 0);

  /// Tracks which players have animated chips on each street.
  final Map<int, Set<int>> animatedPlayersPerStreet = {};

  int? lastActionPlayerIndex;

  PlaybackManagerService({
    PlaybackService? playbackService,
    required this.actions,
    required this.stackService,
    required this.actionSync,
    PotCalculator? potCalculator,
  })  : _playbackService = playbackService ?? PlaybackService(),
        _potCalculator = potCalculator ?? PotCalculator() {
    _playbackService.addListener(_onPlaybackChanged);
    actionSync.attachPlaybackManager(this);
  }

  int get playbackIndex => _playbackService.playbackIndex;
  bool get isPlaying => _playbackService.isPlaying;

  void startPlayback() => _playbackService.startPlayback(actions.length);

  void pausePlayback() => _playbackService.pausePlayback();

  void stepForward() => _playbackService.stepForward(actions.length);

  void stepBackward() => _playbackService.stepBackward();

  void seek(int index) => _playbackService.seek(index);

  void resetHand() {
    _playbackService.resetHand();
    actionSync.updatePlaybackIndex(_playbackService.playbackIndex);
    updatePlaybackState();
  }

  void updatePlaybackState() {
    final subset = actions.take(_playbackService.playbackIndex).toList();
    if (_playbackService.playbackIndex == 0) {
      animatedPlayersPerStreet.clear();
    }
    stackService.applyActions(subset);
    _updatePots(fromActions: subset);
    lastActionPlayerIndex =
        subset.isNotEmpty ? subset.last.playerIndex : null;
    notifyListeners();
  }

  void _updatePots({List<ActionEntry>? fromActions}) {
    final list = fromActions ?? actions;
    final investments = StreetInvestments();
    for (final a in list) {
      investments.addAction(a);
    }
    final pots = _potCalculator.calculatePots(list, investments);
    for (int i = 0; i < this.pots.length; i++) {
      this.pots[i] = pots[i];
    }
  }

  void _onPlaybackChanged() {
    actionSync.updatePlaybackIndex(_playbackService.playbackIndex);
    updatePlaybackState();
  }

  @override
  void dispose() {
    _playbackService
      ..removeListener(_onPlaybackChanged)
      ..dispose();
    super.dispose();
  }
}
