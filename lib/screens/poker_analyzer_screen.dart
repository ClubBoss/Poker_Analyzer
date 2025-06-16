import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../services/evaluation_queue_service.dart';
import '../services/debug_preferences_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/card_model.dart';
import '../models/action_entry.dart';
import '../services/playback_manager_service.dart';
import '../services/board_manager_service.dart';
import '../services/board_sync_service.dart';
import '../services/board_editing_service.dart';
import '../services/board_reveal_service.dart';
import '../widgets/player_zone_widget.dart';
import '../widgets/street_actions_widget.dart';
import '../widgets/board_display.dart';
import '../widgets/action_history_overlay.dart';
import '../widgets/collapsible_action_history.dart';
import '../widgets/action_history_expansion_tile.dart';
import 'package:provider/provider.dart';
import '../services/saved_hand_manager_service.dart';
import '../theme/constants.dart';
import '../theme/app_colors.dart';
import '../widgets/detailed_action_bottom_sheet.dart';
import '../widgets/chip_widget.dart';
import '../widgets/player_info_widget.dart';
import '../widgets/street_actions_list.dart';
import '../widgets/collapsible_street_section.dart';
import '../widgets/hud_overlay.dart';
import '../widgets/chip_trail.dart';
import '../widgets/bet_chips_on_table.dart';
import '../widgets/invested_chip_tokens.dart';
import '../widgets/central_pot_widget.dart';
import '../widgets/central_pot_chips.dart';
import '../widgets/pot_display_widget.dart';
import '../widgets/card_selector.dart';
import '../widgets/player_bet_indicator.dart';
import '../widgets/player_stack_chips.dart';
import '../widgets/bet_stack_chips.dart';
import '../widgets/chip_stack_widget.dart';
import '../widgets/chip_amount_widget.dart';
import '../widgets/mini_stack_widget.dart';
import '../helpers/poker_position_helper.dart';
import '../models/saved_hand.dart';
import '../models/player_model.dart';
import '../models/action_evaluation_request.dart';
import '../widgets/action_timeline_widget.dart';
import '../services/pot_sync_service.dart';
import '../widgets/chip_moving_widget.dart';
import '../services/stack_manager_service.dart';
import '../services/player_manager_service.dart';
import '../services/player_profile_service.dart';
import '../services/hand_restore_service.dart';
import '../services/action_tag_service.dart';
import '../helpers/date_utils.dart';
import '../widgets/evaluation_request_tile.dart';
import '../helpers/debug_helpers.dart';
import '../helpers/table_geometry_helper.dart';
import '../helpers/action_formatting_helper.dart';
import '../services/backup_manager_service.dart';
import '../services/action_sync_service.dart';
import "../services/transition_lock_service.dart";
import '../services/current_hand_context_service.dart';
import '../services/folded_players_service.dart';



class PokerAnalyzerScreen extends StatefulWidget {
  final SavedHand? initialHand;
  final EvaluationQueueService? queueService;
  final DebugPreferencesService? debugPrefsService;
  final ActionSyncService actionSync;
  final HandRestoreService? handRestoreService;
  final CurrentHandContextService? handContext;
  final FoldedPlayersService? foldedPlayersService;
  final BackupManagerService? backupManagerService;
  final PlaybackManagerService playbackManager;
  final StackManagerService stackService;
  final BoardManagerService boardManager;
  final BoardSyncService boardSync;
  final BoardEditingService boardEditing;
  final PlayerProfileService playerProfile;
  final ActionTagService actionTagService;
  final BoardRevealService boardReveal;
  final PotSyncService potSyncService;

  const PokerAnalyzerScreen({
    super.key,
    this.initialHand,
    this.queueService,
    this.debugPrefsService,
    required this.actionSync,
    this.handRestoreService,
    this.handContext,
    this.foldedPlayersService,
    this.backupManagerService,
    required this.playbackManager,
    required this.stackService,
    required this.boardManager,
    required this.boardSync,
    required this.boardEditing,
    required this.playerProfile,
    required this.actionTagService,
    required this.boardReveal,
    required this.potSyncService,
  });

  @override
  State<PokerAnalyzerScreen> createState() => _PokerAnalyzerScreenState();
}

