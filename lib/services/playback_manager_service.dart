import 'package:flutter/foundation.dart';

import '../models/action_entry.dart';
import 'action_sync_service.dart';
import 'playback_service.dart';
import 'stack_manager_service.dart';
import 'pot_sync_service.dart';

/// Manages playback state updates and delegates to [PlaybackService].
class PlaybackManagerService extends ChangeNotifier {
  final PlaybackService _playbackService;
  final List<ActionEntry> actions;
  StackManagerService stackService;
  final PotSyncService potSync;
  final ActionSyncService actionSync;

  /// Current pot size for each street, mirrored from [potSync].
  final List<int> pots = List.filled(4, 0);

  /// Tracks which players have animated chips on each street.
  final Map<int, Set<int>> animatedPlayersPerStreet = {};

  int? lastActionPlayerIndex;

  PlaybackManagerService({
    PlaybackService? playbackService,
    required this.actions,
    required this.stackService,
    required this.potSync,
    required this.actionSync,
  })  : _playbackService = playbackService ?? PlaybackService() {
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
    // Stack sizes are synchronized via [ActionSyncService].
    potSync.updatePots(subset);
    for (int i = 0; i < pots.length; i++) {
      pots[i] = potSync.pots[i];
    }
    lastActionPlayerIndex =
        subset.isNotEmpty ? subset.last.playerIndex : null;
    notifyListeners();
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
