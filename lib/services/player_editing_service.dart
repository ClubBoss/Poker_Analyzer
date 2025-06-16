import '../models/action_entry.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import 'player_manager_service.dart';
import 'stack_manager_service.dart';
import 'playback_manager_service.dart';

/// Handles modifications to player info and keeps related services
/// synchronized.
class PlayerEditingService {
  PlayerEditingService({
    required PlayerManagerService playerManager,
    required StackManagerService stackService,
    required PlaybackManagerService playbackManager,
  })  : _playerManager = playerManager,
        _stackService = stackService,
        _playbackManager = playbackManager;

  final PlayerManagerService _playerManager;
  final StackManagerService _stackService;
  final PlaybackManagerService _playbackManager;

  /// Update position for [playerIndex].
  void setPosition(int playerIndex, String position) {
    _playerManager.setPosition(playerIndex, position);
  }

  /// Change the hero seat to [index].
  void setHeroIndex(int index) {
    _playerManager.setHeroIndex(index);
    _playbackManager.updatePlaybackState();
  }

  /// Update the player count and reset stacks accordingly.
  void onPlayerCountChanged(int count) {
    _playerManager.onPlayerCountChanged(count);
    _stackService.reset(Map<int, int>.from(_playerManager.initialStacks));
    _playbackManager.updatePlaybackState();
  }

  /// Update the initial stack for [index].
  void setInitialStack(int index, int stack) {
    _playerManager.setInitialStack(index, stack);
    _stackService.setInitialStack(index, stack);
    _playbackManager.updatePlaybackState();
  }

  /// Apply [stack], [type], [isHero] and hole [cards] to a player.
  void updatePlayer(
    int index, {
    required int stack,
    required PlayerType type,
    required bool isHero,
    required List<CardModel> cards,
    bool disableCards = false,
  }) {
    _playerManager.updatePlayer(
      index,
      stack: stack,
      type: type,
      isHero: isHero,
      cards: cards,
      disableCards: disableCards,
    );
    _stackService.reset(Map<int, int>.from(_playerManager.initialStacks));
    _playbackManager.updatePlaybackState();
  }

  /// Remove player at [index] and keep stacks/playback in sync.
  void removePlayer(
    int index, {
    required int heroIndexOverride,
    required List<ActionEntry> actions,
    required List<bool> hintFlags,
  }) {
    _playerManager.removePlayer(
      index,
      heroIndexOverride: heroIndexOverride,
      actions: actions,
      hintFlags: hintFlags,
    );
    if (_playbackManager.playbackIndex > actions.length) {
      _playbackManager.seek(actions.length);
    }
    _stackService.reset(Map<int, int>.from(_playerManager.initialStacks));
    _playbackManager.updatePlaybackState();
  }
}