class _PokerAnalyzerScreenState extends State<PokerAnalyzerScreen>
    with TickerProviderStateMixin {
  late SavedHandManagerService _handManager;
  late PlayerManagerService _playerManager;
  late PlayerProfileService _profile;
  late BoardManagerService _boardManager;
  late BoardSyncService _boardSync;
  late BoardEditingService _boardEditing;
  late BoardRevealService _boardReveal;
  late ActionTagService _actionTagService;
  int get heroIndex => _profile.heroIndex;
  set heroIndex(int v) => _profile.heroIndex = v;
  String get _heroPosition => _profile.heroPosition;
  set _heroPosition(String v) => _profile.heroPosition = v;
  int get numberOfPlayers => _playerManager.numberOfPlayers;
  set numberOfPlayers(int v) => _playerManager.numberOfPlayers = v;
  List<List<CardModel>> get playerCards => _playerManager.playerCards;
  List<CardModel> get boardCards => _boardManager.boardCards;
  List<PlayerModel> get players => _profile.players;
  Map<int, String> get playerPositions => _profile.playerPositions;
  Map<int, PlayerType> get playerTypes => _profile.playerTypes;
  List<bool> get _showActionHints => _playerManager.showActionHints;
  List<CardModel> get revealedBoardCards => _boardSync.revealedBoardCards;
  int? get opponentIndex => _profile.opponentIndex;
  set opponentIndex(int? v) => _profile.opponentIndex = v;
  int get currentStreet => _boardManager.currentStreet;
  set currentStreet(int v) => _boardManager.currentStreet = v;
  int get boardStreet => _boardManager.boardStreet;
  set boardStreet(int v) => _boardManager.boardStreet = v;
  List<ActionEntry> get actions => _actionSync.analyzerActions;
  late PlaybackManagerService _playbackManager;
  late PotSyncService _potSync;
  late StackManagerService _stackService;
  late HandRestoreService _handRestore;
  late CurrentHandContextService _handContext;
  Set<String> get allTags => _handManager.allTags;
  Set<String> get tagFilters => _handManager.tagFilters;
  set tagFilters(Set<String> v) => _handManager.tagFilters = v;
  int? activePlayerIndex;
  Timer? _activeTimer;
  late FoldedPlayersService _foldedPlayers;
  late ActionSyncService _actionSync;

  Set<int> get _expandedHistoryStreets => _actionSync.expandedHistoryStreets;

  ActionEntry? _centerChipAction;
  bool _showCenterChip = false;
  Timer? _centerChipTimer;
  late AnimationController _centerChipController;
  final TransitionLockService lockService = TransitionLockService();
  final GlobalKey<_BoardCardsSectionState> _boardKey =
      GlobalKey<_BoardCardsSectionState>();
  late final ScrollController _timelineController;
  bool _animateTimeline = false;
  bool isPerspectiveSwitched = false;



  /// Handles evaluation queue state and processing.
  late final EvaluationQueueService _queueService;




  /// Allows updating the debug panel while it's open.
  StateSetter? _debugPanelSetState;
  late BackupManagerService _backupManager;

  late final DebugPreferencesService _debugPrefs;

  /// Evaluation processing delay, snapshot retention and other debug
  /// preferences are managed by [_debugPrefs].


  static const double _timelineExtent = 80.0;
  /// Duration for individual board card animations.
  static const Duration _boardRevealDuration = Duration(milliseconds: 200);
  /// Delay between sequential board reveals.
  static const Duration _boardRevealStagger = Duration(milliseconds: 50);


  Widget _queueSection(String label, List<ActionEvaluationRequest> queue) {
    final filtered = _debugPrefs.applyAdvancedFilters(queue);
    return debugQueueSection(label, filtered,
        _debugPrefs.advancedFilters.isEmpty && !_debugPrefs.sortBySpr &&
            _debugPrefs.searchQuery.isEmpty
            ? (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex -= 1;
                lockService.safeSetState(this, () {
                  final item = queue.removeAt(oldIndex);
                  queue.insert(newIndex, item);
                });
                _queueService.persist();
                _debugPanelSetState?.call(() {});
              }
            : (_, __) {});
  }


  void setPosition(int playerIndex, String position) {
    if (lockService.boardTransitioning) return;
    lockService.safeSetState(this, () {
      _playerManager.setPosition(playerIndex, position);
    });
  }

  void _setHeroIndex(int index) {
    if (lockService.boardTransitioning) return;
    lockService.safeSetState(this, () {
      _playerManager.setHeroIndex(index);
    });
  }

  void _onPlayerCountChanged(int value) {
    if (lockService.boardTransitioning) return;
    lockService.safeSetState(this, () {
      _playerManager.onPlayerCountChanged(value);
    });
  }

  String _positionLabelForIndex(int index) {
    final pos = playerPositions[index];
    if (pos == null) return '';
    if (pos.startsWith('UTG')) return 'UTG';
    if (pos == 'HJ' || pos == 'MP') return 'MP';
    return pos;
  }


  int _viewIndex() {
    if (isPerspectiveSwitched && opponentIndex != null) {
      return opponentIndex!;
    }
    return _profile.heroIndex;
  }

  int _inferBoardStreet() => _boardSync.inferBoardStreet();

  bool _isBoardStageComplete(int stage) =>
      _boardSync.isBoardStageComplete(stage);





  void _triggerCenterChip(ActionEntry entry) {
    if (!['bet', 'raise', 'call', 'all-in'].contains(entry.action) ||
        entry.amount == null ||
        entry.generated) {
      return;
    }
    _centerChipTimer?.cancel();
    _centerChipController.forward(from: 0);
    lockService.safeSetState(this, () {
      _centerChipAction = entry;
      _showCenterChip = true;
    });
    _centerChipTimer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _centerChipController.reverse();
      lockService.safeSetState(this, () {
        _showCenterChip = false;
        _centerChipAction = null;
      });
    });
  }

  void _playUnifiedChipAnimation(ActionEntry entry) {
    if (!['bet', 'raise', 'call'].contains(entry.action) ||
        entry.amount == null ||
        entry.generated) return;
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    final double scale =
        TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final tableWidth = screen.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 - TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;
    final i =
        (entry.playerIndex - _viewIndex() + numberOfPlayers) % numberOfPlayers;
    final angle = 2 * pi * i / numberOfPlayers + pi / 2;
    final dx = radiusX * cos(angle);
    final dy = radiusY * sin(angle);
    final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
    final start = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
    final end = Offset(centerX, centerY);
    final color = entry.action == 'raise'
        ? Colors.green
        : entry.action == 'call'
            ? Colors.blue
            : Colors.amber;
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (_) => ChipMovingWidget(
        start: start,
        end: end,
        amount: entry.amount!,
        color: color,
        scale: scale,
        onCompleted: () => overlayEntry.remove(),
      ),
    );
    overlay.insert(overlayEntry);
  }

  void _autoCollapseStreets() {
    for (int i = 0; i < 4; i++) {
      if (!actions.any((a) => a.street == i)) {
        _actionSync.removeExpandedStreet(i);
      }
    }
  }

  bool _isStreetComplete(int street) {
    final active = <int>{};
    for (int i = 0; i < _playerManager.numberOfPlayers; i++) {
      if (!_foldedPlayers.contains(i)) active.add(i);
    }
    if (active.length <= 1) return true;
    final acted = actions
        .where((a) => a.street == street)
        .map((a) => a.playerIndex)
        .toSet();
    return active.difference(acted).isEmpty;
  }

  void _autoAdvanceStreetIfComplete(int street) {
    if (street != currentStreet || street >= 3) return;
    if (!_isStreetComplete(street)) return;
    _recordSnapshot();
    _changeStreet(street + 1);
  }

  bool _canReverseStreet() {
    if (currentStreet == 0) return false;
    final prev = currentStreet - 1;
    return !actions.any((a) => a.street > prev);
  }

  void _reverseStreet() {
    if (lockService.boardTransitioning || !_canReverseStreet()) return;
    _recordSnapshot();
    _changeStreet(currentStreet - 1);
  }

  bool _canAdvanceStreet() => currentStreet < boardStreet;

  void _advanceStreet() {
    if (lockService.boardTransitioning || !_canAdvanceStreet()) return;
    _recordSnapshot();
    _changeStreet(currentStreet + 1);
  }

  void _changeStreet(int street) {
    if (lockService.boardTransitioning) return;
    _actionTagService.clear();
    _boardManager.changeStreet(street);
  }



  void _play() {
    if (lockService.boardTransitioning) return;
    _playbackManager.startPlayback();
  }

  void _pause() {
    if (lockService.boardTransitioning) return;
    _playbackManager.pausePlayback();
  }

  void _stepBackwardPlayback() {
    if (lockService.boardTransitioning) return;
    _playbackManager.stepBackward();
  }

  void _stepForwardPlayback() {
    if (lockService.boardTransitioning) return;
    _playbackManager.stepForward();
  }

  void _seekPlayback(double value) {
    if (lockService.boardTransitioning) return;
    _playbackManager.seek(value.round());
    _playbackManager.updatePlaybackState();
  }

  ActionSnapshot _currentSnapshot() =>
      _actionSync.buildSnapshot(List<CardModel>.from(boardCards));

  void _recordSnapshot() {
    _actionSync.recordSnapshot(_currentSnapshot());
  }

  void _applySnapshot(ActionSnapshot snap) {
    final prevStreet = currentStreet;
    _actionSync.restoreSnapshot(snap);
    _boardManager.setBoardCards(snap.board);
    _animateTimeline = true;
    if (currentStreet != prevStreet) {
      _boardManager.startBoardTransition();
    }
  }


  // Formatting helpers moved to [ActionFormattingHelper].

  String _actionLabel(ActionEntry entry) {
    return entry.amount != null
        ? '${entry.action} ${entry.amount}'
        : entry.action;
  }



  String _cardToDebugString(CardModel card) {
    const suits = {'♠': 's', '♥': 'h', '♦': 'd', '♣': 'c'};
    return '${card.rank}${suits[card.suit] ?? card.suit}';
  }

  Widget _playerTypeIcon(PlayerType? type) {
    switch (type) {
      case PlayerType.shark:
        return const Tooltip(
          message: 'Shark',
          child: Text('🦈', style: TextStyle(fontSize: 14)),
        );
      case PlayerType.fish:
        return const Tooltip(
          message: 'Fish',
          child: Text('🐟', style: TextStyle(fontSize: 14)),
        );
      case PlayerType.nit:
        return const Tooltip(
          message: 'Nit',
          child: Text('🧊', style: TextStyle(fontSize: 14)),
        );
      case PlayerType.maniac:
        return const Tooltip(
          message: 'Maniac',
          child: Text('🔥', style: TextStyle(fontSize: 14)),
        );
      case PlayerType.callingStation:
        return const Tooltip(
          message: 'Calling Station',
          child: Text('📞', style: TextStyle(fontSize: 14)),
        );
      default:
        return const Tooltip(
          message: 'Standard',
          child: Icon(Icons.person, size: 14, color: Colors.white70),
        );
    }
  }

  String _playerTypeLabel(PlayerType? type) {
    switch (type) {
      case PlayerType.shark:
        return 'Shark';
      case PlayerType.fish:
        return 'Fish';
      case PlayerType.nit:
        return 'Nit';
      case PlayerType.maniac:
        return 'Maniac';
      case PlayerType.callingStation:
        return 'Calling Station';
      default:
        return 'Standard';
    }
  }

  String _evaluateActionQuality(ActionEntry entry) {
    switch (entry.action) {
      case 'raise':
      case 'bet':
        return 'good';
      case 'call':
      case 'check':
        return 'ok';
      case 'fold':
        return 'bad';
      default:
        return 'ok';
    }
  }

  void _addQualityTags() {
    final tags = _handContext.tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet();
    bool misplay = false;
    bool aggressive = false;
    for (final a in actions) {
      final q = _evaluateActionQuality(a).toLowerCase();
      if (q.contains('плох') || q.contains('ошиб') || q.contains('bad')) {
        misplay = true;
      }
      if (q.contains('агресс') || q.contains('overbet') || q.contains('слишком')) {
        aggressive = true;
      }
    }
    if (misplay) tags.add('🚫 Мисс-плей');
    if (aggressive) tags.add('🤯 Слишком агрессивно');
    _handContext.tagsController.text = tags.join(', ');
  }


  Future<void> _editPlayerInfo(int index) async {
    if (lockService.boardTransitioning) return;
    final disableCards = index != _profile.heroIndex;

    await showDialog(
      context: context,
      builder: (context) => _PlayerEditorSection(
        initialStack: _stackService.initialStacks[index] ?? 0,
        initialType: _profile.playerTypes[index] ?? PlayerType.unknown,
        isHeroSelected: index == _profile.heroIndex,
        card1: _playerManager.playerCards[index].isNotEmpty
            ? _playerManager.playerCards[index][0]
            : null,
        card2: _playerManager.playerCards[index].length > 1
            ? _playerManager.playerCards[index][1]
            : null,
        disableCards: disableCards,
        onSave: (stack, type, isHero, c1, c2) {
          if (lockService.boardTransitioning) return;
          lockService.safeSetState(this, () {
            final cards = <CardModel>[];
            if (c1 != null) cards.add(c1);
            if (c2 != null) cards.add(c2);
            _playerManager.updatePlayer(
              index,
              stack: stack,
              type: type,
              isHero: isHero,
              cards: cards,
              disableCards: disableCards,
            );
            _stackService
                .reset(Map<int, int>.from(_playerManager.initialStacks));
            _playbackManager.updatePlaybackState();
          });
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _handContext = widget.handContext ?? CurrentHandContextService();
    _actionSync = widget.actionSync;
    _foldedPlayers = widget.foldedPlayersService ?? FoldedPlayersService();
    _queueService = widget.queueService ?? EvaluationQueueService();
    _debugPrefs = widget.debugPrefsService ?? DebugPreferencesService();
    _backupManager = widget.backupManagerService ?? BackupManagerService(
      queueService: _queueService,
      debugPrefs: _debugPrefs,
    );
    _centerChipController = AnimationController(
      vsync: this,
      duration: _boardRevealDuration,
    );
    _timelineController = ScrollController();
    _playerManager = context.read<PlayerManagerService>()
      ..addListener(_onPlayerManagerChanged);
    _profile = widget.playerProfile;
    _actionTagService = widget.actionTagService;
    _boardReveal = widget.boardReveal;
    _potSync = widget.potSyncService;
    _boardManager = widget.boardManager
      ..addListener(() {
        if (mounted) lockService.safeSetState(this, () {});
      });
    _boardSync = widget.boardSync;
    _boardEditing = widget.boardEditing;
    _stackService = widget.stackService;
    _actionSync.attachStackManager(_stackService);
    _potSync.stackService = _stackService;
    _playbackManager = widget.playbackManager;
    _playbackManager
      ..stackService = _stackService
      ..addListener(_onPlaybackManagerChanged);
    _handRestore = widget.handRestoreService ?? HandRestoreService(
      playerManager: _playerManager,
      profile: _profile,
      actionSync: _actionSync,
      playbackManager: _playbackManager,
      boardManager: _boardManager,
      boardSync: _boardSync,
      queueService: _queueService,
      backupManager: _backupManager,
      debugPrefs: _debugPrefs,
      lockService: lockService,
      handContext: _handContext,
      pendingEvaluations: _queueService.pending,
      foldedPlayers: _foldedPlayers,
      actionTags: _actionTagService,
      setCurrentHandName: (name) => _handContext.currentHandName = name,
      setActivePlayerIndex: (i) => activePlayerIndex = i,
      potSync: _potSync,
    );
    _profile.updatePositions();
    _playbackManager.updatePlaybackState();
    if (widget.initialHand != null) {
      _stackService = _handRestore.restoreHand(widget.initialHand!);
      _actionSync.attachStackManager(_stackService);
      _potSync.stackService = _stackService;
      _actionSync.updatePlaybackIndex(_playbackManager.playbackIndex);
      _boardManager.startBoardTransition();
    }
    Future(() => _cleanupOldEvaluationBackups());
    Future(() => _initializeDebugPreferences());
    Future.microtask(_queueService.loadQueueSnapshot);
    Future(() => _backupManager.cleanupOldAutoBackups());
    _backupManager.startAutoBackupTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handManager = context.read<SavedHandManagerService>();
  }

  void selectCard(int index, CardModel card) {
    if (_boardEditing.isDuplicateSelection(card, null)) {
      _boardEditing.showDuplicateCardMessage(context);
      return;
    }
    lockService.safeSetState(this, () => _playerManager.selectCard(index, card));
  }

  Future<void> _onPlayerCardTap(int index, int cardIndex) async {
    if (lockService.boardTransitioning) return;
    final current =
        cardIndex < playerCards[index].length ? playerCards[index][cardIndex] : null;
    final selectedCard = await showCardSelector(
      context,
      disabledCards: _boardEditing.usedCardKeys(except: current),
    );
    if (selectedCard == null) return;
    if (_boardEditing.isDuplicateSelection(selectedCard, current)) {
      _boardEditing.showDuplicateCardMessage(context);
      return;
    }
    lockService.safeSetState(this, () =>
        _playerManager.setPlayerCard(index, cardIndex, selectedCard));
  }

  void _onPlayerTimeExpired(int index) {
    if (lockService.boardTransitioning) return;
    if (activePlayerIndex == index) {
      lockService.safeSetState(this, () => activePlayerIndex = null);
    }
  }

  Future<void> _onOpponentCardTap(int cardIndex) async {
    if (lockService.boardTransitioning) return;
    if (opponentIndex == null) opponentIndex = activePlayerIndex;
    final idx = opponentIndex ?? 0;
    await _onRevealedCardTap(idx, cardIndex);
  }

  Future<void> _onRevealedCardTap(int playerIndex, int cardIndex) async {
    if (lockService.boardTransitioning) return;
    final current = players[playerIndex].revealedCards[cardIndex];
    final selected = await showCardSelector(
      context,
      disabledCards: _boardEditing.usedCardKeys(except: current),
    );
    if (selected == null) return;
    if (_boardEditing.isDuplicateSelection(selected, current)) {
      _boardEditing.showDuplicateCardMessage(context);
      return;
    }
    lockService.safeSetState(this, () =>
        _playerManager.setRevealedCard(playerIndex, cardIndex, selected));
  }



  void selectBoardCard(int index, CardModel card) {
    if (lockService.boardTransitioning) return;
    if (!_boardEditing.canEditBoard(context, index)) return;
    final current = index < boardCards.length ? boardCards[index] : null;
    if (_boardEditing.isDuplicateSelection(card, current)) {
      _boardEditing.showDuplicateCardMessage(context);
      return;
    }
    lockService.safeSetState(this, () {
      _recordSnapshot();
      _boardManager.selectBoardCard(index, card);
    });
  }

  void _removeBoardCard(int index) {
    if (lockService.boardTransitioning) return;
    if (index >= boardCards.length) return;
    lockService.safeSetState(this, () {
      _recordSnapshot();
      _boardManager.removeBoardCard(index);
    });
  }

  Future<Map<String, dynamic>?> _showActionPicker() {
    final bool hasBet = _streetHasBet();
    final bool betEnabled = !hasBet;
    final bool raiseEnabled = hasBet;
    final TextEditingController controller = TextEditingController();
    String? selected;
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final bool needAmount = selected == 'bet' || selected == 'raise';
          return Padding(
            padding: MediaQuery.of(ctx).viewInsets + const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, {'action': 'check'}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Check'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, {'action': 'call'}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Call'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: betEnabled
                      ? () => setModal(() => selected = 'bet')
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Bet'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: raiseEnabled
                      ? () => setModal(() => selected = 'raise')
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Raise'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, {'action': 'fold'}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Fold'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, {'action': 'all-in'}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('All-In'),
                ),
                if (needAmount) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white10,
                      hintText: 'Amount',
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final int? amt = int.tryParse(controller.text);
                      if (amt != null) {
                        Navigator.pop(ctx, {
                          'action': selected,
                          'amount': amt,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirm'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _onPlayerTap(int index) async {
    if (lockService.boardTransitioning) return;
    lockService.safeSetState(this, () => activePlayerIndex = index);
    final result = await _showActionPicker();
    if (result == null) return;
    String action = result['action'] as String;
    int? amount = result['amount'] as int?;
    if (action == 'all-in') {
      amount = _stackService.getStackForPlayer(index);
    }
    final entry = ActionEntry(currentStreet, index, action, amount: amount);
    onActionSelected(entry);
  }


  bool _streetHasBet({List<ActionEntry>? fromActions}) {
    final list = fromActions ?? actions;
    return list
        .where((a) => a.street == currentStreet)
        .any((a) => a.action == 'bet' || a.action == 'raise');
  }

  void _onPlaybackManagerChanged() {
    if (mounted) {
      lockService.safeSetState(this, () {});
      if (_animateTimeline && _timelineController.hasClients) {
        _animateTimeline = false;
        _timelineController.animateTo(
          _playbackManager.playbackIndex * _timelineExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _onPlayerManagerChanged() {
    if (mounted) lockService.safeSetState(this, () {});
  }






  Future<void> _clearEvaluationQueue() async {
    await _queueService.clearQueue();
    unawaited(_debugPrefs.setEvaluationQueueResumed(false));
    if (mounted) {
      lockService.safeSetState(this, () {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evaluation queue cleared')),
      );
    }
    _debugPanelSetState?.call(() {});
  }

  Future<void> _clearPendingQueue() async {
    if (_queueService.pending.isEmpty) return;
    await _queueService.clearPending();
    if (mounted) {
      lockService.safeSetState(this, () {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pending queue cleared')),
      );
    }
    _debugPanelSetState?.call(() {});
  }

  Future<void> _clearFailedQueue() async {
    if (_queueService.failed.isEmpty) return;
    await _queueService.clearFailed();
    if (mounted) {
      lockService.safeSetState(this, () {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed queue cleared')),
      );
    }
    _debugPanelSetState?.call(() {});
  }

  Future<void> _clearCompletedQueue() async {
    if (_queueService.completed.isEmpty) return;
    await _queueService.clearCompleted();
    if (mounted) {
      lockService.safeSetState(this, () {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completed queue cleared')),
      );
    }
    _debugPanelSetState?.call(() {});
  }

  Future<void> _clearCompletedEvaluations() async {
    final count = _queueService.completed.length;
    if (count == 0) return;
    await _queueService.clearCompleted();
    _debugPanelSetState?.call(() {});
    if (mounted) {
      lockService.safeSetState(this, () {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cleared $count completed evaluations')),
      );
    }
  }

  Future<void> _removeDuplicateEvaluations() async {
    try {
      final removed = await _queueService.removeDuplicateEvaluations();
      if (mounted) {
        lockService.safeSetState(this, () {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed $removed duplicate entries')),
        );
      }
      _debugPanelSetState?.call(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove duplicates')),
        );
      }
    }
  }

  Future<void> _resolveQueueConflicts() async {
    try {
      final removed = await _queueService.resolveQueueConflicts();
      if (mounted) {
        lockService.safeSetState(this, () {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resolved $removed conflicts')),
        );
      }
      _debugPanelSetState?.call(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resolve conflicts')),
        );
      }
    }
  }

  int _compareEvaluationRequests(
      ActionEvaluationRequest a, ActionEvaluationRequest b) {
    final streetComp = a.street.compareTo(b.street);
    if (streetComp != 0) return streetComp;
    final playerComp = a.playerIndex.compareTo(b.playerIndex);
    if (playerComp != 0) return playerComp;
    return a.action.compareTo(b.action);
  }

  Future<void> _sortEvaluationQueues() async {
    try {
      await _queueService.sortQueues();
      if (mounted) {
        lockService.safeSetState(this, () {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Queues sorted')),
        );
      }
      _debugPanelSetState?.call(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sort queues')),
        );
      }
    }
  }

  Future<void> _toggleEvaluationProcessingPause() async {
    await _queueService.togglePauseProcessing();
    if (mounted) lockService.safeSetState(this, () {});
    _debugPanelSetState?.call(() {});
  }

  Future<void> _cancelEvaluationProcessing() async {
    await _queueService.cancelProcessing();
    if (mounted) lockService.safeSetState(this, () {});
    _debugPanelSetState?.call(() {});
  }

  Future<void> _forceRestartEvaluationProcessing() async {
    await _queueService.forceRestartProcessing();
    if (mounted) lockService.safeSetState(this, () {});
    _debugPanelSetState?.call(() {});
  }

  void _retryFailedEvaluations() {
    _queueService.retryFailedEvaluations().then((_) {
      if (mounted) {
        lockService.safeSetState(this, () {});
      }
      _queueService.persist();
      _debugPanelSetState?.call(() {});
    });
  }

  void _removeFutureActionsForPlayer(
      int playerIndex, int street, int fromIndex) {
    final toRemove = <int>[];
    for (int i = actions.length - 1; i > fromIndex; i--) {
      final a = actions[i];
      if (a.playerIndex == playerIndex && a.street >= street) {
        toRemove.add(i);
      }
    }
    if (toRemove.isEmpty) return;
    for (final idx in toRemove) {
      final s = actions[idx].street;
      _actionSync.deleteAnalyzerAction(idx,
          recordHistory: false, street: s);
    }
    if (_playbackManager.playbackIndex > actions.length) {
      _playbackManager.seek(actions.length);
    }
    _actionTagService.updateAfterActionRemoval(playerIndex, actions);
    _playbackManager.updatePlaybackState();
  }


  void _addAutoFolds(ActionEntry entry) {
    final street = entry.street;
    final ordered = List.generate(_playerManager.numberOfPlayers,
        (i) => (i + _profile.heroIndex) % _playerManager.numberOfPlayers);
    final acted = actions
        .where((a) => a.street == street)
        .map((a) => a.playerIndex)
        .toSet();
    final toFold = ordered
        .takeWhile((i) => i != entry.playerIndex)
        .where((i) => !acted.contains(i));

    bool inserted = false;
    for (final i in toFold) {
      final autoFold = ActionEntry(street, i, 'fold', generated: true);
      _addAction(autoFold);
      _removeFutureActionsForPlayer(i, street, actions.length - 1);
      inserted = true;
    }
    if (inserted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пропущенные игроки сброшены в пас.')),
      );
    }
  }

  void _addAction(ActionEntry entry,
      {int? index, bool recordHistory = true}) {
    if (lockService.boardTransitioning) return;
    final prevStreet = currentStreet;
    final inferred = _boardSync.inferBoardStreet();
    if (inferred > currentStreet) {
      _boardManager.boardStreet = inferred;
      _boardManager.changeStreet(inferred);
    }
    if (entry.street != currentStreet) {
      entry = ActionEntry(currentStreet, entry.playerIndex, entry.action,
          amount: entry.amount, generated: entry.generated);
    }
    final insertIndex = index ?? actions.length;
    if (recordHistory) {
      _recordSnapshot();
    }
    _actionSync.addAnalyzerAction(entry,
        index: index,
        recordHistory: recordHistory,
        prevStreet: prevStreet,
        newStreet: currentStreet);
    _actionSync.addExpandedStreet(entry.street);
    _actionTagService.updateForAction(entry);
    setPlayerLastAction(
      players[entry.playerIndex].name,
      ActionFormattingHelper.formatLastAction(entry),
      ActionFormattingHelper.actionColor(entry.action),
      entry.amount,
    );
    if (recordHistory) {
      _triggerCenterChip(entry);
      _playUnifiedChipAnimation(entry);
    }
    if (_playbackManager.playbackIndex > actions.length) {
      _playbackManager.seek(actions.length);
    }
    _playbackManager.updatePlaybackState();
    _autoAdvanceStreetIfComplete(entry.street);
  }

  void onActionSelected(ActionEntry entry) {
    lockService.safeSetState(this, () {
      _addAutoFolds(entry);
      _addAction(entry);
      if (entry.action == 'fold') {
        _removeFutureActionsForPlayer(
            entry.playerIndex, entry.street, actions.length - 1);
      }
    });
  }

  void _updateAction(int index, ActionEntry entry,
      {bool recordHistory = true}) {
    final previous = actions[index];
    if (recordHistory) {
      _recordSnapshot();
    }
    _actionSync.updateAnalyzerAction(index, entry,
        recordHistory: recordHistory, street: currentStreet);
    _actionTagService.updateForAction(entry);
    setPlayerLastAction(
      players[entry.playerIndex].name,
      ActionFormattingHelper.formatLastAction(entry),
      ActionFormattingHelper.actionColor(entry.action),
      entry.amount,
    );
    if (recordHistory) {
      _triggerCenterChip(entry);
      _playUnifiedChipAnimation(entry);
    }
    _playbackManager.updatePlaybackState();
  }

  void _editAction(int index, ActionEntry entry) {
    if (lockService.boardTransitioning) return;
    lockService.safeSetState(this, () {
      _updateAction(index, entry);
      if (entry.action == 'fold') {
        _removeFutureActionsForPlayer(entry.playerIndex, entry.street, index);
      }
    });
  }


  void _deleteAction(int index,
      {bool recordHistory = true, bool withSetState = true}) {
    void perform() {
      if (recordHistory) {
        _recordSnapshot();
      }
      final removed = actions[index];
      _actionSync.deleteAnalyzerAction(index,
          recordHistory: recordHistory, street: currentStreet);
      if (_playbackManager.playbackIndex > actions.length) {
        _playbackManager.seek(actions.length);
      }
      // Update action tag for player whose action was removed
      _actionTagService.updateAfterActionRemoval(
          removed.playerIndex, actions);
      _autoCollapseStreets();
      _playbackManager.updatePlaybackState();
    }

    if (withSetState) {
      lockService.safeSetState(this, perform);
    } else {
      perform();
    }
  }

  Future<void> _removeLastPlayerAction(int playerIndex) async {
    final actionIndex = actions.lastIndexWhere(
        (a) => a.playerIndex == playerIndex && a.street == currentStreet);
    if (actionIndex == -1) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить действие?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      lockService.safeSetState(this, () {
        _deleteAction(actionIndex, withSetState: false);
      });
    }
  }

  void _undoAction() {
    if (lockService.undoRedoTransitionLock || lockService.boardTransitioning) return;
    _boardManager.cancelBoardReveal();
    final result = _actionSync.undo(_currentSnapshot());
    if (result.entry == null && result.snapshot == null) return;
    lockService.safeSetState(this, () {
      final op = result.entry;
      final snap = result.snapshot;
      if (op != null) {
        switch (op.type) {
          case ActionChangeType.add:
            _deleteAction(op.index, recordHistory: false, withSetState: false);
            break;
          case ActionChangeType.edit:
            _updateAction(op.index, op.oldEntry!, recordHistory: false);
            break;
          case ActionChangeType.delete:
            _addAction(op.oldEntry!, index: op.index, recordHistory: false);
            break;
        }
        _boardManager.changeStreet(op.prevStreet);
      }
      if (snap != null) {
        _applySnapshot(snap);
      }
      _playbackManager.updatePlaybackState();
      _autoCollapseStreets();
      _boardManager.startBoardTransition();
    });
    _debugPanelSetState?.call(() {});
  }

  void _redoAction() {
    if (lockService.undoRedoTransitionLock || lockService.boardTransitioning) return;
    _boardManager.cancelBoardReveal();
    final result = _actionSync.redo(_currentSnapshot());
    if (result.entry == null && result.snapshot == null) return;
    lockService.safeSetState(this, () {
      final op = result.entry;
      final snap = result.snapshot;
      if (op != null) {
        switch (op.type) {
          case ActionChangeType.add:
            _addAction(op.newEntry!, index: op.index, recordHistory: false);
            break;
          case ActionChangeType.edit:
            _updateAction(op.index, op.newEntry!, recordHistory: false);
            break;
          case ActionChangeType.delete:
            _deleteAction(op.index, recordHistory: false, withSetState: false);
            break;
        }
        _boardManager.changeStreet(op.newStreet);
      }
      if (snap != null) {
        _applySnapshot(snap);
      }
      _playbackManager.updatePlaybackState();
      _autoCollapseStreets();
      _boardManager.startBoardTransition();
    });
    _debugPanelSetState?.call(() {});
  }

  void _previousStreet() {
    if (lockService.boardTransitioning || currentStreet <= 0) return;
    lockService.safeSetState(this, () {
      _recordSnapshot();
      _boardManager.changeStreet(currentStreet - 1);
      _actionTagService.clear();
      _playbackManager.animatedPlayersPerStreet
          .putIfAbsent(currentStreet, () => <int>{});
      _playbackManager.updatePlaybackState();
      _boardManager.startBoardTransition();
    });
    _debugPanelSetState?.call(() {});
  }

  void _nextStreet() {
    if (lockService.boardTransitioning || currentStreet >= boardStreet) return;
    lockService.safeSetState(this, () {
      _recordSnapshot();
      _boardManager.changeStreet(currentStreet + 1);
      _actionTagService.clear();
      _playbackManager.animatedPlayersPerStreet
          .putIfAbsent(currentStreet, () => <int>{});
      _playbackManager.updatePlaybackState();
      _boardManager.startBoardTransition();
    });
    _debugPanelSetState?.call(() {});
  }

  Future<void> _removePlayer(int index) async {
    if (lockService.boardTransitioning) return;
    if (_playerManager.numberOfPlayers <= 2) return;

    int updatedHeroIndex = _profile.heroIndex;

    if (index == heroIndex) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hero player is being removed'),
          content: const Text('What would you like to do?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'remove'),
              child: const Text('Remove anyway'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'change'),
              child: const Text('Change Hero'),
            ),
          ],
        ),
      );

      if (choice == null || choice == 'cancel') return;

      if (choice == 'change') {
        final selected = await showDialog<int>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Select new hero'),
            children: [
              for (int i = 0; i < _playerManager.numberOfPlayers; i++)
                if (i != index)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, i),
                    child: Text('Player ${i + 1}'),
                  ),
            ],
          ),
        );
        if (selected == null) return;
        updatedHeroIndex = selected;
      }
    }

    lockService.safeSetState(this, () {
      _playerManager.removePlayer(
        index,
        heroIndexOverride: updatedHeroIndex,
        actions: actions,
        hintFlags: _playerManager.showActionHints,
      );
      if (_playbackManager.playbackIndex > actions.length) {
        _playbackManager.seek(actions.length);
      }
      _stackService.reset(
          Map<int, int>.from(_playerManager.initialStacks));
      _playbackManager.updatePlaybackState();
    });
  }

  Future<void> _resetHand() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить раздачу?'),
        content: const Text('Все введённые данные будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      lockService.safeSetState(this, () {
        _playerManager.reset();
        _actionSync.clearAnalyzerActions();
        _foldedPlayers.reset();
        _boardManager.changeStreet(0);
        _boardManager.startBoardTransition();
        _actionTagService.clear();
        _playbackManager.animatedPlayersPerStreet.clear();
        _stackService.reset(
            Map<int, int>.from(_playerManager.initialStacks));
        _playbackManager.resetHand();
        _handContext.commentController.clear();
        _handContext.tagsController.clear();
        _handContext.currentHandName = null;
      });
    }
  }

  String _defaultHandName() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    return 'Раздача от $day.$month.$year';
  }

  Future<void> _exportEvaluationQueue() async {
    await _backupManager.exportEvaluationQueue(context);
  }

  Future<void> _exportQueueToClipboard() async {
    await _backupManager.exportQueueToClipboard(context);
  }

  Future<void> _importQueueFromClipboard() async {
    await _backupManager.importQueueFromClipboard(context);
    lockService.safeSetState(this, () {});
    _debugPanelSetState?.call(() {});
  }

  Future<void> _exportFullEvaluationQueueState() async {
    await _backupManager.exportFullQueueState(context);
  }

  Future<void> _importFullEvaluationQueueState() async {
    await _backupManager.importFullQueueState(context);
    if (mounted) setState(() {});
    _debugPanelSetState?.call(() {});
  }

  Future<void> _restoreFullEvaluationQueueState() async {
    await _backupManager.restoreFullQueueState(context);
    if (mounted) setState(() {});
    _debugPanelSetState?.call(() {});
  }

  Future<void> _backupEvaluationQueue() async {
    await _backupManager.backupEvaluationQueue(context);
  }

  Future<void> _quickBackupEvaluationQueue() async {
    await _backupManager.quickBackupEvaluationQueue(context);
    _debugPanelSetState?.call(() {});
  }

  Future<void> _exportEvaluationQueueSnapshot({bool showNotification = true}) async {
    await _backupManager.exportEvaluationQueueSnapshot(
      context,
      showNotification: showNotification,
    );
  }

  /// Schedule snapshot export without awaiting the result.
  void _scheduleSnapshotExport() {
    unawaited(
      _backupManager.exportEvaluationQueueSnapshot(
        context,
        showNotification: false,
      ),
    );
  }

  /// Load persisted evaluation queue if available.
  Future<void> _loadSavedEvaluationQueue() async {
    try {
      final resumed = await _queueService.loadSavedQueue();
      await s._debugPrefs.setEvaluationQueueResumed(resumed);
      if (mounted) lockService.safeSetState(this, () {});
      _debugPanelSetState?.call(() {});
    } catch (_) {
      await s._debugPrefs.setEvaluationQueueResumed(false);
    }
  }

  /// Executes a single evaluation request.
  ///
  /// This stub simply waits briefly and sometimes throws an exception to
  /// help debug how the UI reacts to evaluation failures.
  Future<void> _executeEvaluation(ActionEvaluationRequest req) async {
    // Delay to mimic heavy evaluation logic.
    await Future.delayed(const Duration(milliseconds: 300));

    // Introduce a 20% chance of failure for testing purposes.
    if (Random().nextDouble() < 0.2) {
      throw Exception('Simulated evaluation failure');
    }
  }

  Future<void> _processEvaluationQueue() async {
    await _queueService.processQueue();
    if (mounted) lockService.safeSetState(this, () {});
  }

  Future<void> _processNextEvaluation() async {
    await _queueService.processQueue();
    if (mounted) lockService.safeSetState(this, () {});
  }

  Future<void> _cleanupOldEvaluationBackups() async {
    await _backupManager.cleanupOldEvaluationBackups();
  }

  Future<void> _cleanupOldEvaluationSnapshots() async {
    await _backupManager.cleanupOldEvaluationSnapshots();
  }

  Future<void> _initializeDebugPreferences() async {
    await _debugPrefs.loadAllPreferences();
    if (_debugPrefs.snapshotRetentionEnabled) {
      await _cleanupOldEvaluationSnapshots();
    }
    if (mounted) lockService.safeSetState(this, () {});
  }

  Future<void> _exportArchive(String subfolder, String archivePrefix) async {
    await _backupManager.exportArchive(context, subfolder, archivePrefix);
    if (mounted) setState(() {});
  }

  Future<void> _exportAllEvaluationBackups() async {
    await _backupManager.exportAllEvaluationBackups(context);
  }

  Future<void> _exportAutoBackups() async {
    await _backupManager.exportAutoBackups(context);
  }

  Future<void> _exportSnapshots() async {
    await _backupManager.exportSnapshots(context);
  }

  Future<void> _restoreFromAutoBackup() async {
    await _backupManager.restoreFromAutoBackup(context);
    if (mounted) setState(() {});
    _debugPanelSetState?.call(() {});
  }

  Future<void> _exportAllEvaluationSnapshots() async {
    await _backupManager.exportAllEvaluationSnapshots(context);
  }

  Future<void> _importEvaluationQueue() async {
    await _backupManager.importEvaluationQueue(context);
    _debugPanelSetState?.call(() {});
    unawaited(_debugPrefs.setEvaluationQueueResumed(false));
  }

  Future<void> _restoreEvaluationQueue() async {
    await _backupManager.restoreEvaluationQueue(context);
  }

  Future<void> _bulkImportEvaluationQueue() async {
    await _backupManager.bulkImportEvaluationQueue(context);
    if (mounted) setState(() {});
    _debugPanelSetState?.call(() {});
  }


  Future<void> _importEvaluationQueueSnapshot() async {
    await _backupManager.importEvaluationQueueSnapshot(context);
    if (mounted) setState(() {});
    _debugPanelSetState?.call(() {});
  }

  Future<void> _bulkImportEvaluationSnapshots() async {
    await _backupManager.bulkImportEvaluationSnapshots(context);
    if (mounted) setState(() {});
    _debugPanelSetState?.call(() {});
  }


  Future<void> _showDebugPanel() async {
    await _debugPrefs.setIsDebugPanelOpen(true);
    await showDialog<void>(
      context: context,
      builder: (context) => _DebugPanelDialog(parent: this),
    );
    await _debugPrefs.setIsDebugPanelOpen(false);
    _debugPanelSetState = null;
  }

  Future<void> _resetDebugPanelPreferences() async {
    await _debugPrefs.clearAll();
    if (_debugPrefs.snapshotRetentionEnabled) {
      await _cleanupOldEvaluationSnapshots();
    }
    lockService.safeSetState(this, () {});
    _debugPanelSetState?.call(() {});
  }

  void _prevStreetDebug() {
    lockService.safeSetState(this, _reverseStreet);
    _debugPanelSetState?.call(() {});
  }

  void _nextStreetDebug() {
    lockService.safeSetState(this, _advanceStreet);
    _debugPanelSetState?.call(() {});
  }


  SavedHand _currentSavedHand({String? name}) {
    final stacks =
        _potSync.calculateEffectiveStacksPerStreet(actions, numberOfPlayers);
    final collapsed = [
      for (int i = 0; i < 4; i++)
        if (!_expandedHistoryStreets.contains(i)) i
    ];
    return SavedHand(
      name: name ?? _defaultHandName(),
      heroIndex: _profile.heroIndex,
      heroPosition: _profile.heroPosition,
      numberOfPlayers: _playerManager.numberOfPlayers,
      playerCards: [
        for (int i = 0; i < _playerManager.numberOfPlayers; i++)
          List<CardModel>.from(_playerManager.playerCards[i])
      ],
      boardCards: List<CardModel>.from(_playerManager.boardCards),
      boardStreet: boardStreet,
      revealedCards: [
        for (int i = 0; i < _playerManager.numberOfPlayers; i++)
          [for (final c in _profile.players[i].revealedCards) if (c != null) c]
      ],
      opponentIndex: opponentIndex,
      activePlayerIndex: activePlayerIndex,
      actions: List<ActionEntry>.from(actions),
      stackSizes: Map<int, int>.from(_stackService.initialStacks),
      remainingStacks: {
        for (int i = 0; i < _playerManager.numberOfPlayers; i++)
          i: _stackService.getStackForPlayer(i)
      },
      playerPositions: Map<int, String>.from(_profile.playerPositions),
      playerTypes: Map<int, PlayerType>.from(_profile.playerTypes),
      comment: _handContext.commentController.text.isNotEmpty
          ? _handContext.commentController.text
          : null,
      tags: _handContext.tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      commentCursor: _handContext.commentController.selection.baseOffset >= 0
          ? _handContext.commentController.selection.baseOffset
          : null,
      tagsCursor: _handContext.tagsController.selection.baseOffset >= 0
          ? _handContext.tagsController.selection.baseOffset
          : null,
      isFavorite: false,
      date: DateTime.now(),
      effectiveStacksPerStreet: stacks,
      collapsedHistoryStreets: collapsed.isEmpty ? null : collapsed,
      foldedPlayers:
          _foldedPlayers.isEmpty ? null : List<int>.from(_foldedPlayers.players),
      actionTags:
          _actionTagService.tags.isEmpty ? null : Map<int, String?>.from(_actionTagService.tags),
      pendingEvaluations:
          _queueService.pending.isEmpty ? null : List<ActionEvaluationRequest>.from(_queueService.pending),
      playbackIndex: _playbackManager.playbackIndex,
    );
  }

  String saveHand() {
    _addQualityTags();
    final hand = _currentSavedHand();
    return jsonEncode(hand.toJson());
  }

  void loadHand(String jsonStr) {
    final hand = SavedHand.fromJson(jsonDecode(jsonStr));
    _stackService = _handRestore.restoreHand(hand);
    _actionSync.attachStackManager(_stackService);
    _potSync.stackService = _stackService;
    _actionSync.updatePlaybackIndex(_playbackManager.playbackIndex);
    _boardManager.startBoardTransition();
  }


  /// Load a training spot represented as a JSON-like map.
  ///
  /// Expected keys:
  /// - `playerCards`: List<List<Map>> where each map has `rank` and `suit`.
  /// - `boardCards`: same card maps for community cards.
  /// - `actions`: List of {street, playerIndex, action, amount}.
  /// - `heroIndex`: int specifying hero seat.
  /// - `numberOfPlayers`: total players at the table.
  /// - `playerTypes`: optional list of player type names.
  /// - `positions`: list of position strings for each player.
  /// - `stacks`: optional list of stack sizes.
  void loadTrainingSpot(Map<String, dynamic> data) {
    final pcData = data['playerCards'] as List? ?? [];
    final newCards =
        List.generate(playerCards.length, (_) => <CardModel>[]);
    for (var i = 0; i < pcData.length && i < playerCards.length; i++) {
      final list = pcData[i];
      if (list is List) {
        for (var j = 0; j < list.length && j < 2; j++) {
          final cardMap = list[j];
          if (cardMap is Map) {
            newCards[i].add(CardModel(
              rank: cardMap['rank'] as String,
              suit: cardMap['suit'] as String,
            ));
          }
        }
      }
    }

    final boardData = data['boardCards'] as List? ?? [];
    final newBoard = <CardModel>[];
    for (final c in boardData) {
      if (c is Map) {
        newBoard.add(
          CardModel(rank: c['rank'] as String, suit: c['suit'] as String),
        );
      }
    }

    final actionsData = data['actions'] as List? ?? [];
    final newActions = <ActionEntry>[];
    for (final a in actionsData) {
      if (a is Map) {
        newActions.add(ActionEntry(
          a['street'] as int,
          a['playerIndex'] as int,
          a['action'] as String,
          amount: (a['amount'] as num?)?.toInt(),
        ));
      }
    }


    final newHeroIndex = data['heroIndex'] as int? ?? 0;
    final newPlayerCount =
        data['numberOfPlayers'] as int? ?? pcData.length;

    final posList = (data['positions'] as List?)?.cast<String>() ?? [];
    final heroPos =
        newHeroIndex < posList.length ? posList[newHeroIndex] : _heroPosition;
    final newPositions = <int, String>{};
    for (var i = 0; i < posList.length; i++) {
      newPositions[i] = posList[i];
    }

    lockService.safeSetState(this, () {
      heroIndex = newHeroIndex;
      numberOfPlayers = newPlayerCount;
      _heroPosition = heroPos;

      for (final list in playerCards) {
        list.clear();
      }
      for (var i = 0; i < newCards.length; i++) {
      playerCards[i].addAll(newCards[i]);
      }

      boardCards
        ..clear()
        ..addAll(newBoard);

      actions
        ..clear()
        ..addAll(newActions);

      playerPositions
        ..clear()
        ..addAll(newPositions);

      _boardManager.changeStreet(0);
      _playbackManager.resetHand();
      _playbackManager.updatePlaybackState();
      _profile.updatePositions();
      _handContext.currentHandName = null;
    });
    _boardManager.startBoardTransition();
  }

  Future<void> saveCurrentHand() async {
    if (lockService.undoRedoTransitionLock || lockService.boardTransitioning) return;
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Название раздачи'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Введите название'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final handName = result.trim().isEmpty ? _defaultHandName() : result.trim();
    _addQualityTags();
    final hand = _currentSavedHand(name: handName);
    await _handManager.add(hand);
    lockService.safeSetState(this, () => _handContext.currentHandName = handName);
  }

  void loadLastSavedHand() {
    if (lockService.undoRedoTransitionLock || lockService.boardTransitioning) return;
    final hand = _handManager.lastHand;
    if (hand == null) return;
    _stackService = _handRestore.restoreHand(hand);
    _actionSync.attachStackManager(_stackService);
    _potSync.stackService = _stackService;
    _actionSync.updatePlaybackIndex(_playbackManager.playbackIndex);
    _boardManager.startBoardTransition();
  }

  Future<void> loadHandByName() async {
    if (lockService.undoRedoTransitionLock || lockService.boardTransitioning) return;
    final selected = await _handManager.selectHand(context);
      if (selected != null) {
        _stackService = _handRestore.restoreHand(selected);
        _actionSync.attachStackManager(_stackService);
        _potSync.stackService = _stackService;
        _actionSync.updatePlaybackIndex(_playbackManager.playbackIndex);
        _boardManager.startBoardTransition();
      }
  }


  Future<void> exportLastSavedHand() async {
    if (lockService.undoRedoTransitionLock || lockService.boardTransitioning) return;
    await _handManager.exportLastHand(context);
  }

  Future<void> exportAllHands() async {
    if (lockService.undoRedoTransitionLock || lockService.boardTransitioning) return;
    await _handManager.exportAllHands(context);
  }

  Future<void> importHandFromClipboard() async {
    if (lockService.undoRedoTransitionLock || lockService.boardTransitioning) return;
    final hand = await _handManager.importHandFromClipboard(context);
    if (hand != null) {
      _stackService = _handRestore.restoreHand(hand);
      _actionSync.attachStackManager(_stackService);
      _potSync.stackService = _stackService;
      _actionSync.updatePlaybackIndex(_playbackManager.playbackIndex);
      _boardManager.startBoardTransition();
    }
  }

  Future<void> importAllHandsFromClipboard() async {
    if (lockService.undoRedoTransitionLock || lockService.boardTransitioning) return;
    await _handManager.importAllHandsFromClipboard(context);
  }



  @override
  void dispose() {
    _activeTimer?.cancel();
    _playerManager.removeListener(_onPlayerManagerChanged);
    _playbackManager.removeListener(_onPlaybackManagerChanged);
    _centerChipTimer?.cancel();
    _queueService.cleanup();
    _centerChipController.dispose();
    _timelineController.dispose();
    _backupManager.dispose();
    _handContext.dispose();
    super.dispose();
  }





  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final visibleActions =
        actions.take(_playbackManager.playbackIndex).toList();
    final savedActions = _currentSavedHand().actions;
    final double scale =
        TableGeometryHelper.tableScale(numberOfPlayers);
    final viewIndex = _viewIndex();
    final double infoScale = numberOfPlayers > 8 ? 0.85 : 1.0;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 -
        TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    final effectiveStack =
        _potSync.calculateEffectiveStack(currentStreet, visibleActions);
    final currentStreetEffectiveStack = _potSync
        .calculateEffectiveStackForStreet(currentStreet, visibleActions, numberOfPlayers);
    final pot = _playbackManager.pots[currentStreet];
    final double? sprValue =
        pot > 0 ? effectiveStack / pot : null;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            children: [
            _HandHeaderSection(
              handName: _handContext.currentHandName ?? 'New Hand',
              playerCount: numberOfPlayers,
              streetName: ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'][currentStreet],
              onEdit: loadHandByName,
            ),
            _PlayerCountSelector(
              numberOfPlayers: numberOfPlayers,
              playerPositions: playerPositions,
              playerTypes: playerTypes,
              onChanged: lockService.boardTransitioning ? null : _onPlayerCountChanged,
              disabled: lockService.boardTransitioning,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                'Effective Stack (Current Street): $currentStreetEffectiveStack BB',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            Expanded(
              flex: 7,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Stack(
                  children: [
                  _TableBackgroundSection(scale: scale),
                  AbsorbPointer(
                    absorbing: lockService.boardTransitioning,
                    child: _BoardCardsSection(
                      key: _boardKey,
                      scale: scale,
                      currentStreet: currentStreet,
                      boardCards: boardCards,
                      revealedBoardCards: _boardSync.revealedBoardCards,
                      onCardSelected: selectBoardCard,
                      onCardLongPress: _removeBoardCard,
                      canEditBoard: (i) => _boardEditing.canEditBoard(context, i),
                      usedCards: _boardEditing.usedCardKeys(),
                      editingDisabled: lockService.boardTransitioning,
                      visibleActions: visibleActions,
                      boardReveal: widget.boardReveal,
                    ),
                  ),
                  _PlayerZonesSection(
                    numberOfPlayers: numberOfPlayers,
                    scale: scale,
                    playerPositions: playerPositions,
                    opponentCardRow: AbsorbPointer(
                      absorbing: lockService.boardTransitioning,
                      child: _OpponentCardRowSection(
                        scale: scale,
                        players: players,
                        activePlayerIndex: activePlayerIndex,
                        opponentIndex: opponentIndex,
                        onCardTap:
                            lockService.boardTransitioning ? null : _onOpponentCardTap,
                      ),
                    ),
                    playerBuilder: _buildPlayerWidgets,
                    chipTrailBuilder: _buildChipTrail,
                  ),
                  _BetStacksOverlaySection(
                    scale: scale,
                    state: this,
                  ),
                  _InvestedChipsOverlaySection(
                    scale: scale,
                    state: this,
                  ),
                  _PotAndBetsOverlaySection(
                    scale: scale,
                    numberOfPlayers: numberOfPlayers,
                    currentStreet: currentStreet,
                    viewIndex: viewIndex,
                    actions: actions,
                    pots: _playbackManager.pots,
                    animatedPlayersPerStreet:
                        _playbackManager.animatedPlayersPerStreet,
                    centerChipAction: _centerChipAction,
                    showCenterChip: _showCenterChip,
                    centerChipController: _centerChipController,
                    actionColor: ActionFormattingHelper.actionColor,
                  ),
                  _ActionHistorySection(
                    actions: actions,
                    playbackIndex: _playbackManager.playbackIndex,
                    playerPositions: playerPositions,
                    expandedStreets: _expandedHistoryStreets,
                    onToggleStreet: (index) {
                      lockService.safeSetState(this, () {
                        if (_expandedHistoryStreets.contains(index)) {
                          _actionSync.removeExpandedStreet(index);
                        } else {
                          _actionSync.addExpandedStreet(index);
                        }
                      });
                    },
                  ),
                  _PerspectiveSwitchButton(
                    isPerspectiveSwitched: isPerspectiveSwitched,
                    onToggle: () => lockService.safeSetState(this, 
                        () => isPerspectiveSwitched = !isPerspectiveSwitched),
                  ),
                  _HudOverlaySection(
                    streetName:
                        ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'][currentStreet],
                    potText: ActionFormattingHelper
                        .formatAmount(_playbackManager.pots[currentStreet]),
                    stackText:
                        ActionFormattingHelper.formatAmount(effectiveStack),
                    sprText: sprValue != null
                        ? 'SPR: ${sprValue.toStringAsFixed(1)}'
                        : null,
                  ),
                  if (lockService.boardTransitioning)
                    const _BoardTransitionBusyIndicator(),
                _RevealAllCardsButton(
                  showAllRevealedCards: _debugPrefs.showAllRevealedCards,
                  onToggle: () async {
                    await _debugPrefs.setShowAllRevealedCards(
                        !_debugPrefs.showAllRevealedCards);
                    lockService.safeSetState(this, () {});
                  },
                )
              ],
        ),
      ),
    ),
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: AbsorbPointer(
        absorbing: lockService.boardTransitioning,
        child: Column(
          children: List.generate(
            4,
            (i) => CollapsibleStreetSection(
              street: i,
              actions: savedActions,
              pots: _playbackManager.pots,
              stackSizes: _stackService.stackSizes,
              playerPositions: playerPositions,
              onEdit: _editAction,
              onDelete: _deleteAction,
              visibleCount: _playbackManager.playbackIndex,
              evaluateActionQuality: _evaluateActionQuality,
            ),
          ),
        ),
      ),
    ),
    AbsorbPointer(
      absorbing: lockService.boardTransitioning,
      child: ActionHistoryExpansionTile(
        actions: visibleActions,
        playerPositions: playerPositions,
        pots: _playbackManager.pots,
        stackSizes: _stackService.stackSizes,
        onEdit: _editAction,
      onDelete: _deleteAction,
      visibleCount: _playbackManager.playbackIndex,
      evaluateActionQuality: _evaluateActionQuality,
    ),
    StreetActionsWidget(
      currentStreet: currentStreet,
      canGoPrev: _canReverseStreet(),
      onPrevStreet:
          lockService.boardTransitioning ? null : () => lockService.safeSetState(this, _reverseStreet),
      onStreetChanged: (index) {
        if (lockService.boardTransitioning) return;
        lockService.safeSetState(this, () {
          _recordSnapshot();
          _changeStreet(index);
        });
      },
            ),
            AbsorbPointer(
              absorbing: lockService.boardTransitioning,
              child: StreetActionInputWidget(
                currentStreet: currentStreet,
                numberOfPlayers: numberOfPlayers,
                actions: actions,
                playerPositions: playerPositions,
                onAdd: onActionSelected,
                onEdit: _editAction,
                onDelete: _deleteAction,
              ),
            ),
            AbsorbPointer(
              absorbing: lockService.boardTransitioning,
              child: ActionTimelineWidget(
                actions: visibleActions,
                playbackIndex: _playbackManager.playbackIndex,
                onTap: (index) {
                  lockService.safeSetState(this, () {
                    _playbackManager.seek(index);
                    _playbackManager.updatePlaybackState(); // Перестраиваем экран
                  });
                },
                playerPositions: playerPositions,
                controller: _timelineController,
                scale: scale,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _PlaybackAndHandControls(
                isPlaying: _playbackManager.isPlaying,
                playbackIndex: _playbackManager.playbackIndex,
                actionCount: actions.length,
                onPlay: _play,
                onPause: _pause,
                onStepBackward: _stepBackwardPlayback,
                onStepForward: _stepForwardPlayback,
                onSeek: _seekPlayback,
                onSave: () => saveCurrentHand(),
                onLoadLast: loadLastSavedHand,
                onLoadByName: () => loadHandByName(),
                onExportLast: exportLastSavedHand,
                onExportAll: exportAllHands,
                onImport: importHandFromClipboard,
                onImportAll: importAllHandsFromClipboard,
                onReset: _resetHand,
                disabled: lockService.boardTransitioning || lockService.undoRedoTransitionLock,
              ),
            ),
            Expanded(
              child: AbsorbPointer(
                absorbing: lockService.boardTransitioning,
                child: _HandEditorSection(
                  historyActions: visibleActions,
                  playerPositions: playerPositions,
                  heroIndex: heroIndex,
                  commentController: _handContext.commentController,
                  tagsController: _handContext.tagsController,
                  currentStreet: currentStreet,
                  actions: actions,
                  pots: _playbackManager.pots,
                  stackSizes: _stackService.stackSizes,
                  onEdit: _editAction,
                  onDelete: _deleteAction,
                  visibleCount: _playbackManager.playbackIndex,
                  evaluateActionQuality: _evaluateActionQuality,
                  onAnalyze: () {},
                ),
              ),
            ),
          ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'playFab',
            onPressed: () {
              final data = {
                'playerCards': [
                  [
                    {'rank': 'A', 'suit': 'h'},
                    {'rank': 'K', 'suit': 'h'},
                  ],
                  [
                    {'rank': 'Q', 'suit': 's'},
                    {'rank': 'Q', 'suit': 'd'},
                  ],
                  [
                    {'rank': 'J', 'suit': 'c'},
                    {'rank': 'J', 'suit': 'd'},
                  ],
                ],
                'boardCards': [
                  {'rank': '2', 'suit': 'h'},
                  {'rank': '7', 'suit': 'd'},
                  {'rank': 'T', 'suit': 's'},
                ],
                'actions': [
                  {
                    'street': 1,
                    'playerIndex': 0,
                    'action': 'bet',
                    'amount': 40,
                  },
                ],
                'positions': ['BTN', 'SB', 'BB'],
                'heroIndex': 0,
                'numberOfPlayers': 3,
              };
              loadTrainingSpot(data);
            },
            child: const Icon(Icons.play_arrow),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'debugFab',
            onPressed: _showDebugPanel,
            child: const Icon(Icons.bug_report),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPlayerWidgets(int i, double scale) {
    final screenSize = MediaQuery.of(context).size;
    final double infoScale = numberOfPlayers > 8 ? 0.85 : 1.0;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 -
        TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final radiusMod =
        TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    final visibleActions =
        actions.take(_playbackManager.playbackIndex).toList();

    ActionEntry? lastStreetAction;
    for (final a in visibleActions.reversed) {
      if (a.street == currentStreet) {
        lastStreetAction = a;
        break;
      }
    }

    final index = (i + _viewIndex()) % numberOfPlayers;
    final angle = 2 * pi * i / numberOfPlayers + pi / 2;
    final dx = radiusX * cos(angle);
    final dy = radiusY * sin(angle);
    final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;

    final String position = playerPositions[index] ?? '';
    final int stack = _stackService.stackSizes[index] ?? 0;
    final String tag = _actionTagService.getTag(index) ?? '';
    final bool isActive = activePlayerIndex == index;
    final bool isFolded = _foldedPlayers.contains(index);

    ActionEntry? lastAction;
    for (final a in visibleActions.reversed) {
      if (a.playerIndex == index && a.street == currentStreet) {
        lastAction = a;
        break;
      }
    }

    ActionEntry? lastAmountAction;
    for (final a in visibleActions.reversed) {
      if (a.playerIndex == index &&
          a.street == currentStreet &&
          (a.action == 'bet' ||
              a.action == 'raise' ||
              a.action == 'call' ||
              a.action == 'all-in') &&
          a.amount != null) {
        lastAmountAction = a;
        break;
      }
    }
    final int currentBet = lastAmountAction?.amount ?? 0;

    final invested =
        _stackService.getInvestmentForStreet(index, currentStreet);

    final Color? actionColor =
        (lastAction?.action == 'bet' || lastAction?.action == 'raise')
            ? Colors.green
            : lastAction?.action == 'call'
                ? Colors.blue
                : null;
    final double maxRadius = 36 * scale;
    final double radius = (_playbackManager.pots[currentStreet] > 0)
        ? min(
            maxRadius,
            (invested / _playbackManager.pots[currentStreet]) * maxRadius,
          )
        : 0.0;

    final widgets = <Widget>[
      if (isActive)
        _ActivePlayerHighlight(
          position: Offset(centerX + dx, centerY + dy),
          scale: scale * infoScale,
          bias: bias,
        ),
      // action arrow behind player widgets
      Positioned(
        left: centerX + dx,
        top: centerY + dy + bias + 12,
        child: IgnorePointer(
          child: AnimatedOpacity(
            opacity: (lastStreetAction != null &&
                    lastStreetAction!.playerIndex == index &&
                    (lastStreetAction!.action == 'bet' ||
                        lastStreetAction!.action == 'raise' ||
                        lastStreetAction!.action == 'call'))
                ? 1.0
                : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Transform.rotate(
              angle: atan2(
                  centerY - (centerY + dy + bias + 12),
                  centerX - (centerX + dx)),
              alignment: Alignment.topLeft,
              child: Container(
                width: sqrt(pow(centerX - (centerX + dx), 2) +
                    pow(centerY - (centerY + dy + bias + 12), 2)),
                height: 1,
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withOpacity(0.6),
                      blurRadius: 4,
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: centerX + dx - 55 * scale * infoScale,
        top: centerY + dy + bias - 55 * scale * infoScale,
        child: Transform.scale(
          scale: infoScale,
          child: AbsorbPointer(
            absorbing: lockService.boardTransitioning,
            child: PlayerInfoWidget(
            position: position,
            stack: stack,
            tag: tag,
            cards: _debugPrefs.showAllRevealedCards &&
                    players[index]
                        .revealedCards
                        .whereType<CardModel>()
                        .isNotEmpty
                ? players[index]
                    .revealedCards
                    .whereType<CardModel>()
                    .toList()
                : playerCards[index],
            remainingStack: _stackService.getStackForPlayer(index),
            streetInvestment: invested,
            currentBet: currentBet,
            lastAction: lastAction?.action,
            showLastIndicator: lastStreetAction?.playerIndex == index,
            isActive: isActive,
            isFolded: isFolded,
            isHero: index == _profile.heroIndex,
            isOpponent: index == opponentIndex,
            playerTypeIcon: '',
            playerTypeLabel: _playerManager.numberOfPlayers > 9
                ? null
                : _playerTypeLabel(_profile.playerTypes[index]),
            positionLabel:
                _playerManager.numberOfPlayers <= 9
                    ? _positionLabelForIndex(index)
                    : null,
            blindLabel: (_profile.playerPositions[index] == 'SB' ||
                    _profile.playerPositions[index] == 'BB')
                ? _profile.playerPositions[index]
                : null,
            timersDisabled: lockService.boardTransitioning,
            onCardTap: lockService.boardTransitioning
                ? null
                : (cardIndex) => _onPlayerCardTap(index, cardIndex),
            onTap: () => _onPlayerTap(index),
            onDoubleTap: lockService.boardTransitioning
                ? null
                : () => _setHeroIndex(index),
            onLongPress: lockService.boardTransitioning ? null : () => _editPlayerInfo(index),
            onEdit: lockService.boardTransitioning ? null : () => _editPlayerInfo(index),
            onStackTap: lockService.boardTransitioning
                ? null
                : (value) => lockService.safeSetState(this, () {
                      _playerManager.setInitialStack(index, value);
                      _stackService
                          .reset(Map<int, int>.from(_playerManager.initialStacks));
                      _playbackManager.updatePlaybackState();
                    }),
            onRemove: _playerManager.numberOfPlayers > 2 && !lockService.boardTransitioning
                ? () {
                    _removePlayer(index);
                  }
                : null,
            onTimeExpired: () => _onPlayerTimeExpired(index),
          ),
        ),
        ),
      ),
      Positioned(
        left: centerX + dx - 8 * scale,
        top: centerY + dy + bias - 70 * scale,
        child: _playerTypeIcon(_profile.playerTypes[index]),
      ),
      if (lastAmountAction != null)
        Positioned(
          left: centerX + dx - 24 * scale,
          top: centerY + dy + bias - 80 * scale,
          child: ChipAmountWidget(
            amount: lastAmountAction!.amount!.toDouble(),
            color: ActionFormattingHelper.actionColor(
                lastAmountAction!.action),
            scale: scale,
          ),
        ),
      Positioned(
        left: centerX + dx - 12 * scale,
        top: centerY + dy + bias + 70 * scale,
        child: PlayerStackChips(
          stack: stack,
          scale: scale * 0.9,
        ),
      ),
      Positioned(
        left: centerX + dx - 20 * scale,
        top: centerY + dy + bias + 84 * scale,
        child: Text(
          '$stack BB',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12 * scale,
            shadows: const [Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2)],
          ),
        ),
      ),
      Positioned(
        left: centerX + dx + (cos(angle) < 0 ? -45 * scale : 30 * scale),
        top: centerY + dy + bias + 50 * scale,
        child: MiniStackWidget(
          stack: stack,
          scale: scale * 0.8,
        ),
      ),
      if (lastAction != null)
        Positioned(
          left: centerX + dx - 30 * scale,
          top: centerY + dy + bias + 90 * scale,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: 6 * scale, vertical: 2 * scale),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              lastAction!.amount != null
                  ? '${lastAction!.action.toUpperCase()} ${lastAction!.amount}'
                  : lastAction!.action.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12 * scale,
              ),
            ),
          ),
        ),
      Positioned(
        left: centerX + dx - 20 * scale,
        top: centerY + dy + bias + 60 * scale,
        child: Container(
          width: 40 * scale,
          padding: const EdgeInsets.symmetric(vertical: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey.shade700,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            position,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10 * scale,
            ),
          ),
        ),
      ),
      if (lastAction != null)
        Positioned(
          left: centerX + dx + 40 * scale,
          top: centerY + dy + bias - 60 * scale,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 16 * scale,
            onPressed: () => _removeLastPlayerAction(index),
            icon: const Text('❌', style: TextStyle(color: Colors.redAccent)),
          ),
        ),
    ];

    if (invested > 0) {
      if (_playbackManager.pots[currentStreet] > 0 &&
          (lastAction?.action == 'bet' ||
              lastAction?.action == 'raise' ||
              lastAction?.action == 'call')) {
        widgets.add(Positioned(
          left: centerX + dx - radius,
          top: centerY + dy + bias + 112 * scale - radius,
          child: AnimatedSwitcher(
            duration: _boardRevealDuration,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: AnimatedContainer(
              key: ValueKey(radius),
              duration: const Duration(milliseconds: 300),
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: actionColor!.withOpacity(0.2),
              ),
            ),
          ),
        ));
      }
      widgets.add(Positioned(
        left: centerX + dx - 20 * scale,
        top: centerY + dy + bias + 92 * scale,
        child: InvestedChipTokens(
          amount: invested,
          color: actionColor ?? Colors.green,
          scale: scale,
        ),
      ));
    }

    if (_debugPrefs.debugLayout) {
      widgets.add(Positioned(
        left: centerX + dx - 40 * scale,
        top: centerY + dy + bias - 70 * scale,
        child: Container(
          padding: const EdgeInsets.all(2),
          color: Colors.black45,
          child: Text(
            'a:${angle.toStringAsFixed(2)}\n${dx.toStringAsFixed(1)},${dy.toStringAsFixed(1)}',
            style: TextStyle(color: Colors.yellow, fontSize: 9 * scale),
            textAlign: TextAlign.center,
          ),
        ),
      ));
    }

    return widgets;
  }

  List<Widget> _buildChipTrail(int i, double scale) {
    final screenSize = MediaQuery.of(context).size;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 -
        TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    final visibleActions =
        actions.take(_playbackManager.playbackIndex).toList();

    final index = (i + _viewIndex()) % numberOfPlayers;
    final angle = 2 * pi * i / numberOfPlayers + pi / 2;
    final dx = radiusX * cos(angle);
    final dy = radiusY * sin(angle);
    final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;

    ActionEntry? lastAction;
    for (final a in visibleActions.reversed) {
      if (a.playerIndex == index && a.street == currentStreet) {
        lastAction = a;
        break;
      }
    }

    final invested =
        _stackService.getInvestmentForStreet(index, currentStreet);

    final Color? actionColor =
        (lastAction?.action == 'bet' || lastAction?.action == 'raise')
            ? Colors.green
            : lastAction?.action == 'call'
                ? Colors.blue
                : null;

    final bool showTrail = invested > 0 &&
        (lastAction != null &&
            (lastAction!.action == 'bet' ||
                lastAction!.action == 'raise' ||
                lastAction!.action == 'call'));

    if (!showTrail) return [];

    final fraction = _playbackManager.pots[currentStreet] > 0
        ? invested / _playbackManager.pots[currentStreet]
        : 0.0;
    final trailCount = 3 + (fraction * 2).clamp(0, 2).round();

    return [
      Positioned.fill(
        child: ChipTrail(
          start: Offset(centerX + dx, centerY + dy + bias + 92 * scale),
          end: Offset(centerX, centerY),
          chipCount: trailCount,
          visible: showTrail,
          scale: scale,
          color: actionColor ?? Colors.green,
        ),
      )
    ];
  }
}

