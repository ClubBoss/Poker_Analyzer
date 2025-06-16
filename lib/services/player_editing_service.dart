import '../models/action_entry.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import 'player_manager_service.dart';
import 'stack_manager_service.dart';
import 'playback_manager_service.dart';

/// Service that centralizes player info editing and keeps related
/// services in sync.
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

  Map<int, String> get playerPositions => _playerManager.playerPositions;
  Map<int, PlayerType> get playerTypes => _playerManager.playerTypes;
  List<List<CardModel>> get playerCards => _playerManager.playerCards;
  int get heroIndex => _playerManager.heroIndex;
  int get numberOfPlayers => _playerManager.numberOfPlayers;
  List<PlayerModel> get players => _playerManager.players;

  void setPosition(int playerIndex, String position) {
    _playerManager.setPosition(playerIndex, position);
  }

  void setHeroIndex(int index) {
    _playerManager.setHeroIndex(index);
  }

  void onPlayerCountChanged(int value) {
    _playerManager.onPlayerCountChanged(value);
  }

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

  void setInitialStack(int index, int stack) {
    _playerManager.setInitialStack(index, stack);
    _stackService.reset(Map<int, int>.from(_playerManager.initialStacks));
    _playbackManager.updatePlaybackState();
  }

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

  void reset() {
    _playerManager.reset();
    _stackService.reset(Map<int, int>.from(_playerManager.initialStacks));
    _playbackManager.resetHand();
  }
}
