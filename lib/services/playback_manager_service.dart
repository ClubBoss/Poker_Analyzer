import 'package:flutter/foundation.dart';

import 'action_sync_service.dart';
import 'playback_service.dart';
import 'stack_manager_service.dart';
import 'pot_sync_service.dart';
import '../models/saved_hand.dart';

/// Manages playback state updates and delegates to [PlaybackService].
class PlaybackManagerService extends ChangeNotifier {
  final PlaybackService _playbackService;
  StackManagerService stackService;
  final PotSyncService potSync;
  final ActionSyncService actionSync;

  /// Current pot size for each street, mirrored from [potSync].
  final List<int> pots = List.filled(4, 0);

  /// Tracks which players have animated chips on each street.
  final Map<int, Set<int>> animatedPlayersPerStreet = {};

  /// Players that should animate on the next frame for each street.
  final Map<int, Set<int>> _pendingAnimations = {};

  int? lastActionPlayerIndex;

  PlaybackManagerService({
    PlaybackService? playbackService,
    required this.stackService,
    required this.potSync,
    required this.actionSync,
  }) : _playbackService = playbackService ?? PlaybackService() {
    _playbackService.addListener(_onPlaybackChanged);
    actionSync.attachPlaybackManager(this);
  }

  int get playbackIndex => _playbackService.playbackIndex;
  bool get isPlaying => _playbackService.isPlaying;
  Duration get elapsedTime => _playbackService.elapsedTime;

  /// Returns `true` if the [playerIndex] should animate for [street].
  bool shouldAnimatePlayer(int street, int playerIndex) {
    final set = _pendingAnimations[street];
    if (set != null && set.remove(playerIndex)) {
      if (set.isEmpty) _pendingAnimations.remove(street);
      return true;
    }
    return false;
  }

  void startPlayback({Duration? stepDelay, bool Function()? canAdvance}) =>
      _playbackService.startPlayback(
        actionSync.analyzerActions.length,
        delay: stepDelay,
        canAdvance: canAdvance,
      );

  void pausePlayback() => _playbackService.pausePlayback();

  void stepForward() =>
      _playbackService.stepForward(actionSync.analyzerActions.length);

  void stepBackward() => _playbackService.stepBackward();

  void seek(int index) => _playbackService.seek(index);

  void resetHand() {
    _playbackService.resetHand();
    actionSync.updatePlaybackIndex(_playbackService.playbackIndex);
    _pendingAnimations.clear();
    updatePlaybackState();
  }

  void updatePlaybackState() {
    final subset = actionSync.analyzerActions
        .take(_playbackService.playbackIndex)
        .toList();

    // Determine players with chip animations up to the current index.
    final previous = {
      for (final e in animatedPlayersPerStreet.entries)
        e.key: Set<int>.from(e.value)
    };
    final Map<int, Set<int>> newAnimated = {};
    for (final a in subset) {
      if ((a.action == 'bet' ||
              a.action == 'raise' ||
              a.action == 'call' ||
              a.action == 'all-in') &&
          a.amount != null &&
          !a.generated) {
        newAnimated.putIfAbsent(a.street, () => <int>{}).add(a.playerIndex);
      }
    }
    animatedPlayersPerStreet
      ..clear()
      ..addAll(newAnimated);
    _pendingAnimations.clear();
    newAnimated.forEach((street, players) {
      final diff = players.difference(previous[street] ?? <int>{});
      if (diff.isNotEmpty) {
        _pendingAnimations[street] = diff;
      }
    });

    // Pot sizes are synchronized via [PotSyncService].
    potSync.updateForPlayback(
        _playbackService.playbackIndex, actionSync.analyzerActions);
    for (int i = 0; i < pots.length; i++) {
      pots[i] = potSync.pots[i];
    }
    lastActionPlayerIndex = subset.isNotEmpty ? subset.last.playerIndex : null;
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

  /// Serializes the current playback state.
  Map<String, dynamic> toJson() => {'playbackIndex': playbackIndex};

  /// Returns `null` when [playbackIndex] is zero, otherwise [toJson()].
  Map<String, dynamic>? toNullableJson() =>
      playbackIndex == 0 ? null : toJson();

  /// Applies the current playback state to [hand].
  SavedHand applyTo(SavedHand hand) =>
      hand.copyWith(playbackIndex: playbackIndex);

  /// Restores playback state from [json].
  void restoreFromJson(Map<String, dynamic>? json) {
    final idx = (json?['playbackIndex'] as int?) ?? 0;
    final clamped = idx.clamp(0, actionSync.analyzerActions.length);
    seek(clamped);
    animatedPlayersPerStreet.clear();
    updatePlaybackState();
  }

  /// Restores playback state from [hand].
  void restoreFromHand(SavedHand hand) =>
      restoreFromJson({'playbackIndex': hand.playbackIndex});
}