class _ActivePlayerHighlight extends StatelessWidget {
  final Offset position;
  final double scale;
  final double bias;

  const _ActivePlayerHighlight({
    required this.position,
    required this.scale,
    required this.bias,
  });

  @override
  Widget build(BuildContext context) {
    final double avatarRadius = 55 * scale;
    final double highlightRadius = avatarRadius + 6 * scale;
    return Positioned(
      left: position.dx - highlightRadius,
      top: position.dy + bias - highlightRadius,
      child: IgnorePointer(
        child: Container(
          width: highlightRadius * 2,
          height: highlightRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.green.withOpacity(0.6),
              width: 4 * scale,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.4),
                blurRadius: 12 * scale,
                spreadRadius: 4 * scale,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerZonesSection extends StatelessWidget {
  final int numberOfPlayers;
  final double scale;
  final Map<int, String> playerPositions;
  final Widget opponentCardRow;
  final List<Widget> Function(int, double) playerBuilder;
  final List<Widget> Function(int, double) chipTrailBuilder;

  const _PlayerZonesSection({
    required this.numberOfPlayers,
    required this.scale,
    required this.playerPositions,
    required this.opponentCardRow,
    required this.playerBuilder,
    required this.chipTrailBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        opponentCardRow,
        for (int i = 0; i < numberOfPlayers; i++) ...playerBuilder(i, scale),
        for (int i = 0; i < numberOfPlayers; i++) ...chipTrailBuilder(i, scale),
      ],
    );
  }
}

class _OpponentCardRowSection extends StatelessWidget {
  final double scale;
  final List<PlayerModel> players;
  final int? activePlayerIndex;
  final int? opponentIndex;
  final void Function(int)? onCardTap;

  const _OpponentCardRowSection({
    required this.scale,
    required this.players,
    required this.activePlayerIndex,
    required this.opponentIndex,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: const Alignment(0, -0.8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(2, (i) {
            final idx = opponentIndex ?? activePlayerIndex;
            final list = idx != null
                ? players[idx].revealedCards
                : List<CardModel?>.filled(2, null);
            final card = list[i];
            final isRed = card?.suit == '♥' || card?.suit == '♦';
            return GestureDetector(
              onTap: onCardTap != null ? () => onCardTap!(i) : null,
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 36 * scale,
                height: 52 * scale,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(card == null ? 0.3 : 1),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 3,
                      offset: const Offset(1, 2),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: card != null
                    ? Text(
                        '${card.rank}${card.suit}',
                        style: TextStyle(
                          color: isRed ? Colors.red : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18 * scale,
                        ),
                      )
                    : Image.asset(
                        'assets/cards/card_back.png',
                        fit: BoxFit.cover,
                      ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _TableBackgroundSection extends StatelessWidget {
  final double scale;

  const _TableBackgroundSection({
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final tableWidth = screenSize.width * 0.9 * scale;

    return Center(
      child: Image.asset(
        'assets/table.png',
        width: tableWidth,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _PotAndBetsOverlaySection extends StatelessWidget {
  final double scale;
  final int numberOfPlayers;
  final int currentStreet;
  final int viewIndex;
  final List<ActionEntry> actions;
  final List<int> pots;
  final Map<int, Set<int>> animatedPlayersPerStreet;
  final ActionEntry? centerChipAction;
  final bool showCenterChip;
  final Animation<double> centerChipController;
  final Color Function(String) actionColor;

  const _PotAndBetsOverlaySection({
    required this.scale,
    required this.numberOfPlayers,
    required this.currentStreet,
    required this.viewIndex,
    required this.actions,
    required this.pots,
    required this.animatedPlayersPerStreet,
    required this.centerChipAction,
    required this.showCenterChip,
    required this.centerChipController,
    required this.actionColor,
  });


  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 -
        TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    final List<Widget> items = [];

    final pot = pots[currentStreet];
    if (pot > 0) {
      items.add(
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: const Alignment(0, -0.05),
              child: Transform.translate(
                offset: Offset(0, -12 * scale),
                child: CentralPotChips(
                  amount: pot,
                  scale: scale,
                ),
              ),
            ),
          ),
        ),
      );
      items.add(
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: PotDisplayWidget(
                amount: pot,
                scale: scale,
              ),
            ),
          ),
        ),
      );
    }

    if (centerChipAction != null) {
      items.add(
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: AnimatedOpacity(
                opacity: showCenterChip ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: ScaleTransition(
                  scale: centerChipController,
                  child: ChipAmountWidget(
                    amount: centerChipAction!.amount!.toDouble(),
                    color: actionColor(centerChipAction!.action),
                    scale: scale,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (int i = 0; i < numberOfPlayers; i++) {
      final index = (i + viewIndex) % numberOfPlayers;
      final playerActions =
          actions.where((a) => a.playerIndex == index && a.street == currentStreet).toList();
      if (playerActions.isEmpty) continue;
      final lastAction = playerActions.last;
      if (['bet', 'raise', 'call'].contains(lastAction.action) && lastAction.amount != null) {
        final angle = 2 * pi * i / numberOfPlayers + pi / 2;
        final dx = radiusX * cos(angle);
        final dy = radiusY * sin(angle);
        final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
        final start = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
        final end = Offset(centerX, centerY);
        final streetSet =
            animatedPlayersPerStreet.putIfAbsent(currentStreet, () => <int>{});
        final animate = !streetSet.contains(index);
        if (animate) {
          streetSet.add(index);
        }
        items.add(
          Positioned.fill(
            child: BetChipsOnTable(
              start: start,
              end: end,
              chipCount: (lastAction.amount! / 20).clamp(1, 5).round(),
              color: actionColor(lastAction.action),
              scale: scale,
              animate: animate,
            ),
          ),
        );
        items.add(
          Positioned(
            left: centerX + dx + 40 * scale,
            top: centerY + dy + bias - 40 * scale,
            child: PlayerBetIndicator(
              action: lastAction.action,
              amount: lastAction.amount!,
              scale: scale,
            ),
          ),
        );
        final stackPos = Offset.lerp(start, end, 0.15)!;
        final stackScale = scale * 0.7;
        items.add(
          Positioned(
            left: stackPos.dx - 6 * stackScale,
            top: stackPos.dy - 12 * stackScale,
            child: ChipStackWidget(
              amount: lastAction.amount!,
              scale: stackScale,
              color: actionColor(lastAction.action),
            ),
          ),
        );
      }
    }

    return Stack(children: items);
  }
}

class _BetStacksOverlaySection extends StatelessWidget {
  final double scale;
  final _PokerAnalyzerScreenState state;

  const _BetStacksOverlaySection({
    required this.scale,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(state.context).size;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 -
        TableGeometryHelper.centerYOffset(state.numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(state.numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    final List<Widget> chips = [];
    for (int i = 0; i < state.numberOfPlayers; i++) {
      final index = (i + state._viewIndex()) % state.numberOfPlayers;
      final invested =
          state._stackService.getInvestmentForStreet(index, state.currentStreet);
      if (invested > 0) {
        final angle = 2 * pi * i / state.numberOfPlayers + pi / 2;
        final dx = radiusX * cos(angle);
        final dy = radiusY * sin(angle);
        final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;

        final start = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
        final pos = Offset.lerp(start, Offset(centerX, centerY), 0.15)!;

        final chipScale = scale * 0.8;
        chips.add(Positioned(
          left: pos.dx - 8 * chipScale,
          top: pos.dy - 8 * chipScale,
          child: BetStackChips(amount: invested, scale: chipScale),
        ));
      }
    }
    return Stack(children: chips);
  }
}

class _InvestedChipsOverlaySection extends StatelessWidget {
  final double scale;
  final _PokerAnalyzerScreenState state;

  const _InvestedChipsOverlaySection({
    required this.scale,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(state.context).size;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 -
        TableGeometryHelper.centerYOffset(state.numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(state.numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    final List<Widget> chips = [];
    for (int i = 0; i < state.numberOfPlayers; i++) {
      final index = (i + state._viewIndex()) % state.numberOfPlayers;
      final invested =
          state._stackService.getInvestmentForStreet(index, state.currentStreet);
      if (invested > 0) {
        final angle = 2 * pi * i / state.numberOfPlayers + pi / 2;
        final dx = radiusX * cos(angle);
        final dy = radiusY * sin(angle);
        final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;

        final playerActions = state.actions
            .where((a) =>
                a.playerIndex == index && a.street == state.currentStreet)
            .toList();
        final lastAction =
            playerActions.isNotEmpty ? playerActions.last : null;
        final color =
            ActionFormattingHelper.actionColor(lastAction?.action ?? 'bet');
        final start =
            Offset(centerX + dx, centerY + dy + bias + 92 * scale);
        final end = Offset.lerp(start, Offset(centerX, centerY), 0.2)!;
        final streetSet = state._playbackManager.animatedPlayersPerStreet
            .putIfAbsent(state.currentStreet, () => <int>{});
        final animate = !streetSet.contains(index);
        if (animate) {
          streetSet.add(index);
        }
        chips.add(Positioned.fill(
          child: BetChipsOnTable(
            start: start,
            end: end,
            chipCount: (invested / 20).clamp(1, 5).round(),
            color: color,
            scale: scale,
            animate: animate,
          ),
        ));
      }
    }
    return Stack(children: chips);
  }
}

class _ActionHistorySection extends StatelessWidget {
  final List<ActionEntry> actions;
  final int playbackIndex;
  final Map<int, String> playerPositions;
  final Set<int> expandedStreets;
  final ValueChanged<int> onToggleStreet;

  const _ActionHistorySection({
    required this.actions,
    required this.playbackIndex,
    required this.playerPositions,
    required this.expandedStreets,
    required this.onToggleStreet,
  });

  @override
  Widget build(BuildContext context) {
    return ActionHistoryOverlay(
      actions: actions,
      playbackIndex: playbackIndex,
      playerPositions: playerPositions,
      expandedStreets: expandedStreets,
      onToggleStreet: onToggleStreet,
    );
  }
}


class _BoardCardsSection extends StatefulWidget {
  final double scale;
  final int currentStreet;
  final List<CardModel> boardCards;
  final List<CardModel> revealedBoardCards;
  final List<ActionEntry> visibleActions;
  final void Function(int, CardModel) onCardSelected;
  final void Function(int) onCardLongPress;
  final bool Function(int index)? canEditBoard;
  final Set<String> usedCards;
  final bool editingDisabled;
  final BoardRevealService boardReveal;

  const _BoardCardsSection({
    Key? key,
    required this.scale,
    required this.currentStreet,
    required this.boardCards,
    required this.revealedBoardCards,
    required this.onCardSelected,
    required this.onCardLongPress,
    required this.visibleActions,
    required this.boardReveal,
    this.canEditBoard,
    this.usedCards = const {},
    this.editingDisabled = false,
  }) : super(key: key);

  @override
  State<_BoardCardsSection> createState() => _BoardCardsSectionState();
}

class _BoardCardsSectionState extends State<_BoardCardsSection>
    with TickerProviderStateMixin {
  late int _prevStreet;
  late final BoardRevealService _reveal;

  @override
  void initState() {
    super.initState();
    _prevStreet = widget.currentStreet;
    _reveal = widget.boardReveal;
    _reveal.attachTicker(this);
    _reveal.updateAnimations();
  }

  @override
  void didUpdateWidget(covariant _BoardCardsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStreet != widget.currentStreet) {
      _prevStreet = oldWidget.currentStreet;
    }
    _reveal.updateAnimations();
  }

  void cancelPendingReveals() {
    _reveal.cancelBoardReveal();
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reversing = widget.currentStreet < _prevStreet;
    return AnimatedSwitcher(
      duration: _boardRevealDuration,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: reversing ? const Offset(0, -0.1) : const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: BoardDisplay(
        key: ValueKey(widget.currentStreet),
        scale: widget.scale,
        currentStreet: widget.currentStreet,
        boardCards: widget.boardCards,
        revealedBoardCards: widget.revealedBoardCards,
        revealAnimations: _reveal.animations,
        onCardSelected: widget.onCardSelected,
        onCardLongPress: widget.onCardLongPress,
        canEditBoard: widget.canEditBoard,
        usedCards: widget.usedCards,
        editingDisabled: widget.editingDisabled,
        visibleActions: widget.visibleActions,
      ),
    );
  }
}
class _HudOverlaySection extends StatelessWidget {
  final String streetName;
  final String potText;
  final String stackText;
  final String? sprText;

  const _HudOverlaySection({
    required this.streetName,
    required this.potText,
    required this.stackText,
    this.sprText,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: HudOverlay(
        streetName: streetName,
        potText: potText,
        stackText: stackText,
        sprText: sprText,
      ),
    );
  }
}

class _BoardTransitionBusyIndicator extends StatelessWidget {
  const _BoardTransitionBusyIndicator();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black38,
        child: const Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

class _PerspectiveSwitchButton extends StatelessWidget {
  final bool isPerspectiveSwitched;
  final VoidCallback onToggle;

  const _PerspectiveSwitchButton({
    required this.isPerspectiveSwitched,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: TextButton(
        onPressed: onToggle,
        child: const Text(
          '👁 Смотреть от лица',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _PlaybackControlsSection extends StatelessWidget {
  final bool isPlaying;
  final int playbackIndex;
  final int actionCount;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onStepBackward;
  final VoidCallback onStepForward;
  final ValueChanged<double> onSeek;
  final VoidCallback onReset;
  final bool disabled;

  const _PlaybackControlsSection({
    required this.isPlaying,
    required this.playbackIndex,
    required this.actionCount,
    required this.onPlay,
    required this.onPause,
    required this.onStepBackward,
    required this.onStepForward,
    required this.onSeek,
    required this.onReset,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = disabled ? Colors.grey : Colors.white;

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.skip_previous, color: iconColor),
              onPressed: disabled ? null : onStepBackward,
            ),
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: iconColor,
              ),
              onPressed:
                  disabled ? null : (isPlaying ? onPause : onPlay),
            ),
            IconButton(
              icon: Icon(Icons.skip_next, color: iconColor),
              onPressed: disabled ? null : onStepForward,
            ),
            Expanded(
              child: Slider(
                value: playbackIndex.toDouble(),
                min: 0,
                max: actionCount > 0 ? actionCount.toDouble() : 1,
                onChanged: disabled ? null : onSeek,
                inactiveColor: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onReset,
          child: const Text('Сбросить раздачу'),
        ),
      ],
    );
  }
}

class _SaveLoadControlsSection extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onLoadLast;
  final VoidCallback onLoadByName;
  final VoidCallback onExportLast;
  final VoidCallback onExportAll;
  final VoidCallback onImport;
  final VoidCallback onImportAll;
  final bool disabled;

  const _SaveLoadControlsSection({
    required this.onSave,
    required this.onLoadLast,
    required this.onLoadByName,
    required this.onExportLast,
    required this.onExportAll,
    required this.onImport,
    required this.onImportAll,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = disabled ? Colors.grey : Colors.white;
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.save, color: iconColor),
          onPressed: disabled ? null : onSave,
        ),
        IconButton(
          icon: Icon(Icons.folder_open, color: iconColor),
          onPressed: disabled ? null : onLoadLast,
        ),
        IconButton(
          icon: Icon(Icons.list, color: iconColor),
          onPressed: disabled ? null : onLoadByName,
        ),
        IconButton(
          icon: Icon(Icons.upload, color: iconColor),
          onPressed: disabled ? null : onExportLast,
        ),
        IconButton(
          icon: Icon(Icons.file_upload, color: iconColor),
          onPressed: disabled ? null : onExportAll,
        ),
        IconButton(
          icon: Icon(Icons.download, color: iconColor),
          onPressed: disabled ? null : onImport,
        ),
        IconButton(
          icon: Icon(Icons.file_download, color: iconColor),
          onPressed: disabled ? null : onImportAll,
        ),
      ],
    );
  }
}

class _PlaybackAndHandControls extends StatelessWidget {
  final bool isPlaying;
  final int playbackIndex;
  final int actionCount;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onStepBackward;
  final VoidCallback onStepForward;
  final ValueChanged<double> onSeek;
  final VoidCallback onSave;
  final VoidCallback onLoadLast;
  final VoidCallback onLoadByName;
  final VoidCallback onExportLast;
  final VoidCallback onExportAll;
  final VoidCallback onImport;
  final VoidCallback onImportAll;
  final VoidCallback onReset;
  final bool disabled;

  const _PlaybackAndHandControls({
    required this.isPlaying,
    required this.playbackIndex,
    required this.actionCount,
    required this.onPlay,
    required this.onPause,
    required this.onStepBackward,
    required this.onStepForward,
    required this.onSeek,
    required this.onSave,
    required this.onLoadLast,
    required this.onLoadByName,
    required this.onExportLast,
    required this.onExportAll,
    required this.onImport,
    required this.onImportAll,
    required this.onReset,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SaveLoadControlsSection(
          onSave: onSave,
          onLoadLast: onLoadLast,
          onLoadByName: onLoadByName,
          onExportLast: onExportLast,
          onExportAll: onExportAll,
          onImport: onImport,
          onImportAll: onImportAll,
          disabled: disabled,
        ),
        const SizedBox(height: 10),
        _PlaybackControlsSection(
          isPlaying: isPlaying,
          playbackIndex: playbackIndex,
          actionCount: actionCount,
          onPlay: onPlay,
          onPause: onPause,
          onStepBackward: onStepBackward,
          onStepForward: onStepForward,
          onSeek: onSeek,
          onReset: onReset,
          disabled: disabled,
        ),
      ],
    );
  }
}

/// Collapsed view of action history with tabs for each street.
class _CollapsibleActionHistorySection extends StatelessWidget {
  final List<ActionEntry> actions;
  final Map<int, String> playerPositions;
  final int heroIndex;

  const _CollapsibleActionHistorySection({
    required this.actions,
    required this.playerPositions,
    required this.heroIndex,
  });

  @override
  Widget build(BuildContext context) {
    return CollapsibleActionHistory(
      actions: actions,
      playerPositions: playerPositions,
      heroIndex: heroIndex,
    );
  }
}

class _HandNotesSection extends StatelessWidget {
  final TextEditingController commentController;
  final TextEditingController tagsController;

  const _HandNotesSection({
    required this.commentController,
    required this.tagsController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: commentController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Комментарий к раздаче',
              labelStyle: TextStyle(color: Colors.white),
              filled: true,
              fillColor: Colors.white12,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: tagsController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Теги',
              labelStyle: TextStyle(color: Colors.white),
              filled: true,
              fillColor: Colors.white12,
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

class _StreetActionsSection extends StatelessWidget {
  final int street;
  final List<ActionEntry> actions;
  final List<int> pots;
  final Map<int, int> stackSizes;
  final Map<int, String> playerPositions;
  final void Function(int, ActionEntry) onEdit;
  final void Function(int) onDelete;
  final int? visibleCount;
  final String Function(ActionEntry)? evaluateActionQuality;

  const _StreetActionsSection({
    required this.street,
    required this.actions,
    required this.pots,
    required this.stackSizes,
    required this.playerPositions,
    required this.onEdit,
    required this.onDelete,
    this.visibleCount,
    this.evaluateActionQuality,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: StreetActionsList(
        street: street,
        actions: actions,
        pots: pots,
        stackSizes: stackSizes,
        playerPositions: playerPositions,
        onEdit: onEdit,
        onDelete: onDelete,
        visibleCount: visibleCount,
        evaluateActionQuality: evaluateActionQuality,
      ),
    );
  }
}

class _HandHeaderSection extends StatelessWidget {
  final String handName;
  final int playerCount;
  final String streetName;
  final VoidCallback onEdit;

  const _HandHeaderSection({
    required this.handName,
    required this.playerCount,
    required this.streetName,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.padding16),
      child: Card(
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      handName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${playerCount} players • $streetName',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: onEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerCountSelector extends StatelessWidget {
  final int numberOfPlayers;
  final Map<int, String> playerPositions;
  final Map<int, PlayerType> playerTypes;
  final ValueChanged<int>? onChanged;
  final bool disabled;

  const _PlayerCountSelector({
    required this.numberOfPlayers,
    required this.playerPositions,
    required this.playerTypes,
    this.onChanged,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: numberOfPlayers,
      dropdownColor: Colors.black,
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: Colors.white,
      items: [
        for (int i = 2; i <= 10; i++)
          DropdownMenuItem(value: i, child: Text('Игроков: $i')),
      ],
      onChanged: disabled
          ? null
          : (value) {
              if (value != null && onChanged != null) {
                onChanged!(value);
              }
            },
    );
  }
}

class _AnalyzeButtonSection extends StatelessWidget {
  final VoidCallback onAnalyze;

  const _AnalyzeButtonSection({
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onAnalyze,
      child: const Text('🔍 Проанализировать'),
    );
  }
}

class _PlayerEditorSection extends StatefulWidget {
  final int initialStack;
  final PlayerType initialType;
  final bool isHeroSelected;
  final CardModel? card1;
  final CardModel? card2;
  final bool disableCards;
  final void Function(int, PlayerType, bool, CardModel?, CardModel?) onSave;

  const _PlayerEditorSection({
    required this.initialStack,
    required this.initialType,
    required this.isHeroSelected,
    this.card1,
    this.card2,
    this.disableCards = false,
    required this.onSave,
  });

  @override
  State<_PlayerEditorSection> createState() => _PlayerEditorSectionState();
}

class _PlayerEditorSectionState extends State<_PlayerEditorSection> {
  late TextEditingController _stackController;
  late PlayerType _type;
  late bool _isHero;
  CardModel? _card1;
  CardModel? _card2;

  static const ranks = ['A', 'K', 'Q', 'J', 'T', '9', '8', '7', '6', '5', '4', '3', '2'];
  static const suits = ['♠', '♥', '♦', '♣'];

  @override
  void initState() {
    super.initState();
    _stackController = TextEditingController(text: widget.initialStack.toString());
    _type = widget.initialType;
    _isHero = widget.isHeroSelected;
    _card1 = widget.card1;
    _card2 = widget.card2;
  }

  @override
  void dispose() {
    _stackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text('Edit Player', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _stackController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Stack',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type.name,
              dropdownColor: Colors.grey[900],
              decoration: const InputDecoration(
                labelText: 'Type',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              items: const [
                DropdownMenuItem(value: 'standard', child: Text('standard')),
                DropdownMenuItem(value: 'nit', child: Text('nit')),
                DropdownMenuItem(value: 'fish', child: Text('fish')),
                DropdownMenuItem(value: 'maniac', child: Text('maniac')),
                DropdownMenuItem(value: 'shark', child: Text('shark')),
                DropdownMenuItem(value: 'station', child: Text('station')),
              ],
              onChanged: (v) {
                if (v != null) {
                  lockService.safeSetState(this, () =>
                      _type = PlayerType.values.firstWhere(
                        (e) => e.name == v,
                        orElse: () => PlayerType.unknown,
                      ));
                }
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isHero,
              title: const Text('Hero', style: TextStyle(color: Colors.white)),
              onChanged: (v) => context.findAncestorStateOfType<_PokerAnalyzerScreenState>()?.lockService.safeSetState(this, () => _isHero = v),
              activeColor: Colors.orange,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    DropdownButton<String>(
                      value: _card1?.rank,
                      hint: const Text('Rank', style: TextStyle(color: Colors.white54)),
                      dropdownColor: Colors.grey[900],
                      items: ranks
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: widget.disableCards
                          ? null
                          : (v) => lockService.safeSetState(this, () => _card1 = v != null && _card1 != null
                              ? CardModel(rank: v, suit: _card1!.suit)
                              : (v != null ? CardModel(rank: v, suit: suits.first) : null)),
                    ),
                    DropdownButton<String>(
                      value: _card1?.suit,
                      hint: const Text('Suit', style: TextStyle(color: Colors.white54)),
                      dropdownColor: Colors.grey[900],
                      items: suits
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: widget.disableCards
                          ? null
                          : (v) => lockService.safeSetState(this, () => _card1 = v != null && _card1 != null
                              ? CardModel(rank: _card1!.rank, suit: v)
                              : (v != null ? CardModel(rank: ranks.first, suit: v) : null)),
                    ),
                  ],
                ),
                Column(
                  children: [
                    DropdownButton<String>(
                      value: _card2?.rank,
                      hint: const Text('Rank', style: TextStyle(color: Colors.white54)),
                      dropdownColor: Colors.grey[900],
                      items: ranks
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: widget.disableCards
                          ? null
                          : (v) => lockService.safeSetState(this, () => _card2 = v != null && _card2 != null
                              ? CardModel(rank: v, suit: _card2!.suit)
                              : (v != null ? CardModel(rank: v, suit: suits.first) : null)),
                    ),
                    DropdownButton<String>(
                      value: _card2?.suit,
                      hint: const Text('Suit', style: TextStyle(color: Colors.white54)),
                      dropdownColor: Colors.grey[900],
                      items: suits
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: widget.disableCards
                          ? null
                          : (v) => lockService.safeSetState(this, () => _card2 = v != null && _card2 != null
                              ? CardModel(rank: _card2!.rank, suit: v)
                              : (v != null ? CardModel(rank: ranks.first, suit: v) : null)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final stack = int.tryParse(_stackController.text) ?? widget.initialStack;
            widget.onSave(stack, _type, _isHero, _card1, _card2);
            Navigator.pop(context);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _HandEditorSection extends StatelessWidget {
  final List<ActionEntry> historyActions;
  final Map<int, String> playerPositions;
  final int heroIndex;
  final TextEditingController commentController;
  final TextEditingController tagsController;
  final int currentStreet;
  final List<ActionEntry> actions;
  final List<int> pots;
  final Map<int, int> stackSizes;
  final void Function(int, ActionEntry) onEdit;
  final void Function(int) onDelete;
  final int? visibleCount;
  final String Function(ActionEntry)? evaluateActionQuality;
  final VoidCallback onAnalyze;

  const _HandEditorSection({
    required this.historyActions,
    required this.playerPositions,
    required this.heroIndex,
    required this.commentController,
    required this.tagsController,
    required this.currentStreet,
    required this.actions,
    required this.pots,
    required this.stackSizes,
    required this.onEdit,
    required this.onDelete,
    required this.visibleCount,
    required this.evaluateActionQuality,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CollapsibleActionHistorySection(
          actions: historyActions,
          playerPositions: playerPositions,
          heroIndex: heroIndex,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _HandNotesSection(
                    commentController: commentController,
                    tagsController: tagsController),
                _StreetActionsSection(
                  street: currentStreet,
                  actions: actions,
                  pots: pots,
                  stackSizes: stackSizes,
                  playerPositions: playerPositions,
                  onEdit: onEdit,
                  onDelete: onDelete,
                  visibleCount: visibleCount,
                  evaluateActionQuality: evaluateActionQuality,
                ),
                const SizedBox(height: 10),
                _AnalyzeButtonSection(onAnalyze: onAnalyze),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RevealAllCardsButton extends StatelessWidget {
  final bool showAllRevealedCards;
  final VoidCallback onToggle;

  const _RevealAllCardsButton({
    required this.showAllRevealedCards,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: ElevatedButton(
          onPressed: onToggle,
          child: const Text('Показать все карты'),
        ),
      ),
    );
  }
}

class StreetActionInputWidget extends StatefulWidget {
  final int currentStreet;
  final int numberOfPlayers;
  final List<ActionEntry> actions;
  final Map<int, String> playerPositions;
  final void Function(ActionEntry) onAdd;
  final void Function(int, ActionEntry) onEdit;
  final void Function(int) onDelete;

  const StreetActionInputWidget({
    super.key,
    required this.currentStreet,
    required this.numberOfPlayers,
    required this.actions,
    required this.playerPositions,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<StreetActionInputWidget> createState() => _StreetActionInputWidgetState();
}

class _StreetActionInputWidgetState extends State<StreetActionInputWidget> {
  int _player = 0;
  String _action = 'fold';
  final TextEditingController _controller = TextEditingController();

  bool get _needAmount =>
      _action == 'bet' || _action == 'raise' || _action == 'call';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final amount = _needAmount ? int.tryParse(_controller.text) : null;
    widget.onAdd(ActionEntry(widget.currentStreet, _player, _action,
        amount: amount));
    _controller.clear();
  }

  void _editDialog(int index, ActionEntry entry) {
    int p = entry.playerIndex;
    String act = entry.action;
    final c = TextEditingController(
        text: entry.amount != null ? entry.amount.toString() : '');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          bool need = act == 'bet' || act == 'raise' || act == 'call';
          return AlertDialog(
            title: const Text('Редактировать действие'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  value: p,
                  items: [
                    for (int i = 0; i < widget.numberOfPlayers; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(widget.playerPositions[i] ??
                            'Player ${i + 1}'),
                      )
                  ],
                  onChanged: (v) =>
                      ctx.findAncestorStateOfType<_PokerAnalyzerScreenState>()?
                          .lockService.safeSetState(this, () => setState(() => p = v ?? p)),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: act,
                  items: const [
                    DropdownMenuItem(value: 'fold', child: Text('fold')),
                    DropdownMenuItem(value: 'check', child: Text('check')),
                    DropdownMenuItem(value: 'call', child: Text('call')),
                    DropdownMenuItem(value: 'bet', child: Text('bet')),
                    DropdownMenuItem(value: 'raise', child: Text('raise')),
                  ],
                  onChanged: (v) =>
                      ctx.findAncestorStateOfType<_PokerAnalyzerScreenState>()?
                          .lockService.safeSetState(this, () => setState(() => act = v ?? act)),
                ),
                if (need)
                  TextField(
                    controller: c,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () {
                  final amt =
                      (act == 'bet' || act == 'raise' || act == 'call')
                          ? int.tryParse(c.text)
                          : null;
                  widget.onEdit(index,
                      ActionEntry(widget.currentStreet, p, act, amount: amt));
                  Navigator.pop(ctx);
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streetActions = widget.actions
        .where((a) => a.street == widget.currentStreet)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DropdownButton<int>(
              value: _player,
              items: [
                for (int i = 0; i < widget.numberOfPlayers; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(widget.playerPositions[i] ??
                        'Player ${i + 1}'),
                  )
              ],
              onChanged: (v) => context.findAncestorStateOfType<_PokerAnalyzerScreenState>()?.lockService.safeSetState(this, () => _player = v ?? _player),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _action,
              items: const [
                DropdownMenuItem(value: 'fold', child: Text('fold')),
                DropdownMenuItem(value: 'check', child: Text('check')),
                DropdownMenuItem(value: 'call', child: Text('call')),
                DropdownMenuItem(value: 'bet', child: Text('bet')),
                DropdownMenuItem(value: 'raise', child: Text('raise')),
              ],
              onChanged: (v) => context.findAncestorStateOfType<_PokerAnalyzerScreenState>()?.lockService.safeSetState(this, () => _action = v ?? _action),
            ),
            const SizedBox(width: 8),
            if (_needAmount)
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
              ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _add,
              child: const Text('Добавить'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final a in streetActions)
          ListTile(
            dense: true,
            title: Text(
              '${widget.playerPositions[a.playerIndex] ?? 'Player ${a.playerIndex + 1}'} '
              '— ${a.action}${a.amount != null ? ' ${a.amount}' : ''}',
              style: const TextStyle(color: Colors.white),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.amber),
                  onPressed: () =>
                      _editDialog(widget.actions.indexOf(a), a),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      widget.onDelete(widget.actions.indexOf(a)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DebugPanelDialog extends StatefulWidget {
  final _PokerAnalyzerScreenState parent;

  const _DebugPanelDialog({super.key, required this.parent});

  @override
  State<_DebugPanelDialog> createState() => _DebugPanelDialogState();
}

class _DebugPanelDialogState extends State<_DebugPanelDialog> {
  _PokerAnalyzerScreenState get s => widget.parent;

  static const _vGap = SizedBox(height: 12);
  static const _hGap = SizedBox(width: 8);

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    s._debugPanelSetState = setState;
    _searchController.text = s._debugPrefs.searchQuery;
  }

  @override
  void dispose() {
    s._debugPanelSetState = null;
    _searchController.dispose();
    super.dispose();
  }

  VoidCallback? _transitionSafe(VoidCallback? cb) {
    if (cb == null) return null;
    return () {
      if (s.lockService.boardTransitioning) return;
      cb();
    };
  }

  Widget _btn(String label, VoidCallback? onPressed,
      {bool disableDuringTransition = false}) {
    final cb =
        disableDuringTransition ? _transitionSafe(onPressed) : onPressed;
    final disabled = disableDuringTransition && s.lockService.boardTransitioning;
    return ElevatedButton(onPressed: disabled ? null : cb, child: Text(label));
  }

  Widget _buttonsWrap(Map<String, VoidCallback?> actions,
      {bool transitionSafe = false}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in actions.entries)
          _btn(entry.key, entry.value,
              disableDuringTransition: transitionSafe),
      ],
    );
  }

class _QueueTools extends StatelessWidget {
  const _QueueTools({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final _PokerAnalyzerScreenState s = state.s;
    final bool noQueues = s._queueService.pending.isEmpty &&
        s._queueService.failed.isEmpty &&
        s._queueService.completed.isEmpty;

    return state._buttonsWrap(<String, VoidCallback?>{
      'Import Evaluation Queue': s._importEvaluationQueue,
      'Restore Evaluation Queue': s._restoreEvaluationQueue,
      'Restore From Auto-Backup': s._restoreFromAutoBackup,
      'Bulk Import Evaluation Queue': s._bulkImportEvaluationQueue,
      'Bulk Import Backups': () async {
        await s._backupManager.bulkImportEvaluationBackups(s.context);
        if (s.mounted) s.setState(() {});
        s._debugPanelSetState?.call(() {});
      },
      'Bulk Import Auto-Backups': () async {
        await s._backupManager.bulkImportAutoBackups(s.context);
        if (s.mounted) s.setState(() {});
        s._debugPanelSetState?.call(() {});
      },
      'Import Queue Snapshot': s._importEvaluationQueueSnapshot,
      'Bulk Import Snapshots': s._bulkImportEvaluationSnapshots,
      'Export All Snapshots': s._exportAllEvaluationSnapshots,
      'Import Full Queue State': s._importFullEvaluationQueueState,
      'Restore Full Queue State': s._restoreFullEvaluationQueueState,
      'Export Full Queue State': s._exportFullEvaluationQueueState,
      'Export Queue To Clipboard': s._exportQueueToClipboard,
      'Import Queue From Clipboard': s._importQueueFromClipboard,
      'Export Current Queue Snapshot': s._exportEvaluationQueueSnapshot,
      'Quick Backup': s._quickBackupEvaluationQueue,
      'Import Quick Backups': () async {
        await s._backupManager.importQuickBackups(s.context);
        s._debugPanelSetState?.call(() {});
      },
      'Export All Backups': s._exportAllEvaluationBackups,
      'Clear Pending':
          s._queueService.pending.isEmpty ? null : s._clearPendingQueue,
      'Clear Failed':
          s._queueService.failed.isEmpty ? null : s._clearFailedQueue,
      'Clear Completed':
          s._queueService.completed.isEmpty ? null : s._clearCompletedQueue,
      'Clear Evaluation Queue': s._queueService.pending.isEmpty &&
              s._queueService.completed.isEmpty
          ? null
          : s._clearEvaluationQueue,
      'Remove Duplicates': noQueues ? null : s._removeDuplicateEvaluations,
      'Resolve Conflicts': noQueues ? null : s._resolveQueueConflicts,
      'Sort Queues': noQueues ? null : s._sortEvaluationQueues,
      'Clear Completed Evaluations':
          s._queueService.completed.isEmpty ? null : s._clearCompletedEvaluations,
    }, transitionSafe: true);
  }
}

class _SnapshotControls extends StatelessWidget {
  const _SnapshotControls({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final _PokerAnalyzerScreenState s = state.s;
    return state._buttonsColumn({
      'Retry Failed Evaluations':
          s._queueService.failed.isEmpty ? null : s._retryFailedEvaluations,
      'Export Snapshot Now': s._queueService.processing
          ? null
          : () => s._exportEvaluationQueueSnapshot(showNotification: true),
      'Backup Queue Now': s._queueService.processing
          ? null
          : () async {
              await s._backupEvaluationQueue();
              s._debugPanelSetState?.call(() {});
            },
    }, transitionSafe: true);
  }
}

  Widget _buttonsColumn(Map<String, VoidCallback?> actions,
      {bool transitionSafe = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in actions.entries) ...[
          Align(
              alignment: Alignment.centerLeft,
              child: _btn(entry.key, entry.value,
                  disableDuringTransition: transitionSafe)),
          if (entry.key != actions.keys.last) _vGap,
        ],
      ],
    );
  }

  Widget _snapshotRetentionSwitch() {
    return Row(
      children: [
        const Expanded(child: Text('Enable Snapshot Retention Policy')),
        Switch(
          value: s._debugPrefs.snapshotRetentionEnabled,
          onChanged: (v) async {
            await s._debugPrefs.setSnapshotRetentionEnabled(v);
            if (v) await s._cleanupOldEvaluationSnapshots();
            s.lockService.safeSetState(this, () {});
            s._debugPanelSetState?.call(() {});
          },
          activeColor: Colors.orange,
        ),
      ],
    );
  }

  Widget _sortBySprSwitch() {
    return Row(
      children: [
        const Expanded(child: Text('Sort by SPR')),
        Switch(
          value: s._debugPrefs.sortBySpr,
          onChanged: (v) {
            s._debugPrefs.setSortBySpr(v);
            s.lockService.safeSetState(this, () {});
            s._debugPanelSetState?.call(() {});
          },
          activeColor: Colors.orange,
        ),
      ],
    );
  }


class _ProcessingControls extends StatelessWidget {
  const _ProcessingControls({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final _PokerAnalyzerScreenState s = state.s;
    final disabled = s._queueService.pending.isEmpty;
    return state._buttonsWrap({
      'Process Next':
          disabled || s._queueService.processing ? null : s._processNextEvaluation,
      'Start Evaluation Processing':
          disabled || s._queueService.processing ? null : s._processEvaluationQueue,
      s._queueService.pauseRequested ? 'Resume' : 'Pause':
          disabled || !s._queueService.processing ? null : s._toggleEvaluationProcessingPause,
      'Cancel Evaluation Processing':
          !s._queueService.processing && disabled ? null : s._cancelEvaluationProcessing,
      'Force Evaluation Restart': disabled ? null : s._forceRestartEvaluationProcessing,
    });
  }
}

class _QueueDisplaySection extends StatelessWidget {
  const _QueueDisplaySection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final _PokerAnalyzerScreenState s = state.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ToggleButtons(
          isSelected: [
            s._debugPrefs.queueFilters.contains('pending'),
            s._debugPrefs.queueFilters.contains('failed'),
            s._debugPrefs.queueFilters.contains('completed'),
          ],
          onPressed: (i) {
            final modes = ['pending', 'failed', 'completed'];
            s._debugPrefs.toggleQueueFilter(modes[i]);
            s.lockService.safeSetState(this, () {});
            s._debugPanelSetState?.call(() {});
          },
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('Pending'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('Failed'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('Completed'),
            ),
          ],
        ),
        _DebugPanelDialogState._vGap,
        ExpansionTile(
          title: const Text('Advanced Filters'),
          children: [
            CheckboxListTile(
              title: const Text('Only hands with feedback'),
              value: s._debugPrefs.advancedFilters.contains('feedback'),
              onChanged: (_) {
                s._debugPrefs.toggleAdvancedFilter('feedback');
                s.lockService.safeSetState(this, () {});
                s._debugPanelSetState?.call(() {});
              },
            ),
            CheckboxListTile(
              title: const Text('Only hands with opponent cards'),
              value: s._debugPrefs.advancedFilters.contains('opponent'),
              onChanged: (_) {
                s._debugPrefs.toggleAdvancedFilter('opponent');
                s.lockService.safeSetState(this, () {});
                s._debugPanelSetState?.call(() {});
              },
            ),
            CheckboxListTile(
              title: const Text('Only failed evaluations'),
              value: s._debugPrefs.advancedFilters.contains('failed'),
              onChanged: (_) {
                s._debugPrefs.toggleAdvancedFilter('failed');
                s.lockService.safeSetState(this, () {});
                s._debugPanelSetState?.call(() {});
              },
            ),
            CheckboxListTile(
              title: const Text('Only high SPR (>=3)'),
              value: s._debugPrefs.advancedFilters.contains('highspr'),
              onChanged: (_) {
                s._debugPrefs.toggleAdvancedFilter('highspr');
                s.lockService.safeSetState(this, () {});
                s._debugPanelSetState?.call(() {});
              },
            ),
          ],
        ),
        _DebugPanelDialogState._vGap,
        state._sortBySprSwitch(),
        _DebugPanelDialogState._vGap,
        TextField(
          controller: state._searchController,
          decoration:
              const InputDecoration(labelText: 'Search by ID or Feedback'),
          onChanged: (v) {
            s._debugPrefs.setSearchQuery(v);
            s.lockService.safeSetState(this, () {});
            s._debugPanelSetState?.call(() {});
          },
        ),
        _DebugPanelDialogState._vGap,
        Builder(
          builder: (context) {
            final sections = <Widget>[];
            if (s._debugPrefs.queueFilters.contains('pending')) {
              sections.add(state._queueSection('Pending', s._queueService.pending));
            }
            if (s._debugPrefs.queueFilters.contains('failed')) {
              sections.add(state._queueSection('Failed', s._queueService.failed));
            }
            if (s._debugPrefs.queueFilters.contains('completed')) {
              sections.add(
                  state._queueSection('Completed', s._queueService.completed));
            }
            if (sections.isEmpty) {
              return debugDiag('Queue Items', '(none)');
            }
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sections,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _EvaluationResultsSection extends StatelessWidget {
  const _EvaluationResultsSection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final _PokerAnalyzerScreenState s = state.s;
    final results = s._queueService.completed.length > 50
        ? s._queueService.completed
            .sublist(s._queueService.completed.length - 50)
        : s._queueService.completed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Evaluation Results:'),
        if (results.isEmpty)
          debugDiag('Completed Evaluations', '(none)')
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final r in results)
                debugDiag(
                    'Player ${r.playerIndex}, Street ${r.street}', r.action),
            ],
          ),
        _DebugPanelDialogState._vGap,
        const Text('Evaluation Queue Statistics:'),
        debugDiag('Pending', s._queueService.pending.length),
        debugDiag('Failed', s._queueService.failed.length),
        debugDiag('Completed', s._queueService.completed.length),
        debugDiag('Total Processed',
            s._queueService.completed.length + s._queueService.failed.length),
      ],
    );
  }
}

class _PlaybackDiagnosticsSection extends StatelessWidget {
  const _PlaybackDiagnosticsSection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final _PokerAnalyzerScreenState s = state.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        debugDiag('Playback Index',
            '${s._playbackManager.playbackIndex} / ${s.actions.length}'),
        _DebugPanelDialogState._vGap,
        debugDiag('Active Player Index', s.activePlayerIndex ?? 'None'),
        _DebugPanelDialogState._vGap,
        debugDiag('Last Action Player Index',
            s._playbackManager.lastActionPlayerIndex ?? 'None'),
        _DebugPanelDialogState._vGap,
        const Text('Playback Pause State:'),
        debugDiag('Is Playback Paused', s._activeTimer == null),
      ],
    );
  }
}

class _HudOverlayDiagnosticsSection extends StatelessWidget {
  const _HudOverlayDiagnosticsSection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final _PokerAnalyzerScreenState s = state.s;
    final hudStreetName = ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'][s.currentStreet];
    final hudPotText =
        ActionFormattingHelper.formatAmount(s._playbackManager.pots[s.currentStreet]);
    final int hudEffStack = s._potSync.calculateEffectiveStackForStreet(
        s.currentStreet, s.actions, s.numberOfPlayers);
    final double? hudSprValue = s._playbackManager.pots[s.currentStreet] > 0
        ? hudEffStack / s._playbackManager.pots[s.currentStreet]
        : null;
    final String? hudSprText =
        hudSprValue != null ? 'SPR: ${hudSprValue.toStringAsFixed(1)}' : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HUD Overlay State:'),
        debugDiag('HUD Street Name', hudStreetName),
        _DebugPanelDialogState._vGap,
        debugDiag('HUD Pot Text', hudPotText),
        _DebugPanelDialogState._vGap,
        debugDiag('HUD SPR Text', hudSprText ?? '(none)'),
      ],
    );
  }
}

class _StreetTransitionDiagnosticsSection extends StatelessWidget {
  const _StreetTransitionDiagnosticsSection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final _PokerAnalyzerScreenState s = state.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Street Transition State:'),
        debugDiag(
          'Current Animated Players Per Street',
          s._playbackManager.animatedPlayersPerStreet[s.currentStreet]?.length ??
              0,
        ),
        _DebugPanelDialogState._vGap,
        for (final entry
            in s._playbackManager.animatedPlayersPerStreet.entries) ...[
          debugDiag('Street ${entry.key} Animated Count', entry.value.length),
          _DebugPanelDialogState._vGap,
        ],
      ],
    );
  }
}

class _ChipTrailDiagnosticsSection extends StatelessWidget {
  const _ChipTrailDiagnosticsSection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final _PokerAnalyzerScreenState s = state.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chip Trail Diagnostics:'),
        debugDiag('Animated Chips In Flight', ChipMovingWidget.activeCount),
      ],
    );
  }
}

class _EvaluationQueueDiagnosticsSection extends StatelessWidget {
  const _EvaluationQueueDiagnosticsSection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final _PokerAnalyzerScreenState s = state.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        debugDiag(
          'Action Evaluation Queue',
          s._debugPrefs.queueResumed ? '(Resumed from saved state)' : '(New)',
        ),
        debugDiag('Pending Action Evaluations', s._queueService.pending.length),
        debugDiag(
          'Processed',
          '${s._queueService.completed.length} / ${s._queueService.pending.length + s._queueService.completed.length}',
        ),
        debugDiag('Failed', s._queueService.failed.length),
      ],
    );
  }
}

class _ExportConsistencySection extends StatelessWidget {
  const _ExportConsistencySection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final _PokerAnalyzerScreenState s = state.s;
    final hand = s._currentSavedHand();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Debug Menu Visibility:'),
        debugDiag('Is Debug Menu Open', s._debugPrefs.isDebugPanelOpen),
        _DebugPanelDialogState._vGap,
        const Text('Full Export Consistency:'),
        debugCheck('numberOfPlayers',
            hand.numberOfPlayers == s.numberOfPlayers,
            '${hand.numberOfPlayers}', '${s.numberOfPlayers}'),
        debugCheck('heroIndex', hand.heroIndex == s.heroIndex,
            '${hand.heroIndex}', '${s.heroIndex}'),
        debugCheck('heroPosition', hand.heroPosition == s._heroPosition,
            hand.heroPosition, s._heroPosition),
        debugCheck('playerPositions',
            mapEquals(hand.playerPositions, s.playerPositions),
            hand.playerPositions.toString(),
            s.playerPositions.toString()),
        debugCheck('stackSizes',
            mapEquals(hand.stackSizes, s._stackService.initialStacks),
            hand.stackSizes.toString(),
            s._stackService.initialStacks.toString()),
        debugCheck('actions.length', hand.actions.length == s.actions.length,
            '${hand.actions.length}', '${s.actions.length}'),
        debugCheck(
            'boardCards',
            hand.boardCards.map((c) => c.toString()).join(' ') ==
                s.boardCards.map((c) => c.toString()).join(' '),
            hand.boardCards.map((c) => c.toString()).join(' '),
            s.boardCards.map((c) => c.toString()).join(' ')),
        debugCheck(
            'revealedCards',
            listEquals(
              [
                for (final p in s.players)
                  p.revealedCards
                      .whereType<CardModel>()
                      .map((c) => c.toString())
                      .join(' ')
              ],
              [
                for (final list in hand.revealedCards)
                  list.map((c) => c.toString()).join(' ')
              ],
            ),
            [
              for (final list in hand.revealedCards)
                list.map((c) => c.toString()).join(' ')
            ].toString(),
            [
              for (final p in s.players)
                p.revealedCards
                    .whereType<CardModel>()
                    .map((c) => c.toString())
                    .join(' ')
            ].toString()),
      ],
    );
  }
}

class _InternalStateFlagsSection extends StatelessWidget {
  const _InternalStateFlagsSection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final _PokerAnalyzerScreenState s = state.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Internal State Flags:'),
        debugDiag('Debug Layout', s._debugPrefs.debugLayout),
        _DebugPanelDialogState._vGap,
        debugDiag('Perspective Switched', s.isPerspectiveSwitched),
        _DebugPanelDialogState._vGap,
        debugDiag('Show All Revealed Cards', s._debugPrefs.showAllRevealedCards),
      ],
    );
  }
}

class _ThemeDiagnosticsSection extends StatelessWidget {
  const _ThemeDiagnosticsSection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Theme Diagnostics:'),
        debugDiag('Current Theme',
            Theme.of(context).brightness == Brightness.dark ? 'Dark' : 'Light'),
      ],
    );
  }
}

class _CollapsedStreetsSection extends StatelessWidget {
  const _CollapsedStreetsSection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final _PokerAnalyzerScreenState s = state.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Collapsed Streets State:'),
        for (int street = 0; street < 4; street++) ...[
          debugDiag(
            'Street \$street Collapsed',
            !s._expandedHistoryStreets.contains(street),
          ),
          _DebugPanelDialogState._vGap,
        ],
      ],
    );
  }
}

class _CenterChipDiagnosticsSection extends StatelessWidget {
  const _CenterChipDiagnosticsSection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final _PokerAnalyzerScreenState s = state.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chip Animation State:'),
        debugDiag(
          'Center Chip Action',
          () {
            final action = s._centerChipAction;
            if (action == null) return '(null)';
            var result =
                'Street ${action.street}, Player ${action.playerIndex}, Action ${action.action}';
            if (action.amount != null) result += ', Amount ${action.amount}';
            return result;
          }(),
        ),
        _DebugPanelDialogState._vGap,
        debugDiag('Show Center Chip', s._showCenterChip),
        _DebugPanelDialogState._vGap,
        const Text('Animation Controllers State:'),
        debugDiag('Center Chip Animation Active',
            s._centerChipController.isAnimating),
        _DebugPanelDialogState._vGap,
        debugDiag('Center Chip Animation Value',
            s._centerChipController.value.toStringAsFixed(2)),
      ],
    );
  }
}



  TextButton _dialogBtn(String label, VoidCallback? onPressed,
      {bool disableDuringTransition = false}) {
    final cb =
        disableDuringTransition ? _transitionSafe(onPressed) : onPressed;
    final disabled = disableDuringTransition && s.lockService.boardTransitioning;
    return TextButton(onPressed: disabled ? null : cb, child: Text(label));
  }

  Widget _queueSection(String label, List<ActionEvaluationRequest> queue) =>
      s._queueSection(label, queue);

  @override
  Widget build(BuildContext context) {
    final hand = s._currentSavedHand();

    return AlertDialog(
      title: const Text('Stack Diagnostics'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < s.numberOfPlayers; i++)
              debugDiag(
                'Player ${i + 1}',
                'Initial ${s._stackService.initialStacks[i] ?? 0}, '
                'Invested ${s._stackService.getTotalInvested(i)}, '
                'Remaining ${s._stackService.getStackForPlayer(i)}',
              ),
            _vGap,
            if (hand.remainingStacks != null) ...[
              const Text('Remaining Stacks (from saved hand):'),
              for (final entry in hand.remainingStacks!.entries)
                debugDiag('Player ${entry.key + 1}', entry.value),
              _vGap,
            ],
            if (hand.playerTypes != null) ...[
              const Text('Player Types:'),
              for (final entry in hand.playerTypes!.entries)
                debugDiag('Player ${entry.key + 1}', entry.value.name),
              _vGap,
            ],
            if (hand.comment != null) ...[
              debugDiag('Comment', hand.comment!),
              _vGap,
            ],
            if (hand.tags.isNotEmpty) ...[
              const Text('Tags:'),
              for (final tag in hand.tags) debugDiag('Tag', tag),
              _vGap,
            ],
            if (hand.opponentIndex != null) ...[
              debugDiag('Opponent', 'Player ${hand.opponentIndex! + 1}'),
              _vGap,
            ],
            debugDiag('Hero Position', hand.heroPosition),
            _vGap,
            debugDiag('Players at table', hand.numberOfPlayers),
            _vGap,
            debugDiag('Saved', formatDateTime(hand.date)),
            _vGap,
            if (hand.expectedAction != null) ...[
              debugDiag('Expected Action', hand.expectedAction),
              _vGap,
            ],
            if (hand.feedbackText != null) ...[
              debugDiag('Feedback', hand.feedbackText),
              _vGap,
            ],
            debugDiag(
              'Board Cards',
              s.boardCards.isNotEmpty
                  ? s.boardCards.map(s._cardToDebugString).join(' ')
                  : '(empty)',
            ),
            _vGap,
            for (int i = 0; i < s.numberOfPlayers; i++) ...[
              debugDiag(
                'Player ${i + 1} Revealed',
                () {
                  final rc =
                      i < hand.revealedCards.length ? hand.revealedCards[i] : [];
                  return rc.isNotEmpty
                      ? rc.map(s._cardToDebugString).join(' ')
                      : '(none)';
                }(),
              ),
              _vGap,
            ],
            debugDiag('Current Street',
                ['Preflop', 'Flop', 'Turn', 'River'][s.currentStreet]),
            _vGap,
            _PlaybackDiagnosticsSection(state: this),
            _vGap,
            for (int i = 0; i < s.numberOfPlayers; i++) ...[
              debugDiag('Player ${i + 1} Cards', s.playerCards[i].length),
              _vGap,
            ],
            const Text('Effective Stacks:'),
            for (int street = 0; street < 4; street++)
              debugDiag(
                [
                  'Preflop',
                  'Flop',
                  'Turn',
                  'River',
                ][street],
                s._potSync.calculateEffectiveStackForStreet(
                    street, s.actions, s.numberOfPlayers),
              ),
            _vGap,
            const Text('Playback Diagnostics:'),
            debugDiag('Preflop Actions',
                s.actions.where((a) => a.street == 0).length),
            debugDiag('Flop Actions',
                s.actions.where((a) => a.street == 1).length),
            debugDiag('Turn Actions',
                s.actions.where((a) => a.street == 2).length),
            debugDiag('River Actions',
                s.actions.where((a) => a.street == 3).length),
            _vGap,
            debugDiag('Total Actions', s.actions.length),
            _vGap,
            const Text('Action Tags Diagnostics:'),
            if (s._actionTagService.tags.isNotEmpty)
              for (final entry in s._actionTagService.tags.entries) ...[
                debugDiag('Player ${entry.key + 1} Action Tag', entry.value),
                _vGap,
              ]
            else ...[
              debugDiag('Action Tags', '(none)'),
              _vGap,
            ],
            const Text('StackManager Diagnostics:'),
            for (int i = 0; i < s.numberOfPlayers; i++) ...[
              debugDiag(
                'Player $i StackManager',
                'current ${s._stackService.getStackForPlayer(i)}, invested ${s._stackService.getTotalInvested(i)}',
              ),
              _vGap,
            ],
            _InternalStateFlagsSection(state: this),
            _vGap,
            _snapshotRetentionSwitch(),
            _vGap,
            _CollapsedStreetsSection(state: this),
            _vGap,
            _CenterChipDiagnosticsSection(state: this),
            _vGap,
            _StreetTransitionDiagnosticsSection(state: this),
            _vGap,
            _ChipTrailDiagnosticsSection(state: this),
            _vGap,
            _EvaluationQueueDiagnosticsSection(state: this),
            _vGap,
            _QueueDisplaySection(state: this),
            _vGap,
            _ProcessingControls(state: this),
            _vGap,
            _SnapshotControls(state: this),
            _vGap,
            const Text('Evaluation Queue Tools:'),
            _QueueTools(state: this),
            _vGap,
            Row(
              children: [
                const Text('Processing Speed'),
                _hGap,
                Expanded(
                  child: Slider(
                    value: s._debugPrefs.processingDelay.toDouble(),
                    min: 100,
                    max: 2000,
                    divisions: 19,
                    label: '${s._debugPrefs.processingDelay} ms',
                    onChanged: (v) async {
                      await s._debugPrefs.setProcessingDelay(v.round());
                      s.lockService.safeSetState(this, () {});
                      s._debugPanelSetState?.call(() {});
                    },
                  ),
                ),
                _hGap,
                debugDiag('Delay', '${s._debugPrefs.processingDelay} ms'),
              ],
            ),
            _vGap,
            _EvaluationResultsSection(state: this),
            _vGap,
            _HudOverlayDiagnosticsSection(state: this),
            _vGap,
            _ExportConsistencySection(state: this),
            _vGap,
            _ThemeDiagnosticsSection(state: this),
          ],
        ),
      ),
      actions: [
        _dialogBtn('Export Evaluation Queue', s._exportEvaluationQueue,
            disableDuringTransition: true),
        _dialogBtn('Export Full Queue State', s._exportFullEvaluationQueueState,
            disableDuringTransition: true),
        _dialogBtn('Export Queue To Clipboard', s._exportQueueToClipboard,
            disableDuringTransition: true),
        _dialogBtn('Import Queue From Clipboard', s._importQueueFromClipboard,
            disableDuringTransition: true),
        _dialogBtn('Backup Evaluation Queue', s._backupEvaluationQueue,
            disableDuringTransition: true),
        _dialogBtn('Export All Backups', s._exportAllEvaluationBackups,
            disableDuringTransition: true),
        _dialogBtn('Export Auto-Backups', s._exportAutoBackups,
            disableDuringTransition: true),
        _dialogBtn('Export Snapshots', s._exportSnapshots,
            disableDuringTransition: true),
        _dialogBtn('Export All Snapshots', s._exportAllEvaluationSnapshots,
            disableDuringTransition: true),
        _dialogBtn('Previous Street',
            s.currentStreet <= 0 ? null : s._previousStreet,
            disableDuringTransition: true),
        _dialogBtn(
            'Next Street',
            s.currentStreet >= s.boardStreet
                ? null
                : s._nextStreet,
            disableDuringTransition: true),
        _dialogBtn(
          'Undo',
          s.lockService.boardTransitioning || s.lockService.undoRedoTransitionLock
              ? null
              : s._undoAction,
        ),
        _dialogBtn(
          'Redo',
          s.lockService.boardTransitioning || s.lockService.undoRedoTransitionLock
              ? null
              : s._redoAction,
        ),
        _dialogBtn('Previous Street', s._prevStreetDebug,
            disableDuringTransition: true),
        _dialogBtn('Next Street', s._nextStreetDebug,
            disableDuringTransition: true),
        _dialogBtn('Close', () => Navigator.pop(context)),
        _dialogBtn('Clear Evaluation Queue', s._clearEvaluationQueue),
        _dialogBtn('Reset Debug Panel Settings', s._resetDebugPanelPreferences),
      ],
    );
  }

