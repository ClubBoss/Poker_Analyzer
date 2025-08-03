import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../services/evaluation_queue_service.dart';
import '../services/evaluation_queue_import_export_service.dart';
import '../services/saved_hand_import_export_service.dart';
import '../services/training_import_export_service.dart';
import '../services/player_profile_import_export_service.dart';
import '../services/evaluation_processing_service.dart';
import '../services/debug_panel_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/card_model.dart';
import '../models/action_entry.dart';
import '../models/action_outcome.dart';
import '../models/training_spot.dart';
import '../services/playback_manager_service.dart';
import '../services/board_manager_service.dart';
import '../services/board_sync_service.dart';
import '../services/board_editing_service.dart';
import '../services/board_reveal_service.dart';
import '../widgets/player_zone_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../screens/result_screen.dart';
import '../widgets/street_actions_widget.dart';
import '../widgets/action_history_overlay.dart';
import '../widgets/collapsible_action_history.dart';
import '../widgets/action_history_expansion_tile.dart';
import 'package:provider/provider.dart';
import '../services/saved_hand_manager_service.dart';
import '../theme/constants.dart';
import '../theme/app_colors.dart';
import '../widgets/player_info_widget.dart';
import '../widgets/street_actions_list.dart';
import '../widgets/street_action_history_panel.dart';
import '../widgets/hud_overlay.dart';
import '../widgets/chip_trail.dart';
import '../widgets/bet_chips_on_table.dart';
import '../widgets/invested_chip_tokens.dart';
import '../widgets/bet_stack_chips.dart';
import '../widgets/card_selector.dart';
import '../widgets/player_bet_indicator.dart';
import '../widgets/player_stack_chips.dart';
import '../widgets/spr_label.dart';
import '../widgets/total_invested_label.dart';
import '../widgets/chip_amount_widget.dart';
import '../widgets/mini_stack_widget.dart';
import '../widgets/bet_display_widget.dart';
import '../widgets/player_zone/player_stack_value.dart';
import '../widgets/player_note_button.dart';
import '../widgets/player_zone/bet_size_label.dart';
import '../widgets/turn_countdown_overlay.dart';
import '../models/saved_hand.dart';
import '../models/player_model.dart';
import '../models/action_evaluation_request.dart';
import '../widgets/analyzer/action_timeline_panel.dart';
import '../widgets/analyzer/stack_display.dart';
import '../widgets/analyzer/board_editor.dart';
import '../widgets/analyzer/player_zone.dart';
import '../services/pot_sync_service.dart';
import '../widgets/player_zone/chip_moving_widget.dart';
import '../widgets/chip_stack_moving_widget.dart';
import '../widgets/refund_chip_stack_moving_widget.dart';
import '../widgets/player_zone/bet_flying_chips.dart';
import '../widgets/bet_to_center_animation.dart';
import '../widgets/bet_slide_chips.dart';
import '../widgets/all_in_chips_animation.dart';
import '../widgets/win_chips_animation.dart';
import '../widgets/chip_reward_animation.dart';
import '../widgets/win_amount_widget.dart';
import '../services/pot_animation_service.dart';
import '../widgets/win_text_widget.dart';
import '../widgets/loss_fade_widget.dart';
import '../widgets/bet_chip_animation.dart';
import '../widgets/pot_collection_chips.dart';
import '../services/demo_animation_manager.dart';
import '../widgets/trash_flying_chips.dart';
import '../widgets/burn_chips_animation.dart';
import '../widgets/burn_card_animation.dart';
import '../widgets/fold_flying_cards.dart';
import '../widgets/undo_refund_animation.dart';
import '../widgets/refund_amount_widget.dart';
import '../widgets/reveal_card_animation.dart';
import '../widgets/clear_table_cards.dart';
import '../widgets/fold_reveal_animation.dart';
import '../widgets/table_cleanup_overlay.dart';
import '../widgets/table_fade_overlay.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/poker_table_painter.dart';
import '../widgets/deal_card_animation.dart';
import '../widgets/playback_progress_bar.dart';
import '../widgets/hand_completion_indicator.dart';
import '../widgets/street_indicator.dart';
import '../widgets/street_transition_overlay.dart';
import '../services/stack_manager_service.dart';
import '../services/player_manager_service.dart';
import '../services/player_profile_service.dart';
import '../services/player_editing_service.dart';
import '../services/hand_restore_service.dart';
import '../services/action_tag_service.dart';
import '../helpers/date_utils.dart';
import '../helpers/debug_helpers.dart';
import '../user_preferences.dart';
import '../helpers/table_geometry_helper.dart';
import '../helpers/action_formatting_helper.dart';
import '../helpers/showdown_evaluator.dart';
import '../services/backup_manager_service.dart';
import '../services/debug_snapshot_service.dart';
import '../services/action_sync_service.dart';
import '../services/undo_redo_service.dart';
import '../undo_history/diff_engine.dart';
import '../services/action_editing_service.dart';
import '../services/transition_lock_service.dart';
import '../services/transition_history_service.dart';
import '../services/all_in_players_service.dart';
import '../services/current_hand_context_service.dart';
import '../services/folded_players_service.dart';
import '../services/action_history_service.dart';
import '../services/service_registry.dart';
import 'package:poker_analyzer/plugins/plugin_manager.dart';
import 'package:poker_analyzer/plugins/plugin_loader.dart';
import 'package:poker_analyzer/plugins/plugin.dart';
import '../services/demo_playback_controller.dart';
import 'poker_analyzer/board_controls_widget.dart';
import 'poker_analyzer/action_editor_widget.dart';
import 'poker_analyzer/evaluation_panel_widget.dart';
import 'poker_analyzer/action_controls_widget.dart';
import 'poker_analyzer_screen_components.dart';
part 'poker_analyzer/debug_dialog.dart';

class PokerAnalyzerScreen extends StatefulWidget {
  final SavedHand? initialHand;
  final EvaluationQueueService? queueService;
  final EvaluationQueueImportExportService? importExportService;
  final SavedHandImportExportService? handImportExportService;
  final TrainingImportExportService? trainingImportExportService;
  final PlayerProfileImportExportService? playerProfileImportExportService;
  final EvaluationProcessingService? processingService;
  final DebugPanelPreferences? debugPrefsService;
  final ActionSyncService actionSync;
  final HandRestoreService? handRestoreService;
  final CurrentHandContextService? handContext;
  final FoldedPlayersService? foldedPlayersService;
  final AllInPlayersService? allInPlayersService;
  final BackupManagerService? backupManagerService;
  final PlaybackManagerService playbackManager;
  final StackManagerService stackService;
  final BoardManagerService boardManager;
  final BoardSyncService boardSync;
  final BoardEditingService boardEditing;
  final PlayerEditingService playerEditing;
  final PlayerManagerService playerManager;
  final PlayerProfileService playerProfile;
  final ActionTagService actionTagService;
  final BoardRevealService boardReveal;
  final PotSyncService potSyncService;
  final ActionHistoryService actionHistory;
  final TransitionLockService lockService;
  final PotAnimationService? potAnimationService;
  final DemoAnimationManager? demoAnimationManager;
  final bool demoMode;

  const PokerAnalyzerScreen({
    super.key,
    this.initialHand,
    this.queueService,
    this.importExportService,
    this.handImportExportService,
    this.trainingImportExportService,
    this.playerProfileImportExportService,
    this.processingService,
    this.debugPrefsService,
    required this.actionSync,
    this.handRestoreService,
    this.handContext,
    this.foldedPlayersService,
    this.allInPlayersService,
    this.backupManagerService,
    required this.playbackManager,
    required this.stackService,
    required this.boardManager,
    required this.boardSync,
    required this.boardEditing,
    required this.playerEditing,
    required this.playerManager,
    required this.playerProfile,
    required this.actionTagService,
    required this.boardReveal,
    required this.potSyncService,
    required this.actionHistory,
    required this.lockService,
    this.demoAnimationManager,
    this.demoMode = false,
  });

  @override
  State<PokerAnalyzerScreen> createState() => PokerAnalyzerScreenState();
}

class PokerAnalyzerScreenState extends State<PokerAnalyzerScreen>
    with TickerProviderStateMixin {
  late SavedHandManagerService _handManager;
  late SavedHandImportExportService _handImportExportService;
  late TrainingImportExportService _trainingImportExportService;
  late PlayerManagerService _playerManager;
  late BoardManagerService _boardManager;
  late BoardSyncService _boardSync;
  late BoardEditingService _boardEditing;
  late PlayerEditingService _playerEditing;
  late BoardRevealService _boardReveal;
  late ActionTagService _actionTagService;
  int get heroIndex => _playerManager.heroIndex;
  set heroIndex(int v) => _playerEditing.setHeroIndex(v);
  String get _heroPosition => _playerManager.heroPosition;
  set _heroPosition(String v) => _playerManager.heroPosition = v;
  int get numberOfPlayers => _playerManager.numberOfPlayers;
  set numberOfPlayers(int v) => _playerManager.numberOfPlayers = v;
  List<List<CardModel>> get playerCards => _playerManager.playerCards;
  List<CardModel> get boardCards => _boardManager.boardCards;
  List<PlayerModel> get players => _playerManager.players;
  Map<int, String> get playerPositions => _playerManager.playerPositions;
  Map<int, PlayerType> get playerTypes => _playerManager.playerTypes;
  List<bool> get _showActionHints => _playerManager.showActionHints;
  List<CardModel> get revealedBoardCards => _boardReveal.revealedBoardCards;
  int? get opponentIndex => _playerManager.opponentIndex;
  set opponentIndex(int? v) => _playerManager.opponentIndex = v;
  int get currentStreet => _boardManager.currentStreet;
  set currentStreet(int v) => _boardManager.currentStreet = v;
  int get boardStreet => _boardManager.boardStreet;
  set boardStreet(int v) => _boardManager.boardStreet = v;
  List<ActionEntry> get actions => _actionSync.analyzerActions;
  late PlaybackManagerService _playbackManager;
  late PotSyncService _potSync;
  late ActionHistoryService _actionHistory;
  late StackManagerService _stackService;
  late HandRestoreService _handRestore;
  late CurrentHandContextService _handContext;
  Set<String> get allTags => _handManager.allTags;
  Set<String> get tagFilters => _handManager.tagFilters;
  set tagFilters(Set<String> v) => _handManager.tagFilters = v;
  int? activePlayerIndex;
  Timer? _activeTimer;
  late FoldedPlayersService _foldedPlayers;
  late AllInPlayersService _allInPlayers;
  late ActionSyncService _actionSync;
  late UndoRedoService _undoRedoService;
  late TransitionHistoryService _transitionHistory;
  late ActionEditingService _actionEditing;

  bool get _trainingMode => UserPreferences.instance.coachMode;

  Set<int> get _expandedHistoryStreets => _actionHistory.expandedStreets;

  ActionEntry? _centerChipAction;
  bool _showCenterChip = false;
  Offset? _centerChipOrigin;
  Timer? _centerChipTimer;
  late AnimationController _centerChipController;
  late AnimationController _potGrowthController;
  late Animation<double> _potGrowthAnimation;
  late AnimationController _potCountController;
  late Animation<int> _potCountAnimation;
  final List<int> _displayedPots = List.filled(4, 0);
  final Map<int, int> _displayedStacks = {};
  final Map<int, int> _uncalledRefunds = {};
  List<int> _sidePots = [];
  int _currentPot = 0;
  late TransitionLockService lockService;
  final GlobalKey<BoardEditorState> _boardKey =
      GlobalKey<BoardEditorState>();
  late final ScrollController _timelineController;
  bool _animateTimeline = false;
  bool isPerspectiveSwitched = false;
  final bool _focusOnHero = false;

  final Map<int, BetDisplayInfo> _recentBets = {};
  final Map<int, BetDisplayInfo> _betDisplays = {};
  final Map<int, BetDisplayInfo> _centerBetStacks = {};
  final Map<int, int> _actionBetStacks = {};
  final Map<int, OverlayEntry> _betSlideOverlays = {};
  final Map<int, Timer> _betTimers = {};
  final Map<int, AnimationController> _foldControllers = {};
  final Map<int, AnimationController> _stackIncreaseControllers = {};
  Set<int> _prevFoldedPlayers = {};
  int _prevPlaybackIndex = 0;
  int _prevStreet = 0;
  final Set<int> _showdownPlayers = {};
  bool _showdownActive = false;
  int? _winnerIndex;
  Map<int, int>? _winnings;
  Map<int, int>? _returns;
  bool _returnsAnimated = false;
  bool _potAnimationPlayed = false;
  bool _winnerRevealPlayed = false;
  bool _showdownWinPlayed = false;
  bool _simpleWinPlayed = false;
  bool _pendingPotAnimation = false;
  bool _tableCleanupPlayed = false;
  final Set<int> _bustedPlayers = {};

  final List<ChipFlight> _chipFlights = [];

  int _resetAnimationCount = 0;
  bool _waitingForAutoReset = false;
  bool _showNextHandButton = false;
  bool _showReplayDemoButton = false;
  bool _showFinishHandButton = false;
  bool _autoShowdownTriggered = false;
  bool _showHandCompleteIndicator = false;
  Timer? _autoNextHandTimer;
  final double _uiScale = 1.0;

  bool get _isHandEmpty =>
      actions.isEmpty &&
      boardCards.isEmpty &&
      playerCards.every((c) => c.isEmpty);

  bool get _isHandValid =>
      playerCards.any((cards) => cards.isNotEmpty) &&
      boardCards.isNotEmpty &&
      actions.isNotEmpty;

  String? get _validationHint {
    if (!playerCards.any((cards) => cards.isNotEmpty)) {
      return 'Добавьте карты игроков';
    }
    if (boardCards.isEmpty) return 'Добавьте карты на стол';
    if (actions.isEmpty) return 'Нет действий';
    return null;
  }

  int _handProgressStep() {
    if (_showdownActive) return 3;
    if (actions.isNotEmpty) return 2;
    if (boardCards.isNotEmpty ||
        playerCards.any((cards) => cards.isNotEmpty)) {
      return 1;
    }
    return 0;
  }

  /// Overlay entries for transient win labels and glow effects.
  final List<OverlayEntry> _messageOverlays = [];

  // Previous card state used to trigger deal animations.
  List<CardModel> _prevBoardCards = [];
  final List<List<CardModel>> _prevPlayerCards =
      List.generate(10, (_) => <CardModel>[]);

  String? _playbackNarration;
  late final DemoAnimationManager _demoAnimations;
  late final PotAnimationService _potAnimations;



  /// Handles evaluation queue state and processing.
  late final EvaluationQueueService _queueService;
  late final EvaluationQueueImportExportService _importExportService;
  late final EvaluationProcessingService _processingService;
  late final DebugSnapshotService _debugSnapshotService;
  late final ServiceRegistry _serviceRegistry;




  /// Allows updating the debug panel while it's open.
  StateSetter? _debugPanelSetState;

  late final DebugPanelPreferences _debugPrefs;

  /// Evaluation processing delay, snapshot retention and other debug
  /// preferences are managed by [_debugPrefs].


  static const double _timelineExtent = 80.0;
  /// Duration for individual board card animations.
  static const Duration _boardRevealDuration =
      BoardRevealService.revealDuration;
  static const Duration _burnDuration = Duration(milliseconds: 300);
  static const Duration _revealDelay = Duration(milliseconds: 300);


  Widget _queueSection(String label, List<ActionEvaluationRequest> queue) {
    final filtered = _debugPrefs.applyAdvancedFilters(queue);
    return debugQueueSection(label, filtered,
        _debugPrefs.advancedFilters.isEmpty && !_debugPrefs.sortBySpr &&
            _debugPrefs.searchQuery.isEmpty
            ? (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex -= 1;
                lockService.safeSetState(this, () {});
                unawaited(
                    _queueService.reorderQueue(queue, oldIndex, newIndex));
                _debugPanelSetState?.call(() {});
              }
            : (_, __) {});
  }


  void setPosition(int playerIndex, String position) {
    if (lockService.isLocked) return;
    lockService.safeSetState(this, () {
      _playerEditing.setPosition(playerIndex, position);
    });
  }

  void _setHeroIndex(int index) {
    if (lockService.isLocked) return;
    lockService.safeSetState(this, () {
      _playerEditing.setHeroIndex(index);
    });
  }

  void _onPlayerCountChanged(int value) {
    if (lockService.isLocked) return;
    lockService.safeSetState(this, () {
      _playerEditing.onPlayerCountChanged(value);
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
    return _debugPrefs.pinHeroPosition ? _playerManager.heroIndex : 0;
  }

  int _currentStreetBet(int playerIndex) {
    final streetActions = _actionHistory.actionsForStreet(currentStreet);
    ActionEntry? last;
    for (final a in streetActions.reversed) {
      if (a.playerIndex != playerIndex) continue;
      if (a.amount != null &&
          (a.action == 'bet' ||
              a.action == 'raise' ||
              a.action == 'call' ||
              a.action == 'all-in')) {
        last = a;
        break;
      }
      if (a.action == 'fold' || a.action == 'check') {
        break;
      }
    }
    return last?.amount ?? 0;
  }

  int _calculateFoldRefund(int playerIndex) {
    final invested = _stackService.getInvestmentForStreet(playerIndex, currentStreet) -
        (_uncalledRefunds[playerIndex] ?? 0);
    if (invested <= 0) return 0;
    final contributions = <int>[];
    for (int i = 0; i < numberOfPlayers; i++) {
      if (i == playerIndex) continue;
      if (_foldedPlayers.isPlayerFolded(i)) continue;
      contributions.add(_stackService.getInvestmentForStreet(i, currentStreet));
    }
    if (contributions.isEmpty) return 0;
    contributions.sort();
    int callAmount = 0;
    for (final c in contributions) {
      if (c <= invested) {
        callAmount = c;
      } else {
        break;
      }
    }
    return invested - callAmount;
  }

  /// Calculates any uncalled bet amounts that should be returned to players at
  /// the end of the hand.
  Map<int, int> _calculateUncalledReturns() {
    final returns = <int, int>{};
    final activePlayers = [
      for (int i = 0; i < numberOfPlayers; i++)
        if (!_foldedPlayers.isPlayerFolded(i)) i
    ];
    if (activePlayers.length <= 1) return returns;
    for (final p in activePlayers) {
      final invested =
          _stackService.getTotalInvested(p) - (_uncalledRefunds[p] ?? 0);
      if (invested <= 0) continue;
      int maxOther = 0;
      for (final o in activePlayers) {
        if (o == p) continue;
        final otherInvest = _stackService.getTotalInvested(o);
        if (otherInvest > maxOther) maxOther = otherInvest;
      }
      final callAmount = invested < maxOther ? invested : maxOther;
      final refund = invested - callAmount;
      if (refund > 0) returns[p] = refund;
    }
    return returns;
  }

  void _applyOverbetRefunds() {
    final returns = _calculateUncalledReturns();
    returns.forEach((player, amount) {
      final already = _uncalledRefunds[player] ?? 0;
      final delta = amount - already;
      if (delta > 0) {
        _applyRefund(player, delta);
      }
    });
    _recomputeCurrentPot();
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
    final scale = TableGeometryHelper.tableScale(numberOfPlayers);
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
    _centerChipOrigin = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
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
        _centerChipOrigin = null;
      });
    });
  }

  void _animatePotGrowth() {
    if (_potGrowthController.isAnimating) {
      _potGrowthController.stop();
    }
    _potGrowthController.forward(from: 0);
  }

  void _triggerFoldChipReturn(ActionEntry entry) {
    if (entry.amount == null || entry.amount! <= 0) return;
    final overlay = Overlay.of(context);
    final double scale =
        TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final tableWidth = screen.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 -
            TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;
    final i =
        (entry.playerIndex - _viewIndex() + numberOfPlayers) % numberOfPlayers;
    final angle = 2 * pi * i / numberOfPlayers + pi / 2;
    final dx = radiusX * cos(angle);
    final dy = radiusY * sin(angle);
    final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
    final start = Offset(centerX, centerY);
    final end = Offset(centerX + dx, centerY + dy + bias + 92 * scale);

    late final OverlayEntry overlayEntry;
    final controller =
        AnimationController(vsync: this, duration: _boardRevealDuration);
    overlayEntry = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: controller,
        builder: (_, child) {
          final pos = Offset.lerp(start, end, controller.value)!;
          final f = 1 - controller.value;
          return Positioned(
            left: pos.dx - 12 * scale * f,
            top: pos.dy - 12 * scale * f,
            child: Transform.scale(scale: scale * f, child: child),
          );
        },
        child: ChipAmountWidget(
          amount: entry.amount!.toDouble(),
          color: ActionFormattingHelper.actionColor(entry.action),
          scale: 1.0,
        ),
      ),
    );
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        overlayEntry.remove();
        controller.dispose();
      }
    });
    overlay.insert(overlayEntry);
    controller.forward();
  }

  void _playBetFlyInAnimation(ActionEntry entry) {
    if (!['bet', 'raise', 'call', 'all-in'].contains(entry.action) ||
        entry.amount == null ||
        entry.amount! <= 0 ||
        entry.generated) {
      return;
    }
    final overlay = Overlay.of(context);
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
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;
    final perp = Offset(-sin(angle), cos(angle));
    final control = Offset(
      midX + perp.dx * 20 * scale,
      midY - (40 + RefundChipStackMovingWidget.activeCount * 8) * scale,
    );
    final isAllIn = entry.action == 'all-in';
    final color = entry.action == 'raise'
        ? Colors.green
        : entry.action == 'call'
            ? Colors.blue
            : Colors.yellow;
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (_) => isAllIn
          ? AllInChipsAnimation(
              start: start,
              end: end,
              control: control,
              amount: entry.amount!.round(),
              scale: scale,
              onCompleted: () {
                overlayEntry.remove();
                _animatePotGrowth();
              },
            )
          : BetToCenterAnimation(
              start: start,
              end: end,
              control: control,
              amount: entry.amount!.round(),
              color: color,
              scale: scale,
              fadeStart: 0.8,
              labelStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14 * scale,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
              ),
              onCompleted: () {
                overlayEntry.remove();
                _animatePotGrowth();
              },
            ),
    );
    overlay.insert(overlayEntry);
  }

  void _playAllInChipsAnimation(ActionEntry entry) {
    if (entry.action != 'all-in' || entry.amount == null || entry.amount! <= 0) {
      return;
    }
    final overlay = Overlay.of(context);
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
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;
    final perp = Offset(-sin(angle), cos(angle));
    final control = Offset(
      midX + perp.dx * 40 * scale,
      midY - (80 + ChipStackMovingWidget.activeCount * 8) * scale,
    );
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (_) => AllInChipsAnimation(
        start: start,
        end: end,
        control: control,
        amount: entry.amount!.round(),
        scale: scale * 1.2,
        duration: const Duration(milliseconds: 300),
        glowColor: Colors.redAccent,
        fadeStart: 0.6,
        onCompleted: () {
          overlayEntry.remove();
          _animatePotGrowth();
        },
      ),
    );
    overlay.insert(overlayEntry);
  }

  void _playBetReturnAnimation(ActionEntry entry) {
    if (!['bet', 'raise', 'call', 'all-in'].contains(entry.action) ||
        entry.amount == null ||
        entry.amount! <= 0 ||
        entry.generated) {
      return;
    }
    _playFoldRefundAnimation(entry.playerIndex, entry.amount!.round());
  }

  void _startChipFlight(ActionEntry entry) {
    if (!['bet', 'raise', 'call'].contains(entry.action) ||
        entry.amount == null ||
        entry.generated) {
      return;
    }
    final scale = TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final tableWidth = screen.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 - TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;
    final i = (entry.playerIndex - _viewIndex() + numberOfPlayers) % numberOfPlayers;
    final angle = 2 * pi * i / numberOfPlayers + pi / 2;
    final dx = radiusX * cos(angle);
    final dy = radiusY * sin(angle);
    final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
    final start = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
    final end = Offset(centerX, centerY);
    final color = ActionFormattingHelper.actionColor(entry.action);
    final key = UniqueKey();

    lockService.safeSetState(this, () {
      _chipFlights.add(ChipFlight(
        key: key,
        start: start,
        end: end,
        amount: entry.amount!.round(),
        color: color,
        scale: scale,
      ));
    });
  }

  void _removeChipFlight(Key key) {
    ChipFlight? flight;
    lockService.safeSetState(this, () {
      final index = _chipFlights.indexWhere((f) => f.key == key);
      if (index >= 0) {
        flight = _chipFlights.removeAt(index);
      }
    });
    if (flight != null && mounted) {
      final player = flight!.playerIndex;
      final startStack =
          _displayedStacks[player] ?? _stackService.getStackForPlayer(player);
      final endStack = startStack + flight!.amount;
      _animateStackIncrease(player, startStack, endStack);
      final pos = Offset(
        flight!.end.dx - 20 * flight!.scale,
        flight!.end.dy - 60 * flight!.scale,
      );
      if (flight!.color == Colors.lightBlueAccent) {
        showRefundAmountOverlay(
          context: context,
          position: pos,
          amount: flight!.amount,
          scale: flight!.scale,
        );
      } else {
        showWinAmountOverlay(
          context: context,
          position: pos,
          amount: flight!.amount,
          scale: flight!.scale,
        );
      }
      _onResetAnimationComplete();
    }
  }

  void _startPotWinFlights(Map<int, int> payouts) {
    _potAnimations.startPotWinFlights(
      context: context,
      payouts: payouts,
      numberOfPlayers: numberOfPlayers,
      viewIndex: _viewIndex,
      players: players,
      flights: _chipFlights,
      registerResetAnimation: _registerResetAnimation,
      displayedPots: _displayedPots,
      currentStreet: currentStreet,
      potCountController: _potCountController,
      setPotCountAnimation: (a) => _potCountAnimation = a,
      sidePots: _sidePots,
      potSync: _potSync,
      refresh: () => lockService.safeSetState(this, () {}),
      mounted: mounted,
      hideLosingHands: _hideLosingHands,
    );
  }

  void _startSidePotFlights(Map<int, int> payouts) {
    _potAnimations.startSidePotFlights(
      context: context,
      payouts: payouts,
      numberOfPlayers: numberOfPlayers,
      viewIndex: _viewIndex,
      players: players,
      flights: _chipFlights,
      registerResetAnimation: _registerResetAnimation,
      displayedPots: _displayedPots,
      currentStreet: currentStreet,
      potCountController: _potCountController,
      setPotCountAnimation: (a) => _potCountAnimation = a,
      sidePots: _sidePots,
      potSync: _potSync,
      refresh: () => lockService.safeSetState(this, () {}),
      mounted: mounted,
      hideLosingHands: _hideLosingHands,
    );
  }

  void _handleBetAction(ActionEntry entry, {int potIndex = 0}) {
    if (!['bet', 'raise', 'call', 'all-in'].contains(entry.action) ||
        entry.amount == null ||
        entry.amount! <= 0 ||
        entry.generated) {
      return;
    }
    final overlay = Overlay.of(context);
    final double scale =
        TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final tableWidth = screen.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 -
            TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
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
    final potOffsetY = -12 * scale + 36 * scale * potIndex;
    final end = Offset(centerX, centerY + potOffsetY);
    late OverlayEntry overlayEntry;
    Widget child;
    if (widget.demoMode) {
      final midX = (start.dx + end.dx) / 2;
      final midY = (start.dy + end.dy) / 2;
      final perp = Offset(-sin(angle), cos(angle));
      final control = Offset(
        midX + perp.dx * 20 * scale,
        midY - (40 + ChipStackMovingWidget.activeCount * 8) * scale,
      );
      child = BetFlyingChips(
        start: start,
        end: end,
        control: control,
        amount: entry.amount!.round(),
        color: ActionFormattingHelper.actionColor(entry.action),
        scale: scale,
        onCompleted: () {
          overlayEntry.remove();
          _animatePotGrowth();
        },
      );
    } else {
      child = BetChipAnimation(
        start: start,
        end: end,
        amount: entry.amount!.round(),
        scale: scale,
        onCompleted: () {
          overlayEntry.remove();
          _animatePotGrowth();
        },
      );
    }
    overlayEntry = OverlayEntry(builder: (_) => Stack(children: [child]));
    overlay.insert(overlayEntry);
  }


  void _playShowdownReveal() {
    final active = [
      for (int i = 0; i < numberOfPlayers; i++)
        if (!_foldedPlayers.isPlayerFolded(i)) i
    ];
    if (active.length < 2) return;
    if (widget.demoMode) _demoAnimations.showNarration('River showdown');

    final winners = <int>{
      if (_winnings != null && _winnings!.isNotEmpty) ..._winnings!.keys,
      if ((_winnings == null || _winnings!.isEmpty) && _winnerIndex != null)
        _winnerIndex!,
    };

    // Reveal every active player's cards. Custom revealedCards still apply
    // for non-winners when provided.
    final revealPlayers = active;

    _showdownPlayers
      ..clear()
      ..addAll(revealPlayers);
    _showdownActive = true;
    _winnerRevealPlayed = false;
    if (_winnings == null || _winnings!.isEmpty) {
      final calc = _calculateShowdownWinnings();
      if (calc.isNotEmpty) resolveWinner(calc);
    }
    lockService.safeSetState(this, () {});

    for (int j = 0; j < revealPlayers.length; j++) {
      final player = revealPlayers[j];
      Future.delayed(Duration(milliseconds: 400 * j), () {
        if (!mounted) return;
        final customCards =
            players[player].revealedCards.whereType<CardModel>().toList();
        if (customCards.isNotEmpty && !winners.contains(player)) {
          _playShowCardsAnimation(player, cards: customCards);
        } else {
          _playShowCardsAnimation(player);
        }
      });
    }
    // Trigger winner flip animation after all reveals finish.
    final totalDelay = 400 * revealPlayers.length + 400;
    Future.delayed(
        Duration(milliseconds: totalDelay), _playWinnerRevealAnimation);
    Future.delayed(Duration(milliseconds: totalDelay + 600), () {
      if (_boardReveal.revealedBoardCards.length == 5) {
        _playPotWinAnimation();
      } else {
        _pendingPotAnimation = true;
      }
    });
  }

  void _clearShowdown() {
    if (_showdownPlayers.isEmpty) return;
    _removeMessageOverlays();
    _cleanupWinnerCards();
    _showdownPlayers.clear();
    _showdownActive = false;
    _potAnimationPlayed = false;
    _simpleWinPlayed = false;
    _winnerRevealPlayed = false;
    _showdownWinPlayed = false;
    _pendingPotAnimation = false;
    _centerBetStacks.clear();
    lockService.safeSetState(this, () {});
  }

  void _clearBetDisplays() {
    if (_betDisplays.isEmpty &&
        _centerBetStacks.isEmpty &&
        _actionBetStacks.isEmpty &&
        _betSlideOverlays.isEmpty) {
      return;
    }
    setState(() {
      _betDisplays.clear();
      _centerBetStacks.clear();
      _actionBetStacks.clear();
      _betSlideOverlays.forEach((_, entry) => entry.remove());
      _betSlideOverlays.clear();
    });
  }

  void _removeMessageOverlays() {
    for (final o in _messageOverlays) {
      o.remove();
    }
    _messageOverlays.clear();
  }

  void _registerResetAnimation() {
    _resetAnimationCount++;
  }

  void _onResetAnimationComplete() {
    if (_resetAnimationCount > 0) _resetAnimationCount--;
    if (_resetAnimationCount == 0 && _waitingForAutoReset) {
      _waitingForAutoReset = false;
      _autoResetAfterShowdown();
    }
  }

  void _scheduleAutoReset() {
    _waitingForAutoReset = true;
    if (_resetAnimationCount == 0) {
      _waitingForAutoReset = false;
      _autoResetAfterShowdown();
    }
  }

  Future<void> _clearTableState() async {
    final overlay = Overlay.of(context);
    final entries = <OverlayEntry>[];
    final double scale = TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final tableWidth = screen.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 -
            TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    // Board cards
    final visible = boardCards.length;
    final baseY = centerY - 52 * scale;
    for (int i = 0; i < visible; i++) {
      final card = boardCards[i];
      final x = centerX + (i - (visible - 1) / 2) * 44 * scale;
      late OverlayEntry e;
      e = OverlayEntry(
        builder: (_) => ClearTableCards(
          start: Offset(x, baseY),
          card: card,
          scale: scale,
          onCompleted: () => e.remove(),
        ),
      );
      overlay.insert(e);
      entries.add(e);
    }

    // Player cards
    for (int p = 0; p < numberOfPlayers; p++) {
      final cards = playerCards[p];
      if (cards.isEmpty) continue;
      final i = (p - _viewIndex() + numberOfPlayers) % numberOfPlayers;
      final angle = 2 * pi * i / numberOfPlayers + pi / 2;
      final dx = radiusX * cos(angle);
      final dy = radiusY * sin(angle);
      final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
      final base = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
      for (int idx = 0; idx < cards.length; idx++) {
        final card = cards[idx];
        final pos = base + Offset((idx == 0 ? -18 : 18) * scale, 0);
        late OverlayEntry e;
        e = OverlayEntry(
          builder: (_) => ClearTableCards(
            start: pos,
            card: card,
            scale: scale,
            onCompleted: () => e.remove(),
          ),
        );
        overlay.insert(e);
        entries.add(e);
      }
    }

    await Future.delayed(const Duration(milliseconds: 600));
    for (final e in entries) {
      e.remove();
    }

    // Burn remaining chips on the table.
    if (_centerBetStacks.isNotEmpty) {
      final burnEntries = <OverlayEntry>[];
      int delay = 0;
      _centerBetStacks.forEach((playerIndex, info) {
        final i = (playerIndex - _viewIndex() + numberOfPlayers) % numberOfPlayers;
        final angle = 2 * pi * i / numberOfPlayers + pi / 2;
        final dx = radiusX * cos(angle);
        final dy = radiusY * sin(angle);
        final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
        final startBase = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
        final start = Offset.lerp(startBase, Offset(centerX, centerY), 0.15)!;
        Future.delayed(Duration(milliseconds: delay), () {
          if (!mounted) return;
          late OverlayEntry e;
          e = OverlayEntry(
            builder: (_) => BurnChipsAnimation(
              start: start,
              end: Offset(centerX, centerY),
              amount: info.amount,
              color: info.color,
              scale: scale,
              onCompleted: () => e.remove(),
            ),
          );
          overlay.insert(e);
          burnEntries.add(e);
        });
        delay += 80;
      });
      await Future.delayed(Duration(milliseconds: delay + 500));
      for (final e in burnEntries) {
        e.remove();
      }
      _clearBetDisplays();
    }

    // Fade out remaining table elements before state reset.
    late OverlayEntry fadeEntry;
    final completer = Completer<void>();
    fadeEntry = OverlayEntry(
      builder: (_) => TableCleanupOverlay(
        onCompleted: () {
          fadeEntry.remove();
          completer.complete();
        },
      ),
    );
    overlay.insert(fadeEntry);
    await completer.future;
  }

  Future<void> _autoResetAfterShowdown({Duration delay = const Duration(milliseconds: 800)}) async {
    if (_tableCleanupPlayed) return;
    _tableCleanupPlayed = true;
    await _clearTableState();
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      for (final i in _bustedPlayers) {
        fadeOutBustedPlayerZone(
            context.read<PlayerZoneRegistry>(), players[i].name);
      }
    });
    if (widget.demoMode) {
      showConfettiOverlay(context);
    }
    lockService.safeSetState(this, () {
      _showHandCompleteIndicator = true;
    });
    _autoNextHandTimer?.cancel();
    _autoNextHandTimer = null;
    _autoNextHandTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      _resetHandState();
    });
    Future.delayed(delay, () {
      if (!mounted) return;
      lockService.safeSetState(this, () {
        _showHandCompleteIndicator = false;
        _showNextHandButton = true;
        _showFinishHandButton = false;
      });
      lockService.unlock();
    });
  }

  /// Clears the table and resets the hand to its initial empty state.
  Future<void> resetAll() async {
    await _clearTableState();
    if (!mounted) return;
    _resetHandState();
  }

  void _resetHandState() {
    _autoNextHandTimer?.cancel();
    _autoNextHandTimer = null;
    lockService.safeSetState(this, () {
      _clearShowdown();
      _boardManager.clearBoard();
      _playerManager.reset();
      _actionSync.clearAnalyzerActions();
      _actionHistory.clear();
      _winnings = null;
      _winnerIndex = null;
      _returns = null;
      _returnsAnimated = false;
      for (int i = 0; i < _displayedPots.length; i++) {
      _displayedPots[i] = 0;
      }
      _sidePots.clear();
      _currentPot = 0;
      _uncalledRefunds.clear();
      _playbackNarration = null;
      // Hide "Next Hand" button when starting a new hand
      _showNextHandButton = false;
      _showHandCompleteIndicator = false;
      _showReplayDemoButton = false;
      _showFinishHandButton = false;
    });
    _tableCleanupPlayed = false;
    _potSync.reset();
    _playbackManager.resetHand();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (playerCards.any((c) => c.isNotEmpty) || boardCards.isNotEmpty) {
        _playDealSequence();
      }
    });
  }

  void _updateLastActionOutcomes() {
    final wins = _winnings;
    if (wins == null) return;
    final winnerSet = wins.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toSet();
    final registry = context.read<PlayerZoneRegistry>();
    for (int i = 0; i < numberOfPlayers; i++) {
      final name = players[i].name;
      if (!_actionTagService.tags.containsKey(i)) {
        setPlayerLastActionOutcome(
            registry, name, ActionOutcome.neutral);
      } else if (winnerSet.contains(i)) {
        setPlayerLastActionOutcome(registry, name, ActionOutcome.win);
        setPlayerShowdownStatus(registry, name, 'W');
      } else {
        setPlayerLastActionOutcome(registry, name, ActionOutcome.lose);
        setPlayerShowdownStatus(registry, name, 'L');
      }
    }
  }

  void _onNextHandPressed() {
    _autoNextHandTimer?.cancel();
    _autoNextHandTimer = null;
    _resetHandState();
  }

  Future<void> _finishHand() async {
    if (lockService.isLocked) return;
    _updateLastActionOutcomes();
    final visibleActions = actions.take(_playbackManager.playbackIndex).toList();
    final lastAction = visibleActions.isNotEmpty ? visibleActions.last : null;
    final int winner = _winnerIndex ?? lastAction?.playerIndex ?? 0;
    final int pot = _potSync.pots[currentStreet];
    final returns = _returns ?? _calculateUncalledReturns();
    final returnTotal = returns.values.fold<int>(0, (p, e) => p + e);
    final payouts = <int, int>{};
    if (_winnings != null && _winnings!.isNotEmpty) {
      payouts.addAll(_winnings!);
    } else {
      payouts[winner] = pot - returnTotal;
    }
    final resultSidePots = List<int>.from(_sidePots);
    await triggerWinnerAnimation(
        context.read<PlayerZoneRegistry>(), winner, pot - returnTotal);
    if (!_returnsAnimated) {
      await _potAnimations.triggerRefundAnimations(
          returns, context.read<PlayerZoneRegistry>());
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final stacks = <int, int>{};
    _stackService.currentStacks.forEach((i, stack) {
      final payout = payouts[i] ?? 0;
      final refund = returns[i] ?? 0;
      stacks[i] = stack + payout + refund;
    });
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          winnerIndex: winner,
          winnings: payouts,
          finalStacks: stacks,
          potSize: pot - returnTotal,
          actions: visibleActions,
          sidePots: resultSidePots,
        ),
      ),
    );
    if (!mounted) return;
    lockService.safeSetState(this, () {
      _showHandCompleteIndicator = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      lockService.safeSetState(this, () {
        _showHandCompleteIndicator = false;
        _showNextHandButton = true;
        _showFinishHandButton = false;
      });
    });
  }


  void _playReturnChipAnimation(ActionEntry entry) {
    if (!['bet', 'raise', 'call', 'all-in'].contains(entry.action) ||
        entry.amount == null ||
        entry.generated) {
      return;
    }
    final overlay = Overlay.of(context);
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
    final start = Offset(centerX, centerY);
    final end = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;
    final perp = Offset(-sin(angle), cos(angle));
    final control = Offset(
      midX + perp.dx * 20 * scale,
      midY - (40 + ChipMovingWidget.activeCount * 8) * scale,
    );
    final color = entry.action == 'raise'
        ? Colors.green
        : entry.action == 'call'
            ? Colors.blue
            : Colors.yellow;
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (_) => ChipMovingWidget(
        start: start,
        end: end,
        control: control,
        amount: entry.amount!.round(),
        color: color,
        scale: scale,
        onCompleted: () => overlayEntry.remove(),
      ),
    );
    overlay.insert(overlayEntry);
  }

  void _playFoldRefundAnimation(int playerIndex, int amount) {
    if (amount <= 0) return;
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
        (playerIndex - _viewIndex() + numberOfPlayers) % numberOfPlayers;
    final angle = 2 * pi * i / numberOfPlayers + pi / 2;
    final dx = radiusX * cos(angle);
    final dy = radiusY * sin(angle);
    final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
    final start = Offset(centerX, centerY);
    final end = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
    _registerResetAnimation();
    playRefundToPlayer(
      context.read<PlayerZoneRegistry>(),
      playerIndex,
      amount,
      startPosition: start,
      color: Colors.lightGreenAccent,
      onCompleted: () {
        final startStack =
            _displayedStacks[playerIndex] ??
                _stackService.getStackForPlayer(playerIndex);
        final endStack = startStack + amount;
        _animateStackIncrease(playerIndex, startStack, endStack);
        final pos = Offset(
          end.dx - 20 * scale,
          end.dy - 60 * scale,
        );
        showRefundAmountOverlay(
          context: context,
          position: pos,
          amount: amount,
          scale: scale,
        );
        _onResetAnimationComplete();
      },
    );
  }

  void _playSplitPotRefunds(Map<int, int> payouts) {
    if (payouts.isEmpty) return;
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
    int delay = 0;
    payouts.forEach((playerIndex, amount) {
      if (amount <= 0) return;
      final i =
          (playerIndex - _viewIndex() + numberOfPlayers) % numberOfPlayers;
      final angle = 2 * pi * i / numberOfPlayers + pi / 2;
      final dx = radiusX * cos(angle);
      final dy = radiusY * sin(angle);
      final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
      final start = Offset(centerX, centerY);
      final end = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
      Future.delayed(Duration(milliseconds: delay), () {
        if (!mounted) return;
        _registerResetAnimation();
        playRefundToPlayer(
          context.read<PlayerZoneRegistry>(),
          playerIndex,
          amount,
          startPosition: start,
          color: Colors.lightGreenAccent,
          onCompleted: () {
            final startStack =
                _displayedStacks[playerIndex] ??
                    _stackService.getStackForPlayer(playerIndex);
            final endStack = startStack + amount;
            _animateStackIncrease(playerIndex, startStack, endStack);
            final pos = Offset(
              end.dx - 20 * scale,
              end.dy - 60 * scale,
            );
            showRefundAmountOverlay(
              context: context,
              position: pos,
              amount: amount,
              scale: scale,
            );
            _onResetAnimationComplete();
          },
        );
      });
      delay += 200;
    });
  }

  void _notifyShowdownResults() {
    for (int i = 0; i < numberOfPlayers; i++) {
      onShowdownResult(
          context.read<PlayerZoneRegistry>(), players[i].name);
    }
  }

  void _applyRefund(int playerIndex, int amount, {bool animate = true}) {
    if (amount <= 0) return;
    final startStack = _displayedStacks[playerIndex] ??
        _stackService.getStackForPlayer(playerIndex);
    final endStack = startStack + amount;
    lockService.safeSetState(this, () {
      _uncalledRefunds[playerIndex] =
          (_uncalledRefunds[playerIndex] ?? 0) + amount;
      _displayedStacks[playerIndex] = endStack;
      _currentPot = max(0, _currentPot - amount);
    });
    if (animate) {
      _playFoldRefundAnimation(playerIndex, amount);
    }
  }

  void _playUndoRefundAnimations(Map<int, int> refunds) {
    if (refunds.isEmpty) return;
    final overlay = Overlay.of(context);
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

    int delay = 0;
    refunds.forEach((playerIndex, amount) {
      if (amount <= 0) return;
      final i =
          (playerIndex - _viewIndex() + numberOfPlayers) % numberOfPlayers;
      final angle = 2 * pi * i / numberOfPlayers + pi / 2;
      final dx = radiusX * cos(angle);
      final dy = radiusY * sin(angle);
      final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
      final start = Offset(centerX, centerY);
      final end = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
      final midX = (start.dx + end.dx) / 2;
      final midY = (start.dy + end.dy) / 2;
      final perp = Offset(-sin(angle), cos(angle));
      final control = Offset(
        midX + perp.dx * 20 * scale,
        midY - (40 + RefundChipStackMovingWidget.activeCount * 8) * scale,
      );
      Future.delayed(Duration(milliseconds: delay), () {
        if (!mounted) return;
        late OverlayEntry overlayEntry;
        overlayEntry = OverlayEntry(
          builder: (_) => UndoRefundAnimation(
            start: start,
            end: end,
            control: control,
            amount: amount,
            scale: scale,
            color: Colors.lightGreenAccent,
            onCompleted: () {
              overlayEntry.remove();
              final startStack =
                  _displayedStacks[playerIndex] ??
                      _stackService.getStackForPlayer(playerIndex);
              final endStack = startStack + amount;
              _animateStackIncrease(playerIndex, startStack, endStack);
              final pos = Offset(
                end.dx - 20 * scale,
                end.dy - 60 * scale,
              );
              showRefundAmountOverlay(
                context: context,
                position: pos,
                amount: amount,
                scale: scale,
              );
            },
          ),
        );
        overlay.insert(overlayEntry);
      });
      delay += 150;
    });
  }

  void _playFoldTrashAnimation(int playerIndex) {
    final overlay = Overlay.of(context);
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
        (playerIndex - _viewIndex() + numberOfPlayers) % numberOfPlayers;
    final angle = 2 * pi * i / numberOfPlayers + pi / 2;
    final dx = radiusX * cos(angle);
    final dy = radiusY * sin(angle);
    final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
    final start = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
    final end = Offset(-30 * scale, screen.height + 30 * scale);
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;
    final perp = Offset(-sin(angle), cos(angle));
    final control = Offset(
      midX + perp.dx * 20 * scale,
      midY + 40 * scale,
    );
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (_) => TrashFlyingChips(
        start: start,
        end: end,
        control: control,
        amount: 20,
        scale: 0.8 * scale,
        fadeStart: 0.2,
        onCompleted: () => overlayEntry.remove(),
      ),
    );
    overlay.insert(overlayEntry);
  }

  void _playFoldAnimation(int playerIndex) {
    final overlay = Overlay.of(context);
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
        (playerIndex - _viewIndex() + numberOfPlayers) % numberOfPlayers;
    final angle = 2 * pi * i / numberOfPlayers + pi / 2;
    final dx = radiusX * cos(angle);
    final dy = radiusY * sin(angle);
    final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
    final base = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
    final cardPositions = [
      base + Offset(-18 * scale, 0),
      base + Offset(18 * scale, 0),
    ];
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (_) => FoldFlyingCards(
        playerIndex: playerIndex,
        cardPositions: cardPositions,
        scale: scale,
        onCompleted: () => overlayEntry.remove(),
      ),
    );
    overlay.insert(overlayEntry);
  }

  void _playShowCardsAnimation(int playerIndex,
      {List<CardModel>? cards, bool grayscale = false}) {
    final overlay = Overlay.of(context);
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
        (playerIndex - _viewIndex() + numberOfPlayers) % numberOfPlayers;
    final angle = 2 * pi * i / numberOfPlayers + pi / 2;
    final dx = radiusX * cos(angle);
    final dy = radiusY * sin(angle);
    final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
    final base = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
    final cardList = cards ?? playerCards[playerIndex];

    for (int idx = 0; idx < cardList.length; idx++) {
      final card = cardList[idx];
      final pos = base + Offset((idx == 0 ? -18 : 18) * scale, 0);
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => RevealCardAnimation(
          position: pos,
          card: card,
          scale: scale,
          fade: true,
          grayscale: grayscale,
          onCompleted: () => entry.remove(),
        ),
      );
      Future.delayed(Duration(milliseconds: 150 * idx), () {
        overlay.insert(entry);
      });
    }
  }

  void _playWinnerFlipAnimation(int playerIndex) {
    final overlay = Overlay.of(context);
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
        (playerIndex - _viewIndex() + numberOfPlayers) % numberOfPlayers;
    final angle = 2 * pi * i / numberOfPlayers + pi / 2;
    final dx = radiusX * cos(angle);
    final dy = radiusY * sin(angle);
    final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
    final base = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
    final cardList = playerCards[playerIndex];

    for (int idx = 0; idx < cardList.length; idx++) {
      final card = cardList[idx];
      final pos = base + Offset((idx == 0 ? -18 : 18) * scale, 0);
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => RevealCardAnimation(
          position: pos,
          card: card,
          scale: scale,
          fade: true,
          onCompleted: () => entry.remove(),
        ),
      );
      Future.delayed(Duration(milliseconds: 150 * idx), () {
        overlay.insert(entry);
      });
    }
  }

  void _playWinnerRevealAnimation() {
    if (_winnerRevealPlayed) return;
    final winners = <int>{
      if (_winnings != null && _winnings!.isNotEmpty) ..._winnings!.keys,
      if ((_winnings == null || _winnings!.isEmpty) && _winnerIndex != null)
        _winnerIndex!,
    };
    if (winners.isEmpty) return;

    _winnerRevealPlayed = true;
    _playShowdownWinAnimation(winners);
    int delay = 0;
    for (final player in winners) {
      Future.delayed(Duration(milliseconds: 300 * delay), () {
        if (!mounted) return;
        _playShowCardsAnimation(player);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          _playWinnerFlipAnimation(player);
        });
      });
      delay++;
    }

    final revealEnd = 300 * winners.length + 400;

    final losers = [for (final p in _showdownPlayers) if (!winners.contains(p)) p];
    for (int i = 0; i < losers.length; i++) {
      final player = losers[i];
      Future.delayed(Duration(milliseconds: revealEnd + 300 * i), () {
        if (!mounted) return;
        _playShowCardsAnimation(player, grayscale: true);
      });
    }

    final totalDelay = revealEnd + 300 * losers.length + 400;
    Future.delayed(Duration(milliseconds: totalDelay), () {
      if (!mounted) return;
      _playPotCollectionAnimation(winners);
      if (!_showdownWinPlayed) {
        _demoAnimations.showWinnerGlow(
          context: context,
          winners: winners,
          numberOfPlayers: numberOfPlayers,
          viewIndex: _viewIndex,
        );
      }
      _showLossFadeAnimation(winners);
      if (_boardReveal.revealedBoardCards.length < 5) {
        _pendingPotAnimation = true;
      }
    });
  }

  void _playPotCollectionAnimation(Set<int> winners) {
    final Map<int, int> payouts = {};
    if (_winnings != null && _winnings!.isNotEmpty) {
      payouts.addAll(_winnings!);
    } else if (_winnerIndex != null) {
      payouts[_winnerIndex!] = _potSync.pots[currentStreet];
    }

    if (payouts.isEmpty) return;

    final overlay = Overlay.of(context);
    _showPotWinAnimations(
      overlay,
      payouts,
      0,
      AppColors.accent,
      highlight: true,
      fadeStart: 0.5,
    );
  
    _potAnimationPlayed = true;

    final cleanupDelay = 300 * payouts.length + 500;
    Future.delayed(Duration(milliseconds: cleanupDelay), () {
      if (!mounted) return;
      _autoResetAfterShowdown();
    });
  }


  void _playShowdownWinAnimation(Set<int> winners) {
    if (_showdownWinPlayed) return;
    if (winners.isEmpty) return;
    final prefs = UserPreferences.instance;
    final payouts = <int, int>{};
    if (_winnings != null && _winnings!.isNotEmpty) {
      payouts.addAll(_winnings!);
    } else if (_winnerIndex != null) {
      payouts[_winnerIndex!] = _potSync.pots[currentStreet];
    }
    if (payouts.isNotEmpty) {
      _distributeChips(payouts, color: AppColors.accent, fadeStart: 0.5);
    }
    _demoAnimations.showWinnerGlow(
      context: context,
      winners: winners,
      numberOfPlayers: numberOfPlayers,
      viewIndex: _viewIndex,
    );
    for (final p in winners) {
      showWinnerHighlight(context, players[p].name);
      if (prefs.showWinnerCelebration) {
        showWinnerCelebration(
            context, context.read<PlayerZoneRegistry>(), players[p].name);
      }
      if (widget.demoMode) {
        _demoAnimations.showWinnerZoneOverlay(context, players[p].name);
        final amount = payouts[p] ?? _potSync.pots[currentStreet];
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          _demoAnimations.playPotCollection(
            context: context,
            playerIndex: p,
            amount: amount,
            numberOfPlayers: numberOfPlayers,
            viewIndex: _viewIndex,
          );
        });
      }
    }
    if (prefs.showWinnerCelebration) {
      showConfettiOverlay(context);
    }
    _showdownWinPlayed = true;
  }


  void _showLossFadeAnimation(Set<int> winners) {
    final overlay = Overlay.of(context);
    final losers = [for (final p in _showdownPlayers) if (!winners.contains(p)) p];
    if (losers.isEmpty) return;

    final double scale = TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final tableWidth = screen.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 - TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    for (final playerIndex in losers) {
      final i = (playerIndex - _viewIndex() + numberOfPlayers) % numberOfPlayers;
      final angle = 2 * pi * i / numberOfPlayers + pi / 2;
      final dx = radiusX * cos(angle);
      final dy = radiusY * sin(angle);
      final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;

      final cardBase = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
      final cardPositions = [
        cardBase + Offset(-18 * scale, 0),
        cardBase + Offset(18 * scale, 0),
      ];
      final stackChipPos = Offset(
        centerX + dx - 12 * scale,
        centerY + dy + bias + 70 * scale,
      );
      final stackValuePos = Offset(
        centerX + dx - 20 * scale,
        centerY + dy + bias + 84 * scale,
      );
      final cards = playerCards[playerIndex];
      final stack = _displayedStacks[playerIndex] ??
          _stackService.getStackForPlayer(playerIndex);

      Future.microtask(() {
        if (!mounted) return;
        showLossFadeOverlay(
          context: context,
          cardPositions: cardPositions,
          stackChipPos: stackChipPos,
          stackValuePos: stackValuePos,
          cards: cards,
          stack: stack,
          scale: scale,
        );
      });
    }
  }

  void _cleanupWinnerCards() {
    final overlay = Overlay.of(context);
    final winners = <int>{
      if (_winnings != null && _winnings!.isNotEmpty) ..._winnings!.keys,
      if ((_winnings == null || _winnings!.isEmpty) && _winnerIndex != null)
        _winnerIndex!,
    };
    if (winners.isEmpty) return;

    final double scale = TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final tableWidth = screen.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 - TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    int delay = 0;
    for (final playerIndex in winners) {
      final i = (playerIndex - _viewIndex() + numberOfPlayers) % numberOfPlayers;
      final angle = 2 * pi * i / numberOfPlayers + pi / 2;
      final dx = radiusX * cos(angle);
      final dy = radiusY * sin(angle);
      final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
      final base = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
      final cardPositions = [
        base + Offset(-18 * scale, 0),
        base + Offset(18 * scale, 0),
      ];
      Future.delayed(Duration(milliseconds: delay), () {
        if (!mounted) return;
        late OverlayEntry entry;
        entry = OverlayEntry(
          builder: (_) => FoldFlyingCards(
            playerIndex: playerIndex,
            cardPositions: cardPositions,
            scale: scale,
            fadeStart: 0.4,
            onCompleted: () => entry.remove(),
          ),
        );
        overlay.insert(entry);
      });
      delay += 200;
    }
  }

  void _hideLosingHands() {
    final overlay = Overlay.of(context);
    final winners = <int>{
      if (_winnings != null && _winnings!.isNotEmpty) ..._winnings!.keys,
      if ((_winnings == null || _winnings!.isEmpty) && _winnerIndex != null)
        _winnerIndex!,
    };
    final losers = [for (final p in _showdownPlayers) if (!winners.contains(p)) p];
    if (losers.isEmpty) return;

    final double scale = TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final tableWidth = screen.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 - TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    int delay = 0;
    for (final playerIndex in losers) {
      final i = (playerIndex - _viewIndex() + numberOfPlayers) % numberOfPlayers;
      final angle = 2 * pi * i / numberOfPlayers + pi / 2;
      final dx = radiusX * cos(angle);
      final dy = radiusY * sin(angle);
      final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
      final base = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
      final cards = playerCards[playerIndex];
      final dir = dx >= 0 ? 1.0 : -1.0;
      for (int idx = 0; idx < cards.length; idx++) {
        final card = cards[idx];
        final pos = base + Offset((idx == 0 ? -18 : 18) * scale, 0);
        Future.delayed(Duration(milliseconds: delay), () {
          if (!mounted) return;
          late OverlayEntry e;
          e = OverlayEntry(
            builder: (_) => FoldRevealAnimation(
              start: pos,
              card: card,
              scale: scale,
              direction: dir,
              onCompleted: () {
                e.remove();
                _onResetAnimationComplete();
              },
            ),
          );
          _registerResetAnimation();
          overlay.insert(e);
        });
        delay += 120;
      }
    }

    Future.delayed(Duration(milliseconds: delay + 700), () {
      if (!mounted) return;
      for (final p in losers) {
        _showdownPlayers.remove(p);
      }
      lockService.safeSetState(this, () {});
      _scheduleAutoReset();
    });
  }

  /// Animate chips from the pot to one or more players.
  void _distributeChips(
    Map<int, int> targets, {
    Color color = AppColors.accent,
    double scale = 1.0,
    double fadeStart = 0.3,
  }) {
    if (targets.isEmpty) return;
    final overlay = Overlay.of(context);
    final double tableScale =
        TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final tableWidth = screen.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 - TableGeometryHelper.centerYOffset(numberOfPlayers, tableScale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * tableScale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * tableScale * radiusMod;

    targets.forEach((playerIndex, amount) {
      if (amount <= 0) return;
      final i =
          (playerIndex - _viewIndex() + numberOfPlayers) % numberOfPlayers;
      final angle = 2 * pi * i / numberOfPlayers + pi / 2;
      final dx = radiusX * cos(angle);
      final dy = radiusY * sin(angle);
      final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * tableScale;
      final start = Offset(centerX, centerY);
      final end = Offset(centerX + dx, centerY + dy + bias + 92 * tableScale);
      final midX = (start.dx + end.dx) / 2;
      final midY = (start.dy + end.dy) / 2;
      final perp = Offset(-sin(angle), cos(angle));
      final control = Offset(
        midX + perp.dx * 20 * tableScale,
        midY - (40 + ChipStackMovingWidget.activeCount * 8) * tableScale,
      );
      late OverlayEntry overlayEntry;
      overlayEntry = OverlayEntry(
        builder: (_) => BetFlyingChips(
          start: start,
          end: end,
          control: control,
          amount: amount,
          color: color,
          scale: scale,
          labelStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14 * scale,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
          ),
          fadeStart: fadeStart,
          onCompleted: () {
            overlayEntry.remove();
            final startStack =
                _displayedStacks[playerIndex] ??
                    _stackService.getStackForPlayer(playerIndex);
            final endStack = startStack + amount;
            _animateStackIncrease(playerIndex, startStack, endStack);
            final pos = Offset(
              end.dx - 20 * tableScale,
              end.dy - 60 * tableScale,
            );
            showWinAmountOverlay(
              context: context,
              position: pos,
              amount: amount,
              scale: scale * tableScale,
            );
          },
        ),
      );
      overlay.insert(overlayEntry);
    });
  }

  void _showPotWinAnimations(
    OverlayState overlay,
    Map<int, int> targets,
    int startDelay,
    Color color, {
    double scale = 1.0,
    bool highlight = false,
    double fadeStart = 0.6,
  }) {
    if (targets.isEmpty) return;
    final double tableScale =
        TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final tableWidth = screen.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 -
            TableGeometryHelper.centerYOffset(numberOfPlayers, tableScale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * tableScale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * tableScale * radiusMod;

    final totalAmount = targets.values.fold<int>(0, (t, a) => t + (a > 0 ? a : 0));
    int delay = startDelay;
    targets.forEach((playerIndex, amount) {
      if (amount <= 0) return;
      final ratio = totalAmount > 0 ? amount / totalAmount : 0.0;
      final itemScale = scale * (0.8 + 0.4 * ratio);
      final step = (300 * ratio).clamp(150, 300).round();
      final i = (playerIndex - _viewIndex() + numberOfPlayers) % numberOfPlayers;
      final angle = 2 * pi * i / numberOfPlayers + pi / 2;
      final dx = radiusX * cos(angle);
      final dy = radiusY * sin(angle);
      final bias =
          TableGeometryHelper.verticalBiasFromAngle(angle) * tableScale;
      final start = Offset(centerX, centerY);
      final end =
          Offset(centerX + dx, centerY + dy + bias + 92 * tableScale);
      final midX = (start.dx + end.dx) / 2;
      final midY = (start.dy + end.dy) / 2;
      final perp = Offset(-sin(angle), cos(angle));
      final control = Offset(
        midX + perp.dx * 20 * tableScale,
        midY - (40 + ChipStackMovingWidget.activeCount * 8) * tableScale,
      );
      Future.delayed(Duration(milliseconds: delay), () {
        if (!mounted) return;
        late OverlayEntry entry;
        entry = OverlayEntry(
          builder: (_) => WinChipsAnimation(
            start: start,
            end: end,
            control: control,
            amount: amount,
            color: color,
            scale: itemScale * tableScale,
            fadeStart: fadeStart,
            onCompleted: () {
              entry.remove();
              final startStack =
                  _displayedStacks[playerIndex] ??
                      _stackService.getStackForPlayer(playerIndex);
              final endStack = startStack + amount;
              _animateStackIncrease(playerIndex, startStack, endStack);
              final name = players[playerIndex].name;
              if (highlight) showWinnerHighlight(context, name);
              final pos = Offset(
                end.dx - 20 * tableScale,
                end.dy - 60 * tableScale,
              );
              showWinAmountOverlay(
                context: context,
                position: pos,
                amount: amount,
                scale: scale * tableScale,
              );
              final labelPos = Offset(
                end.dx - 40 * tableScale,
                end.dy - 90 * tableScale,
              );
              final playerName =
                  playerIndex == _playerManager.heroIndex ? 'Hero' : name;
              late OverlayEntry textEntry;
              textEntry = OverlayEntry(
                builder: (_) => WinTextWidget(
                  position: labelPos,
                  text: '$playerName wins the pot',
                  scale: scale * tableScale,
                  onCompleted: () {
                    textEntry.remove();
                    _messageOverlays.remove(textEntry);
                  },
                ),
              );
              overlay.insert(textEntry);
              _messageOverlays.add(textEntry);
              Future.delayed(const Duration(milliseconds: 2200), () {
                textEntry.remove();
                _messageOverlays.remove(textEntry);
              });
              _onResetAnimationComplete();
            },
          ),
        );
        _registerResetAnimation();
        overlay.insert(entry);
      });
      delay += step;
    });
  }

  void _showRewardAnimations(
    OverlayState overlay,
    Map<int, int> targets,
    int startDelay,
  ) {
    if (targets.isEmpty) return;
    final double tableScale =
        TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final tableWidth = screen.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screen.width / 2 + 10;
    final centerY = screen.height / 2 -
        TableGeometryHelper.centerYOffset(numberOfPlayers, tableScale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * tableScale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * tableScale * radiusMod;

    int delay = startDelay;
    targets.forEach((playerIndex, amount) {
      if (amount <= 0) return;
      final i = (playerIndex - _viewIndex() + numberOfPlayers) % numberOfPlayers;
      final angle = 2 * pi * i / numberOfPlayers + pi / 2;
      final dx = radiusX * cos(angle);
      final dy = radiusY * sin(angle);
      final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * tableScale;
      final start = Offset(centerX, centerY);
      final end = Offset(centerX + dx, centerY + dy + bias + 92 * tableScale);
      final midX = (start.dx + end.dx) / 2;
      final midY = (start.dy + end.dy) / 2;
      final perp = Offset(-sin(angle), cos(angle));
      final control = Offset(
        midX + perp.dx * 20 * tableScale,
        midY - (40 + ChipStackMovingWidget.activeCount * 8) * tableScale,
      );
      Future.delayed(Duration(milliseconds: delay), () {
        if (!mounted) return;
        late OverlayEntry entry;
        entry = OverlayEntry(
          builder: (_) => ChipRewardAnimation(
            start: start,
            end: end,
            control: control,
            amount: amount,
            scale: tableScale,
            onCompleted: () {
              entry.remove();
              final startStack = _displayedStacks[playerIndex] ??
                  _stackService.getStackForPlayer(playerIndex);
              final endStack = startStack + amount;
              _animateStackIncrease(playerIndex, startStack, endStack);
              showWinnerHighlight(context, players[playerIndex].name);
              _onResetAnimationComplete();
            },
          ),
        );
        _registerResetAnimation();
        overlay.insert(entry);
      });
      delay += 300;
    });
  }

  /// Displays a basic win animation highlighting each winner and
  /// animating chips from the center pot to their stack.
  void _playSimpleWinAnimation(Map<int, int> payouts) {
    if (_simpleWinPlayed || payouts.isEmpty) return;
    final double scale = TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final tableWidth = screen.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 - TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    payouts.forEach((playerIndex, amount) {
      final i = (playerIndex - _viewIndex() + numberOfPlayers) % numberOfPlayers;
      final angle = 2 * pi * i / numberOfPlayers + pi / 2;
      final dx = radiusX * cos(angle);
      final dy = radiusY * sin(angle);
      final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
      final start = Offset(centerX, centerY);
      final end = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
      final midX = (start.dx + end.dx) / 2;
      final midY = (start.dy + end.dy) / 2;
      final perp = Offset(-sin(angle), cos(angle));
      final control = Offset(
        midX + perp.dx * 20 * scale,
        midY - (40 + ChipStackMovingWidget.activeCount * 8) * scale,
      );
      final name = players[playerIndex].name;
      showWinnerHighlight(context, name);
      showWinnerZoneOverlay(
          context, context.read<PlayerZoneRegistry>(), name);
      showPotCollectionChips(
        context: context,
        start: start,
        end: end,
        amount: amount,
        scale: scale,
        control: control,
        fadeStart: 0.6,
      );
    });
    _simpleWinPlayed = true;
  }

  void _animateStackIncrease(int playerIndex, int start, int end) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _stackIncreaseControllers[playerIndex]?.dispose();
    _stackIncreaseControllers[playerIndex] = controller;
    final animation = IntTween(begin: start, end: end).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    )..addListener(() {
        if (!mounted) return;
        lockService.safeSetState(this, () {
          _displayedStacks[playerIndex] = animation.value;
        });
      });
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _stackIncreaseControllers.remove(playerIndex);
        controller.dispose();
      }
    });
    controller.forward();
  }

  void _deductStackAfterAction(ActionEntry entry) {
    if (entry.amount == null) return;
    if (!['bet', 'raise', 'call', 'all-in'].contains(entry.action)) return;
    final current = _displayedStacks[entry.playerIndex] ??
        _stackService.getStackForPlayer(entry.playerIndex);
    final newValue = (current - entry.amount!.round()).clamp(0, current);
    lockService.safeSetState(this, () {
      _displayedStacks[entry.playerIndex] = newValue;
    });
  }

  void _updateCurrentPot(ActionEntry entry) {
    if (entry.amount == null) return;
    if (!['bet', 'raise', 'call', 'all-in'].contains(entry.action)) return;
    lockService.safeSetState(this, () {
      _currentPot += entry.amount!.round();
    });
  }

  void _recomputeCurrentPot() {
    int total = 0;
    for (final a in actions) {
      if ((a.action == 'bet' ||
              a.action == 'raise' ||
              a.action == 'call' ||
              a.action == 'all-in') &&
          a.amount != null) {
        total += a.amount!;
      }
    }
    final refundTotal =
        _uncalledRefunds.values.fold<int>(0, (p, e) => p + e);
    lockService.safeSetState(this, () {
      _currentPot = max(0, total - refundTotal);
    });
  }

  void _animateUncalledReturns({int delay = 0}) {
    if (_returnsAnimated) return;
    final returns = _returns;
    if (returns == null || returns.isEmpty) return;
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      _potAnimations.startRefundFlights(
        context: context,
        refunds: returns,
        numberOfPlayers: numberOfPlayers,
        viewIndex: _viewIndex,
        flights: _chipFlights,
        registerResetAnimation: _registerResetAnimation,
      );
      returns.forEach((player, amount) {
        _applyRefund(player, amount, animate: false);
      });
    });
    _returnsAnimated = true;
  }


  void _playPotWinAnimation() {
    if (_potAnimationPlayed) return;
    final wins = _winnings;
    final payouts = <int, int>{};
    if (wins != null && wins.isNotEmpty) {
      payouts.addAll(wins);
    } else if (_winnerIndex != null) {
      payouts[_winnerIndex!] = _potSync.pots[currentStreet];
    }
    final splitPot = wins != null && wins.length > 1 &&
        wins.values.toSet().length == 1;

    if (payouts.isNotEmpty) {
      if (splitPot) {
        _playSplitPotRefunds(payouts);
      } else {
        _playSimpleWinAnimation(payouts);
        if (_sidePots.isNotEmpty) {
          _startSidePotFlights(payouts);
        } else {
          _startPotWinFlights(payouts);
        }
      }
    }

    _animateUncalledReturns(delay: splitPot ? 0 : 600);
    _potAnimationPlayed = true;
    _notifyShowdownResults();
  }

  /// Plays the pot win animation once showdown reveals have finished.
  void _showPotWinAnimation() {
    if (_potAnimationPlayed) return;
    final overlay = Overlay.of(context);

    final payouts = <int, int>{
      if (_winnings != null && _winnings!.isNotEmpty) ..._winnings!,
      if ((_winnings == null || _winnings!.isEmpty) && _winnerIndex != null)
        _winnerIndex!: _potSync.pots[currentStreet],
    };
    final wins = _winnings;
    final splitPot = wins != null && wins.length > 1 &&
        wins.values.toSet().length == 1;

    if (splitPot) {
      _playSplitPotRefunds(payouts);
      _animateUncalledReturns(delay: 0);
      _potAnimationPlayed = true;
      _notifyShowdownResults();
      return;
    }

    _playSimpleWinAnimation(payouts);

    int delay = 0;
    if (wins != null && wins.isNotEmpty) {
      _showPotWinAnimations(
        overlay,
        wins,
        delay,
        AppColors.accent,
        highlight: true,
        fadeStart: 0.6,
      );
      delay += 150 * wins.length;
    } else if (_winnerIndex != null) {
      _showPotWinAnimations(
        overlay,
        {_winnerIndex!: _potSync.pots[currentStreet]},
        delay,
        AppColors.accent,
        highlight: true,
        fadeStart: 0.6,
      );
      delay += 150;
    } else {
      return;
    }

    _animateUncalledReturns(delay: delay + 500);

    _potAnimationPlayed = true;
    _notifyShowdownResults();

    final winCount = wins?.length ?? 1;
    final totalDelay = 300 * winCount + 500;
    Future.delayed(Duration(milliseconds: totalDelay), () {
      if (!mounted) return;
      final prevPot = _displayedPots[currentStreet];
      if (prevPot > 0) {
        _potCountAnimation =
            IntTween(begin: prevPot, end: 0).animate(_potCountController);
        _potCountController.forward(from: 0);
        _displayedPots[currentStreet] = 0;
      }
      if (_sidePots.isNotEmpty) {
        _sidePots.clear();
        _potSync.sidePots.clear();
        lockService.safeSetState(this, () {});
      }
      _hideLosingHands();
    });
  }

  void _playShowdownRewardAnimation() {
    if (_potAnimationPlayed) return;
    final overlay = Overlay.of(context);

    final wins = _winnings;
    if (wins != null && wins.isNotEmpty) {
      _showRewardAnimations(overlay, wins, 0);
    } else if (_winnerIndex != null) {
      _showRewardAnimations(
          overlay, {_winnerIndex!: _potSync.pots[currentStreet]}, 0);
    } else {
      return;
    }

    _potAnimationPlayed = true;

    final winCount = wins?.length ?? 1;
    final totalDelay = 300 * winCount + 500;
    Future.delayed(Duration(milliseconds: totalDelay), () {
      if (!mounted) return;
      final prevPot = _displayedPots[currentStreet];
      if (prevPot > 0) {
        _potCountAnimation =
            IntTween(begin: prevPot, end: 0).animate(_potCountController);
        _potCountController.forward(from: 0);
        _displayedPots[currentStreet] = 0;
      }
      if (_sidePots.isNotEmpty) {
        _sidePots.clear();
        _potSync.sidePots.clear();
        lockService.safeSetState(this, () {});
      }
      _hideLosingHands();
    });
  }

  void _triggerBetDisplay(ActionEntry entry) {
    if ((entry.action == 'bet' ||
            entry.action == 'raise' ||
            entry.action == 'call' ||
            entry.action == 'all-in') &&
        entry.amount != null) {
      final Color color = ActionFormattingHelper.actionColor(entry.action);
      final int index = entry.playerIndex;
      _betTimers[index]?.cancel();
      setState(() {
        final info = BetDisplayInfo(entry.amount!.round(), color);
        _recentBets[index] = info;
        _betDisplays[index] = info;
        _centerBetStacks[index] = info;
        _actionBetStacks[index] = entry.amount!.round();
      });
      final overlay = Overlay.of(context);
      final double tableScale =
          TableGeometryHelper.tableScale(numberOfPlayers);
      final screen = MediaQuery.of(context).size;
      final tableWidth = screen.width * 0.9;
      final tableHeight = tableWidth * 0.55;
      final centerX = screen.width / 2 + 10;
      final centerY = screen.height / 2 -
          TableGeometryHelper.centerYOffset(numberOfPlayers, tableScale);
      final radiusMod =
          TableGeometryHelper.radiusModifier(numberOfPlayers);
      final radiusX =
          (tableWidth / 2 - 60) * tableScale * radiusMod;
      final radiusY =
          (tableHeight / 2 + 90) * tableScale * radiusMod;
      final i =
          (entry.playerIndex - _viewIndex() + numberOfPlayers) %
              numberOfPlayers;
      final angle = 2 * pi * i / numberOfPlayers + pi / 2;
      final dx = radiusX * cos(angle);
      final dy = radiusY * sin(angle);
      final bias =
          TableGeometryHelper.verticalBiasFromAngle(angle) * tableScale;
      final start =
          Offset(centerX + dx, centerY + dy + bias + 92 * tableScale);
      final end = Offset(centerX, centerY);
      final midX = (start.dx + end.dx) / 2;
      final midY = (start.dy + end.dy) / 2;
      final perp = Offset(-sin(angle), cos(angle));
      final control = Offset(
        midX + perp.dx * 20 * tableScale,
        midY - (40 + ChipStackMovingWidget.activeCount * 8) * tableScale,
      );
      late OverlayEntry overlayEntry;
      overlayEntry = OverlayEntry(
        builder: (_) => BetFlyingChips(
          start: start,
          end: end,
          control: control,
          amount: entry.amount!.round(),
          color: color,
          scale: tableScale,
          fadeStart: 0.8,
          labelStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14 * tableScale,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
          ),
          onCompleted: () => overlayEntry.remove(),
        ),
      );
      overlay.insert(overlayEntry);

      // Chips sliding halfway with amount label
      final mid = Offset.lerp(start, end, 0.5)!;
      _betSlideOverlays[index]?.remove();
      late OverlayEntry slideEntry;
      slideEntry = OverlayEntry(
        builder: (_) => BetSlideChips(
          start: start,
          end: mid,
          amount: entry.amount!.round(),
          color: color,
          scale: tableScale,
          onCompleted: () {
            slideEntry.remove();
            if (_betSlideOverlays[index] == slideEntry) {
              _betSlideOverlays.remove(index);
            }
          },
        ),
      );
      overlay.insert(slideEntry);
      _betSlideOverlays[index] = slideEntry;
          _betTimers[index] = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          _recentBets.remove(index);
          _centerBetStacks.remove(index);
        });
      });
    }
  }

  void _triggerFoldDisplay(int playerIndex) {
    _playFoldAnimation(playerIndex);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      if (playerCards[playerIndex].isNotEmpty) {
        playerCards[playerIndex].clear();
        _prevPlayerCards[playerIndex].clear();
        _playerManager.notifyListeners();
      }
    });
  }

  void _updateSidePots() {
    _sidePots = List<int>.from(_potSync.sidePots);
  }

  void _updateBustedPlayers() {
    _bustedPlayers.clear();
    _stackService.currentStacks.forEach((index, stack) {
      if (stack <= 0 && _allInPlayers.isPlayerAllIn(index)) {
        _bustedPlayers.add(index);
      }
    });
  }

  void _updateFinishHandButtonVisibility() {
    final shouldShow =
        !_potAnimationPlayed &&
        _boardReveal.revealedBoardCards.length == 5 &&
        _playbackManager.playbackIndex == actions.length &&
        !_showNextHandButton;
    if (shouldShow != _showFinishHandButton) {
      lockService.safeSetState(this, () {
        _showFinishHandButton = shouldShow;
      });
    }
  }

  /// Automatically determine showdown winners when cards are revealed.
  Map<int, int> _calculateShowdownWinnings() {
    final active = [
      for (int i = 0; i < numberOfPlayers; i++)
        if (!_foldedPlayers.isPlayerFolded(i)) i
    ];
    if (active.length < 2 || boardCards.length < 5) return {};
    final holes = <int, List<CardModel>>{};
    for (final p in active) {
      final cards = playerCards[p];
      if (cards.length < 2) continue;
      holes[p] = List<CardModel>.from(cards);
    }
    if (holes.length < 2) return {};
    final winners = determineWinners(boardCards, holes);
    if (winners.isEmpty) return {};
    final pot = _potSync.pots[currentStreet];
    final split = pot ~/ winners.length;
    int rem = pot % winners.length;
    final result = <int, int>{};
    for (final p in winners) {
      result[p] = split + (rem > 0 ? 1 : 0);
      if (rem > 0) rem--;
    }
    return result;
  }

  /// Sets the final [winnings] map and plays the pot win animation.
  ///
  /// When the board is fully revealed the chips from the main pot and any
  /// side pots are animated to the winning player(s) using
  /// [WinChipsAnimation]. If the board isn't revealed yet, the animation will
  /// trigger once all cards are shown.
  void resolveWinner(Map<int, int> winnings) {
    if (lockService.isLocked) return;
    _winnings = Map<int, int>.from(winnings);
    if (winnings.isNotEmpty) {
      _winnerIndex = winnings.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    } else {
      _winnerIndex = null;
    }
    _updateSidePots();
    if (_boardReveal.revealedBoardCards.length == 5) {
      _playPotWinAnimation();
    } else {
      _pendingPotAnimation = true;
    }
    lockService.safeSetState(this, () {});
  }


  bool _canReverseStreet() => _boardManager.canReverseStreet();

  void _reverseStreet() {
    if (lockService.isLocked || !_boardManager.canReverseStreet()) return;
    final beforeStacks = {
      for (int i = 0; i < numberOfPlayers; i++) i: _stackService.getStackForPlayer(i)
    };
    _actionTagService.clear();
    _boardManager.reverseStreet();
    _undoRedoService.recordSnapshot();
    final afterStacks = {
      for (int i = 0; i < numberOfPlayers; i++) i: _stackService.getStackForPlayer(i)
    };
    final refunds = <int, int>{};
    for (final i in beforeStacks.keys) {
      final diff = afterStacks[i]! - beforeStacks[i]!;
      if (diff > 0) refunds[i] = diff;
    }
    if (refunds.isNotEmpty) _playUndoRefundAnimations(refunds);
  }

  bool _canAdvanceStreet() => _boardManager.canAdvanceStreet();

  void _advanceStreet() {
    if (lockService.isLocked || !_boardManager.canAdvanceStreet()) return;
    _actionTagService.clear();
    _boardManager.advanceStreet();
    _undoRedoService.recordSnapshot();
  }

  void _changeStreet(int street) {
    if (lockService.isLocked) return;
    _actionTagService.clear();
    _boardManager.changeStreet(street);
  }



  void _play() {
    if (lockService.isLocked) return;
    _playbackManager.startPlayback(
      stepDelay: const Duration(milliseconds: 1200),
      canAdvance: () => !lockService.isLocked && _resetAnimationCount == 0,
    );
  }

  Future<bool> _ensureGameInfo() async {
    if ((_handContext.gameType?.isEmpty ?? true) ||
        (_handContext.category?.isEmpty ?? true)) {
      final gtController =
          TextEditingController(text: _handContext.gameType ?? '');
      final catController =
          TextEditingController(text: _handContext.category ?? '');
      final gameTypes = <String>{
        'Tournament',
        'Cash Game',
        ..._handManager.hands
            .map((h) => h.gameType)
            .whereType<String>()
      }.toList()
        ..sort();
      final categories = <String>{
        'Uncategorized',
        ..._handManager.hands
            .map((h) => h.category)
            .whereType<String>()
      }.toList()
        ..sort();
      final result = await showDialog<(String, String)>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text('Информация о споте',
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: gtController.text.isEmpty ? null : gtController.text,
                  decoration: const InputDecoration(
                    labelText: 'Тип игры',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  dropdownColor: Colors.grey[900],
                  items: [
                    for (final g in gameTypes)
                      DropdownMenuItem(value: g, child: Text(g)),
                  ],
                  onChanged: (v) => setState(() => gtController.text = v ?? ''),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: catController.text.isEmpty ? null : catController.text,
                  decoration: const InputDecoration(
                    labelText: 'Категория',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  dropdownColor: Colors.grey[900],
                  items: [
                    for (final c in categories)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) => setState(() => catController.text = v ?? ''),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(
                    context, (gtController.text, catController.text)),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      );
      try {
        if (result == null ||
            result.$1.trim().isEmpty ||
            result.$2.trim().isEmpty) {
          return false;
        }
        _handContext.gameType = result.$1.trim();
        _handContext.category = result.$2.trim();
      } finally {
        gtController.dispose();
        catController.dispose();
      }
    }
    return true;
  }

  void _playAll() {
    if (lockService.isLocked) return;
    _playbackManager.seek(0);
    _playbackManager.updatePlaybackState();
    _playbackManager.startPlayback(
      stepDelay: const Duration(milliseconds: 1500),
      canAdvance: () => !lockService.isLocked && _resetAnimationCount == 0,
    );
  }

  /// Public wrapper to start autoplay from the beginning.
  void playAll() => _playAll();

  void _pause() {
    if (lockService.isLocked) return;
    _playbackManager.pausePlayback();
  }

  void _stepBackwardPlayback() {
    if (lockService.isLocked) return;
    _playbackManager.stepBackward();
  }

  void _stepForwardPlayback() {
    if (lockService.isLocked) return;
    _playbackManager.stepForward();
  }

  void _seekPlayback(double value) {
    if (lockService.isLocked) return;
    _playbackManager.seek(value.round());
    _playbackManager.updatePlaybackState();
  }

  void _resetPlayback() {
    if (lockService.isLocked) return;
    _cancelHandAnalysis();
    _stackService.reset(Map<int, int>.from(_playerManager.initialStacks));
    _boardManager.changeStreet(0);
    _playbackManager.updatePlaybackState();
  }

  /// Restarts the demo sequence when in demo mode.
  void _replayDemo() {
    final overlay = Overlay.of(context);

    lockService.safeSetState(this, () {
      _showReplayDemoButton = false;
    });

    late OverlayEntry fadeEntry;
    fadeEntry = OverlayEntry(
      builder: (_) => TableFadeOverlay(
        onCompleted: () => fadeEntry.remove(),
      ),
    );
    overlay.insert(fadeEntry);

    Future.delayed(const Duration(milliseconds: 400), () {
      final controller = context.read<DemoPlaybackController>();
      controller.startDemo(
        loadSpot: loadTrainingSpot,
        playAll: playAll,
        announceWinner: resolveWinner,
      );
    });
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

  String _actionNarration(ActionEntry entry) {
    final pos = _positionLabelForIndex(entry.playerIndex);
    final verbs = {
      'fold': 'folds',
      'call': 'calls',
      'raise': 'raises to',
      'bet': 'bets',
      'check': 'checks',
      'all-in': 'shoves',
    };
    final verb = verbs[entry.action] ?? entry.action;
    final amount = entry.amount != null ? ' ${entry.amount}' : '';
    return '$pos $verb$amount';
  }


  String _playerTypeEmoji(PlayerType? type) {
    switch (type) {
      case PlayerType.shark:
        return '🦈';
      case PlayerType.fish:
        return '🐟';
      case PlayerType.nit:
        return '🧊';
      case PlayerType.maniac:
        return '🔥';
      case PlayerType.callingStation:
        return '📞';
      default:
        return '👤';
    }
  }

  Widget _playerTypeIcon(PlayerType? type) {
    final emoji = _playerTypeEmoji(type);
    final label = _playerTypeLabel(type);
    return Tooltip(
      message: label,
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 14),
      ),
    );
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
    final tags = _handContext.tags.toSet();
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
    _handContext.tags = tags.toList();
  }


  Future<void> _editPlayerInfo(int index) async {
    if (lockService.isLocked) return;
    final disableCards = index != _playerManager.heroIndex;

    await showDialog(
      context: context,
      builder: (context) => _PlayerEditorSection(
        initialStack: _stackService.getInitialStack(index),
        initialType: _playerManager.playerTypes[index] ?? PlayerType.unknown,
        isHeroSelected: index == _playerManager.heroIndex,
        card1: _playerManager.playerCards[index].isNotEmpty
            ? _playerManager.playerCards[index][0]
            : null,
        card2: _playerManager.playerCards[index].length > 1
            ? _playerManager.playerCards[index][1]
            : null,
        disableCards: disableCards,
        onSave: (stack, type, isHero, c1, c2) {
          if (lockService.isLocked) return;
          lockService.safeSetState(this, () {
            final cards = <CardModel>[];
            if (c1 != null) cards.add(c1);
            if (c2 != null) cards.add(c2);
            _playerEditing.updatePlayer(
              index,
              stack: stack,
              type: type,
              isHero: isHero,
              cards: cards,
              disableCards: disableCards,
            );
          });
        },
      ),
    );
  }

  Future<void> _editPlayerNote(int index) async {
    if (lockService.isLocked) return;
    final controller = TextEditingController(
        text: _playerManager.playerNotes[index] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        title: const Text(
          'Player Notes',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white10,
            hintText: 'Enter notes',
            hintStyle: const TextStyle(color: Colors.white54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final text = result.trim();
      lockService.safeSetState(this,
          () => _playerManager.setPlayerNote(index, text.isEmpty ? null : text));
    }
  }

  Future<void> _showPlayerProfile(int index) async {
    if (lockService.isLocked) return;
    final profile = _playerManager;
    PlayerType selectedType = profile.playerTypes[index] ?? PlayerType.unknown;
    final controller =
        TextEditingController(text: profile.playerNotes[index] ?? '');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: MediaQuery.of(ctx).viewInsets + const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (ctx, setModal) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Player Profile',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 12),
              DropdownButtonFormField<PlayerType>(
                value: selectedType,
                dropdownColor: Colors.grey[900],
                decoration: const InputDecoration(
                  labelText: 'Type',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                items: PlayerType.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setModal(() => selectedType = v ?? PlayerType.unknown),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white10,
                  hintText: 'Enter notes',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setModal(() {
                        selectedType = PlayerType.unknown;
                        controller.clear();
                      });
                    },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final text = controller.text.trim();
                      profile.setPlayerType(index, selectedType);
                      profile.setPlayerNote(index, text.isEmpty ? null : text);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    _serviceRegistry = ServiceRegistry();
    final pluginManager = PluginManager();
    final loader = PluginLoader();
    await loader.loadAll(_serviceRegistry, pluginManager, context: context);

    _serviceRegistry.register<CurrentHandContextService>(
        widget.handContext ?? CurrentHandContextService());
    _handContext = _serviceRegistry.get<CurrentHandContextService>();

    _serviceRegistry.register<ActionSyncService>(widget.actionSync);
    _actionSync = _serviceRegistry.get<ActionSyncService>();

    _serviceRegistry.register<FoldedPlayersService>(
        widget.foldedPlayersService ?? FoldedPlayersService());
    _foldedPlayers = _serviceRegistry.get<FoldedPlayersService>();
    _prevFoldedPlayers = Set<int>.from(_foldedPlayers.players);
    _foldedPlayers.addListener(_onFoldedPlayersChanged);

    _serviceRegistry.register<AllInPlayersService>(
        widget.allInPlayersService ?? AllInPlayersService());
    _allInPlayers = _serviceRegistry.get<AllInPlayersService>();
    _allInPlayers.addListener(_onAllInPlayersChanged);

    _debugPrefs = widget.debugPrefsService ?? DebugPanelPreferences();
    _serviceRegistry.register<DebugPanelPreferences>(_debugPrefs);

    _serviceRegistry.register<EvaluationQueueService>(
        widget.queueService ?? EvaluationQueueService());
    _queueService = _serviceRegistry.get<EvaluationQueueService>();

    _serviceRegistry.register<EvaluationQueueImportExportService>(
        widget.importExportService ??
            EvaluationQueueImportExportService(queueService: _queueService));
    _importExportService =
        _serviceRegistry.get<EvaluationQueueImportExportService>();

    _serviceRegistry.register<DebugSnapshotService>(DebugSnapshotService());
    _debugSnapshotService = _serviceRegistry.get<DebugSnapshotService>();

    _serviceRegistry.register<TrainingImportExportService>(
        widget.trainingImportExportService ?? const TrainingImportExportService());
    _trainingImportExportService =
        _serviceRegistry.get<TrainingImportExportService>();

    _serviceRegistry.register<BackupManagerService>(
        widget.backupManagerService ??
            BackupManagerService(
                queueService: _queueService, debugPrefs: _debugPrefs));
    final backupManager = _serviceRegistry.get<BackupManagerService>();

    _importExportService.attachBackupManager(backupManager);
    _queueService
      ..attachBackupManager(backupManager)
      ..attachDebugSnapshotService(_debugSnapshotService);
    _importExportService.attachDebugSnapshotService(_debugSnapshotService);

    _serviceRegistry.register<EvaluationProcessingService>(
      widget.processingService ??
          EvaluationProcessingService(
            queueService: _queueService,
            debugPrefs: _debugPrefs,
            registry: _serviceRegistry,
            debugSnapshotService: _debugSnapshotService,
          ));
    _processingService = _serviceRegistry.get<EvaluationProcessingService>();
    _serviceRegistry.register<TransitionLockService>(widget.lockService);
    lockService = _serviceRegistry.get<TransitionLockService>();
    _demoAnimations = widget.demoAnimationManager ?? DemoAnimationManager();
    _potAnimations = widget.potAnimationService ?? PotAnimationService();
    _centerChipController = AnimationController(
      vsync: this,
      duration: _boardRevealDuration,
    );
    _potGrowthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _potGrowthAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _potGrowthController, curve: Curves.easeOutCubic),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _potGrowthController.reverse();
        }
      });
    _potCountController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _potCountAnimation = IntTween(begin: 0, end: 0).animate(_potCountController)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _timelineController = ScrollController();

    _serviceRegistry.register<PlayerManagerService>(widget.playerManager);
    _playerManager =
        _serviceRegistry.get<PlayerManagerService>()..addListener(_onPlayerManagerChanged);

    _serviceRegistry.register<ActionTagService>(widget.actionTagService);
    _actionTagService = _serviceRegistry.get<ActionTagService>();

    _serviceRegistry.register<BoardRevealService>(widget.boardReveal);
    _boardReveal = _serviceRegistry.get<BoardRevealService>();

    _serviceRegistry.register<PotSyncService>(widget.potSyncService);
    _potSync = _serviceRegistry.get<PotSyncService>();

    _serviceRegistry.register<ActionHistoryService>(widget.actionHistory);
    _actionHistory = _serviceRegistry.get<ActionHistoryService>();

    _serviceRegistry.register<BoardManagerService>(widget.boardManager);
    _boardManager = _serviceRegistry.get<BoardManagerService>()
      ..addListener(_onBoardManagerChanged);
    _prevStreet = _boardManager.currentStreet;

    _serviceRegistry.register<BoardSyncService>(widget.boardSync);
    _boardSync = _serviceRegistry.get<BoardSyncService>();

    _serviceRegistry.register<BoardEditingService>(widget.boardEditing);
    _boardEditing = _serviceRegistry.get<BoardEditingService>();

    _serviceRegistry.register<PlayerEditingService>(widget.playerEditing);
    _playerEditing = _serviceRegistry.get<PlayerEditingService>();

    _serviceRegistry.register<StackManagerService>(widget.stackService);
    _stackService = _serviceRegistry.get<StackManagerService>();
    _playerManager.attachStackManager(_stackService);
    _stackService.addListener(_onStackServiceChanged);
    _displayedStacks
      ..clear()
      ..addAll(_stackService.currentStacks);
    _updateBustedPlayers();

    _actionSync.attachStackManager(_stackService);
    _potSync.stackService = _stackService;

    _serviceRegistry.register<PlaybackManagerService>(widget.playbackManager);
    _playbackManager = _serviceRegistry.get<PlaybackManagerService>()
      ..stackService = _stackService
      ..addListener(_onPlaybackManagerChanged);
    _serviceRegistry.register<HandRestoreService>(
        widget.handRestoreService ??
            HandRestoreService(
              playerManager: _playerManager,
              actionSync: _actionSync,
              playbackManager: _playbackManager,
              boardManager: _boardManager,
              boardSync: _boardSync,
              queueService: _queueService,
              backupManager: backupManager,
              debugPrefs: _debugPrefs,
              lockService: lockService,
              handContext: _handContext,
              foldedPlayers: _foldedPlayers,
              actionTags: _actionTagService,
              setActivePlayerIndex: (i) => activePlayerIndex = i,
              potSync: _potSync,
              actionHistory: _actionHistory,
              boardReveal: _boardReveal,
            ));
    _handRestore = _serviceRegistry.get<HandRestoreService>();
    _playerManager.updatePositions();
    _playbackManager.updatePlaybackState();
    _prevPlaybackIndex = _playbackManager.playbackIndex;
    for (int i = 0; i < _displayedPots.length; i++) {
      _displayedPots[i] = _potSync.pots[i];
    }
    _potCountAnimation = IntTween(
      begin: _potSync.pots[currentStreet],
      end: _potSync.pots[currentStreet],
    ).animate(_potCountController);
    _potCountController.value = 1.0;
    _actionHistory.updateHistory(actions,
        visibleCount: _playbackManager.playbackIndex);
    if (widget.initialHand != null) {
      _stackService = _handRestore.restoreHand(widget.initialHand!);
      _playerManager.attachStackManager(_stackService);
      _actionSync.attachStackManager(_stackService);
      _potSync.stackService = _stackService;
      _displayedStacks
        ..clear()
        ..addAll(_stackService.currentStacks);
      _actionSync.updatePlaybackIndex(_playbackManager.playbackIndex);
      _boardManager.startBoardTransition();
      _startNewHand();
    }
    _serviceRegistry.register<TransitionHistoryService>(TransitionHistoryService(
      lockService: lockService,
      boardManager: _boardManager,
    ));
    _transitionHistory = _serviceRegistry.get<TransitionHistoryService>();

    _serviceRegistry.register<UndoRedoService>(UndoRedoService(
      actionSync: _actionSync,
      boardManager: _boardManager,
      playbackManager: _playbackManager,
      playerManager: _playerManager,
      handContext: _handContext,
      actionTagService: _actionTagService,
      actionHistory: _actionHistory,
      foldedPlayers: _foldedPlayers,
      allInPlayers: _allInPlayers,
      boardReveal: _boardReveal,
      potSync: _potSync,
      lockService: lockService,
      transitionHistory: _transitionHistory,
      diffEngine: DiffEngine(),
    ));
    _undoRedoService = _serviceRegistry.get<UndoRedoService>();

    _serviceRegistry.register<ActionEditingService>(ActionEditingService(
      actionSync: _actionSync,
      undoRedo: _undoRedoService,
      actionTag: _actionTagService,
      playbackManager: _playbackManager,
      foldedPlayers: _foldedPlayers,
      allInPlayers: _allInPlayers,
      boardManager: _boardManager,
      boardSync: _boardSync,
      actionHistory: _actionHistory,
      playerManager: _playerManager,
      triggerCenterChip: _triggerCenterChip,
      playChipAnimation: _handleBetAction,
      playerZoneRegistry: context.read<PlayerZoneRegistry>(),
    ));
    _actionEditing = _serviceRegistry.get<ActionEditingService>();
    Future(() => _initializeDebugPreferences());
    Future.microtask(_queueService.loadQueueSnapshot);
    _updateSidePots();
    if (widget.initialHand?.winnings != null &&
        widget.initialHand!.winnings!.isNotEmpty) {
      _winnerIndex = widget.initialHand!.winnings!.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      _winnings = Map<int, int>.from(widget.initialHand!.winnings!);
    }
    _prevBoardCards = List<CardModel>.from(boardCards);
    for (int i = 0; i < _prevPlayerCards.length; i++) {
      _prevPlayerCards[i] = List<CardModel>.from(playerCards[i]);
    }
    // BackupManagerService handles periodic backups and cleanup internally.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handManager = context.read<SavedHandManagerService>();
    _handImportExportService =
        widget.handImportExportService ??
            SavedHandImportExportService(
              _handManager,
              registry: _serviceRegistry,
            );
  }

  void selectCard(int index, CardModel card) {
    if (_playerEditing.selectCard(context, index, card)) {
      lockService.safeSetState(this, () {});
    }
  }

  Future<void> _onPlayerCardTap(int index, int cardIndex) async {
    if (lockService.isLocked) return;
    final current =
        cardIndex < playerCards[index].length ? playerCards[index][cardIndex] : null;
    final selectedCard = await showCardSelector(
      context,
      disabledCards: _playerEditing.usedCardKeys(except: current),
    );
    if (selectedCard == null) return;
    if (_playerEditing.setPlayerCard(
        context, index, cardIndex, selectedCard, current)) {
      lockService.safeSetState(this, () {});
    }
  }

  void _onPlayerTimeExpired(int index) {
    if (lockService.isLocked) return;
    if (activePlayerIndex == index) {
      _setActivePlayer(null);
    }
  }

  void _setActivePlayer(int? index, {Duration duration = const Duration(seconds: 3)}) {
    _activeTimer?.cancel();
    lockService.safeSetState(this, () => activePlayerIndex = index);
    if (index != null) {
      _activeTimer = Timer(duration, () {
        if (mounted && activePlayerIndex == index) {
          lockService.safeSetState(this, () => activePlayerIndex = null);
        }
      });
    }
  }

  void _clearActiveHighlight() {
    if (activePlayerIndex != null) {
      _setActivePlayer(null);
    }
  }

  Future<void> _onOpponentCardTap(int cardIndex) async {
    if (lockService.isLocked) return;
    opponentIndex ??= activePlayerIndex;
    final idx = opponentIndex ?? 0;
    await _onRevealedCardTap(idx, cardIndex);
  }

  Future<void> _onRevealedCardTap(int playerIndex, int cardIndex) async {
    if (lockService.isLocked) return;
    final current = players[playerIndex].revealedCards[cardIndex];
    final selected = await showCardSelector(
      context,
      disabledCards: _playerEditing.usedCardKeys(except: current),
    );
    if (selected == null) return;
    if (_playerEditing.setRevealedCard(
        context, playerIndex, cardIndex, selected, current)) {
      lockService.safeSetState(this, () {});
    }
  }



  void selectBoardCard(int index, CardModel card) {
    if (lockService.isLocked) return;
    final current = index < boardCards.length ? boardCards[index] : null;
    if (_boardEditing.selectBoardCard(context, index, card, current: current)) {
      lockService.safeSetState(this, () {
        _undoRedoService.recordSnapshot();
      });
    }
  }

  void _removeBoardCard(int index) {
    if (lockService.isLocked) return;
    if (index >= boardCards.length) return;
    _boardEditing.removeBoardCard(index);
    lockService.safeSetState(this, () {
      _undoRedoService.recordSnapshot();
    });
  }

  Future<Map<String, dynamic>?> _showActionPicker() {
    final bool hasBet = _streetHasBet();
    final bool betEnabled = !hasBet;
    final bool raiseEnabled = hasBet;
    final TextEditingController controller = TextEditingController();
    String? selected;
    double sliderValue = 1;
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
          final int stack =
              _stackService.getStackForPlayer(activePlayerIndex ?? 0);
          final int pot = _potSync.pots[currentStreet];
          return Padding(
            padding: MediaQuery.of(ctx).viewInsets + const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                if (needAmount) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _sizeButton('50%', pot / 2, ctx, selected!),
                      _sizeButton('66%', pot * 2 / 3, ctx, selected!),
                      _sizeButton('Pot', pot.toDouble(), ctx, selected!),
                    ],
                  ),
                  Slider(
                    value: sliderValue,
                    min: 1,
                    max: stack.toDouble(),
                    divisions: stack > 0 ? stack : 1,
                    label: sliderValue.round().toString(),
                    onChanged: (v) =>
                        setModal(() => sliderValue = v),
                    onChangeEnd: (v) => _submitSize(v, ctx, selected!),
                  ),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      final double? amt = double.tryParse(controller.text);
                      if (amt != null) {
                        _submitSize(amt, ctx, selected!);
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

  Widget _sizeButton(
      String label, double amount, BuildContext ctx, String action) {
    return OutlinedButton(
      onPressed: () => _submitSize(amount, ctx, action),
      child: Text(label),
    );
  }

  void _submitSize(double amount, BuildContext ctx, String action) {
    Navigator.pop(ctx, {
      'action': action,
      'amount': amount.clamp(1, _stackService.getStackForPlayer(activePlayerIndex ?? 0).toDouble()),
    });
  }

  Future<void> _onPlayerTap(int index) async {
    if (lockService.isLocked) return;
    _setActivePlayer(index);
    final result = await _showActionPicker();
    if (result == null) return;
    final String action = result['action'] as String;
    double? amount = result['amount'] as double?;
    if (action == 'all-in') {
      amount = _stackService.getStackForPlayer(index).toDouble();
    }
    final entry = ActionEntry(currentStreet, index, action, amount: amount);
    handlePlayerAction(entry);
  }


  bool _streetHasBet({List<ActionEntry>? fromActions}) {
    final list = fromActions ?? actions;
    return list
        .where((a) => a.street == currentStreet)
        .any((a) => a.action == 'bet' || a.action == 'raise');
  }

  void _maybeTriggerAutoShowdown(ActionEntry? lastAction, List<int> activePlayers) {
    if (_autoShowdownTriggered ||
        _showNextHandButton ||
        _allInPlayers.isEmpty ||
        lastAction == null ||
        lastAction.action != 'fold' ||
        activePlayers.length != 1 ||
        _playbackManager.playbackIndex != actions.length) {
      return;
    }

    _autoShowdownTriggered = true;
    _winnerIndex = activePlayers.first;
    unawaited(_finishHand().whenComplete(() => _autoShowdownTriggered = false));
  }

  void _maybeTriggerSimpleWin(ActionEntry? lastAction, List<int> activePlayers) {
    if (_showdownActive ||
        _autoShowdownTriggered ||
        _showNextHandButton ||
        _allInPlayers.isNotEmpty ||
        _potAnimationPlayed ||
        _simpleWinPlayed ||
        lastAction == null ||
        lastAction.action != 'fold' ||
        activePlayers.length != 1 ||
        _playbackManager.playbackIndex != actions.length) {
      return;
    }

    _winnerIndex = activePlayers.first;
    final winnerName = players[_winnerIndex!].name;
    showWinnerHighlight(context, winnerName);
    showWinnerZoneOverlay(
        context, context.read<PlayerZoneRegistry>(), winnerName);
    _returns = _calculateUncalledReturns();
    _playPotWinAnimation();
    _scheduleAutoReset();
  }

  void _onPlaybackManagerChanged() {
    if (mounted) {
      _clearBetDisplays();
      final prevSides = List<int>.from(_sidePots);
      _updateSidePots();
      final newPot = _potSync.pots[currentStreet];
      final prevPot = _displayedPots[currentStreet];
      final lastIndex = _playbackManager.playbackIndex - 1;
      final lastAction =
          lastIndex >= 0 && lastIndex < actions.length ? actions[lastIndex] : null;

      ActionEntry? undone;
      if (newPot < prevPot && _playbackManager.playbackIndex < _prevPlaybackIndex) {
        for (int i = _prevPlaybackIndex - 1; i >= _playbackManager.playbackIndex; i--) {
          if (i < actions.length) {
            final a = actions[i];
            if ((a.action == 'bet' ||
                    a.action == 'raise' ||
                    a.action == 'call' ||
                    a.action == 'all-in') &&
                a.amount != null) {
              undone = a;
              break;
            }
          }
        }
      }

      int potIndex = 0;
      final maxLen = max(prevSides.length, _sidePots.length);
      for (int i = 0; i < maxLen; i++) {
        final oldVal = i < prevSides.length ? prevSides[i] : 0;
        final newVal = i < _sidePots.length ? _sidePots[i] : 0;
        if (newVal > oldVal) potIndex = i + 1;
      }

      final potGrew = newPot > prevPot || potIndex > 0;

      if (lastAction != null &&
          (lastAction.action == 'bet' ||
              lastAction.action == 'raise' ||
              lastAction.action == 'call' ||
              lastAction.action == 'all-in') &&
          potGrew) {
        _potCountAnimation =
            IntTween(begin: prevPot, end: newPot).animate(_potCountController);
        _potCountController.forward(from: 0);
        _displayedPots[currentStreet] = newPot;
        _triggerCenterChip(lastAction);
        _handleBetAction(lastAction, potIndex: potIndex);
        _startChipFlight(lastAction);
      } else if (lastAction != null && lastAction.action == 'fold') {
        final refund = _calculateFoldRefund(lastAction.playerIndex);
        if (refund > 0) {
          _triggerFoldChipReturn(ActionEntry(
              lastAction.street, lastAction.playerIndex, 'fold',
              amount: refund));
        }
      } else if (undone != null) {
        _potCountAnimation =
            IntTween(begin: prevPot, end: newPot).animate(_potCountController);
        _potCountController.forward(from: 0);
        _displayedPots[currentStreet] = newPot;
        _playBetReturnAnimation(undone);
        _triggerFoldChipReturn(undone);
      } else {
        _displayedPots[currentStreet] = newPot;
        _potCountAnimation = IntTween(begin: newPot, end: newPot)
            .animate(_potCountController);
        _potCountController.value = 1.0;
      }
      lockService.safeSetState(this, () {
        if (_playbackManager.playbackIndex > 0 &&
            _playbackManager.playbackIndex <= actions.length) {
          _playbackNarration =
              _actionNarration(actions[_playbackManager.playbackIndex - 1]);
        } else {
          _playbackNarration = null;
        }
      });
      _setActivePlayer(_playbackManager.lastActionPlayerIndex);
      if (_animateTimeline && _timelineController.hasClients) {
        _animateTimeline = false;
        _timelineController.animateTo(
          _playbackManager.playbackIndex * _timelineExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      _actionHistory.updateHistory(actions,
          visibleCount: _playbackManager.playbackIndex);
      final active = [
        for (int i = 0; i < numberOfPlayers; i++)
          if (!_foldedPlayers.isPlayerFolded(i)) i
      ];
      final shouldShowdown =
          currentStreet == 3 &&
          lastAction != null &&
          lastAction.action == 'call' &&
          active.length == 2 &&
          _playbackManager.playbackIndex == actions.length;
      if (shouldShowdown && !_showdownActive) {
        _playShowdownReveal();
      } else if (!shouldShowdown && _showdownActive) {
        _clearShowdown();
      }
      if (_showdownActive &&
          !_winnerRevealPlayed &&
          _boardReveal.revealedBoardCards.length == 5 &&
          _playbackManager.playbackIndex == actions.length) {
        _playWinnerRevealAnimation();
      } else if (_showdownActive &&
          _pendingPotAnimation &&
          _boardReveal.revealedBoardCards.length == 5 &&
          _playbackManager.playbackIndex == actions.length) {
        _pendingPotAnimation = false;
        _playPotWinAnimation();
      }
      _maybeTriggerAutoShowdown(lastAction, active);
      _maybeTriggerSimpleWin(lastAction, active);
      _prevPlaybackIndex = _playbackManager.playbackIndex;
      _updateFinishHandButtonVisibility();
    }
  }

  void _onPlayerManagerChanged() {
    if (!mounted) return;
    _playDealAnimations();
    lockService.safeSetState(this, () {});
  }

  void _onBoardManagerChanged() {
    if (!mounted) return;
    if (_boardManager.currentStreet != _prevStreet) {
      _clearBetDisplays();
      _revealBoard();
      _playStreetTransition(_boardManager.currentStreet);
      _prevStreet = _boardManager.currentStreet;
    }
    if (_pendingPotAnimation &&
        _boardReveal.revealedBoardCards.length == 5 &&
        !_potAnimationPlayed) {
      _pendingPotAnimation = false;
      _playPotWinAnimation();
    }
    lockService.safeSetState(this, () {});
    _updateFinishHandButtonVisibility();
  }

  void _playDealAnimations() {
    final overlay = Overlay.of(context);
    final double scale = TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final tableWidth = screen.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 -
            TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;
    final center = Offset(centerX, centerY);

    final visible = boardCards.length;
    final baseY = centerY - 52 * scale;
    for (int i = 0; i < boardCards.length; i++) {
      final card = boardCards[i];
      final prev = _prevBoardCards.length > i ? _prevBoardCards[i] : null;
      if (prev != card) {
        final x = centerX + (i - (visible - 1) / 2) * 44 * scale;
        late OverlayEntry e;
        e = OverlayEntry(
          builder: (_) => DealCardAnimation(
            start: center,
            end: Offset(x, baseY),
            card: card,
            scale: scale,
            onCompleted: () => e.remove(),
          ),
        );
        overlay.insert(e);
      }
    }
    _prevBoardCards = List<CardModel>.from(boardCards);

    for (int p = 0; p < numberOfPlayers; p++) {
      final cards = playerCards[p];
      final prevCards = _prevPlayerCards[p];
      final i = (p - _viewIndex() + numberOfPlayers) % numberOfPlayers;
      final angle = 2 * pi * i / numberOfPlayers + pi / 2;
      final dx = radiusX * cos(angle);
      final dy = radiusY * sin(angle);
      final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
      final base = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
      for (int idx = 0; idx < cards.length; idx++) {
        final card = cards[idx];
        final prev = prevCards.length > idx ? prevCards[idx] : null;
        if (prev != card) {
          final pos = base + Offset((idx == 0 ? -18 : 18) * scale, 0);
          late OverlayEntry e;
          e = OverlayEntry(
            builder: (_) => DealCardAnimation(
              start: center,
              end: pos,
              card: card,
              scale: scale,
              onCompleted: () => e.remove(),
            ),
          );
          overlay.insert(e);
        }
      }
      _prevPlayerCards[p] = List<CardModel>.from(cards);
    }
  }

  /// Deal two cards to each player with staggered delays at hand start.
  void _playPreflopDealAnimation() {
    final overlay = Overlay.of(context);
    final double scale = TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final tableWidth = screen.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 -
            TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final radiusMod = TableGeometryHelper.radiusModifier(numberOfPlayers);
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;
    final center = Offset(centerX, centerY);

    int delay = 0;
    for (int p = 0; p < numberOfPlayers; p++) {
      final cards = playerCards[p];
      if (cards.length < 2) continue;
      final i = (p - _viewIndex() + numberOfPlayers) % numberOfPlayers;
      final angle = 2 * pi * i / numberOfPlayers + pi / 2;
      final dx = radiusX * cos(angle);
      final dy = radiusY * sin(angle);
      final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
      final base = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
      for (int idx = 0; idx < 2 && idx < cards.length; idx++) {
        final card = cards[idx];
        final pos = base + Offset((idx == 0 ? -18 : 18) * scale, 0);
        Future.delayed(Duration(milliseconds: delay), () {
          if (!mounted) return;
          late OverlayEntry e;
          e = OverlayEntry(
            builder: (_) => DealCardAnimation(
              start: center,
              end: pos,
              card: card,
              scale: scale,
              onCompleted: () => e.remove(),
            ),
          );
          overlay.insert(e);
        });
        delay += 120;
      }
      _prevPlayerCards[p] = List<CardModel>.from(cards);
    }
  }

  void _playBurnCardAnimation(OverlayState overlay, Offset center, double scale) {
    late OverlayEntry entry;
    final end = center + Offset(-40 * scale, -80 * scale);
    entry = OverlayEntry(
      builder: (_) => BurnCardAnimation(
        start: center,
        end: end,
        scale: scale,
        duration: _burnDuration,
        onCompleted: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  void _playFlopRevealAnimation() {
    final overlay = Overlay.of(context);
    if (boardCards.length < 3) return;
    if (widget.demoMode) _demoAnimations.showNarration('Dealing flop');
    final double scale = TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 -
            TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final center = Offset(centerX, centerY);
    final baseY = centerY - 52 * scale;

    if (widget.demoMode) {
      _playBurnCardAnimation(overlay, center, scale);
    }

    int delay = widget.demoMode ? _burnDuration.inMilliseconds : 0;
    for (int i = 0; i < 3; i++) {
      final card = boardCards[i];
      final x = centerX + (i - 1) * 44 * scale;
      Future.delayed(Duration(milliseconds: delay), () {
        if (!mounted) return;
        late OverlayEntry e;
        e = OverlayEntry(
          builder: (_) => DealCardAnimation(
            start: center,
            end: Offset(x, baseY),
            card: card,
            scale: scale,
            onCompleted: () => e.remove(),
          ),
        );
        overlay.insert(e);
      });
      delay += _revealDelay.inMilliseconds;
    }
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) {
        _revealNextBoardCard(1);
      }
    });
  }

  void _playTurnRevealAnimation() {
    final overlay = Overlay.of(context);
    if (boardCards.length < 4) return;
    if (widget.demoMode) _demoAnimations.showNarration('Turn revealed');
    final double scale = TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 -
            TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final center = Offset(centerX, centerY);
    final baseY = centerY - 52 * scale;

    if (widget.demoMode) {
      _playBurnCardAnimation(overlay, center, scale);
    }

    int delay = widget.demoMode ? _burnDuration.inMilliseconds : 0;

    final visible = BoardSyncService.stageCardCounts[2];
    final x = centerX + (3 - (visible - 1) / 2) * 44 * scale;
    final end = Offset(x, baseY);
    final start = end - Offset(40 * scale, 0);
    late OverlayEntry e;
    e = OverlayEntry(
      builder: (_) => DealCardAnimation(
        start: start,
        end: end,
        card: boardCards[3],
        scale: scale,
        onCompleted: () => e.remove(),
      ),
    );
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      overlay.insert(e);
    });
    delay += _revealDelay.inMilliseconds;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) {
        _revealNextBoardCard(2);
      }
    });
  }

  void _playRiverRevealAnimation() {
    final overlay = Overlay.of(context);
    if (boardCards.length < 5) return;
    if (widget.demoMode) _demoAnimations.showNarration('River revealed');
    final double scale = TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 -
            TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final center = Offset(centerX, centerY);
    final baseY = centerY - 52 * scale;

    if (widget.demoMode) {
      _playBurnCardAnimation(overlay, center, scale);
    }

    int delay = widget.demoMode ? _burnDuration.inMilliseconds : 0;

    final visible = BoardSyncService.stageCardCounts[3];
    final x = centerX + (4 - (visible - 1) / 2) * 44 * scale;
    final end = Offset(x, baseY);
    final start = end + Offset(40 * scale, 0);
    late OverlayEntry e;
    e = OverlayEntry(
      builder: (_) => DealCardAnimation(
        start: start,
        end: end,
        card: boardCards[4],
        scale: scale,
        onCompleted: () => e.remove(),
      ),
    );
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      overlay.insert(e);
    });
    delay += _revealDelay.inMilliseconds;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) {
        _revealNextBoardCard(3);
      }
    });
  }

  /// Reveals the board up to [street] with a burn card animation in demo mode.
  void _revealNextBoardCard(int street) {
    if (widget.demoMode) {
      final overlay = Overlay.of(context);
      final double scale = TableGeometryHelper.tableScale(numberOfPlayers);
      final screen = MediaQuery.of(context).size;
      final centerX = screen.width / 2 + 10;
      final centerY =
          screen.height / 2 -
              TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
      final center = Offset(centerX, centerY);
      _playBurnCardAnimation(overlay, center, scale);
          Future.delayed(_burnDuration, () {
        if (mounted) _boardReveal.revealStreet(street);
      });
    } else {
      _boardReveal.revealStreet(street);
    }
  }

  /// Plays the full dealing sequence for a newly reset hand.
  /// Hole cards are dealt first followed by flop, turn and river
  /// with small delays between stages.
  void _playDealSequence() {
    _playPreflopDealAnimation();
    int delay = numberOfPlayers * 2 * 120 + 300;
    if (boardCards.length >= 3) {
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) _playFlopRevealAnimation();
      });
      delay +=
          (widget.demoMode ? _burnDuration.inMilliseconds : 0) +
          _revealDelay.inMilliseconds * 3 +
          400;
    }
    if (boardCards.length >= 4) {
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) _playTurnRevealAnimation();
      });
      delay +=
          (widget.demoMode ? _burnDuration.inMilliseconds : 0) +
          _revealDelay.inMilliseconds +
          400;
    }
    if (boardCards.length >= 5) {
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) _playRiverRevealAnimation();
      });
    }
  }

  void _startNewHand() {
    _clearActiveHighlight();
    _prevBoardCards = List<CardModel>.from(boardCards);
    for (int i = 0; i < numberOfPlayers; i++) {
      _prevPlayerCards[i] = List<CardModel>.from(playerCards[i]);
    }
    _bustedPlayers.clear();
    _playPreflopDealAnimation();
    _playbackNarration = null;
  }

  void _revealBoard() {
    if (currentStreet == 1) {
      _playFlopRevealAnimation();
      if (boardCards.length >= 3) {
        _demoAnimations.showNarration('Dealing flop');
      }
    } else if (currentStreet == 2) {
      _playTurnRevealAnimation();
      if (boardCards.length >= 4) {
        _demoAnimations.showNarration('Turn revealed');
      }
    } else if (currentStreet == 3) {
      _playRiverRevealAnimation();
      if (boardCards.length >= 5) {
        _demoAnimations.showNarration('River revealed');
      }
    }
  }

  void _playStreetTransition(int street) {
    final overlay = Overlay.of(context);
    const names = ['Preflop', 'Flop', 'Turn', 'River'];
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => StreetTransitionOverlay(
        streetName: names[street.clamp(0, names.length - 1)],
        onComplete: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  void _onStackServiceChanged() {
    if (mounted) {
      _displayedStacks
        ..clear()
        ..addAll(_stackService.currentStacks);
      _updateBustedPlayers();
      _updateSidePots();
      lockService.safeSetState(this, () {});
    }
  }

  void _onFoldedPlayersChanged() {
    if (!mounted) return;
    final current = Set<int>.from(_foldedPlayers.players);
    final added = current.difference(_prevFoldedPlayers);
    final removed = _prevFoldedPlayers.difference(current);

    for (final index in removed) {
      _foldControllers[index]?.dispose();
      _foldControllers.remove(index);
    }

    for (final index in added) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
      );
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller.dispose();
          _foldControllers.remove(index);
          if (mounted) lockService.safeSetState(this, () {});
        }
      });
      _foldControllers[index] = controller;
      controller.forward();
      _triggerFoldDisplay(index);
    }

    _prevFoldedPlayers = current;
    lockService.safeSetState(this, () {});
  }

  void _onAllInPlayersChanged() {
    if (!mounted) return;
    _updateBustedPlayers();
    lockService.safeSetState(this, () {});
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




  void _addAutoFolds(ActionEntry entry) {
    final street = entry.street;
    final ordered = List.generate(_playerManager.numberOfPlayers,
        (i) => (i + _playerManager.heroIndex) % _playerManager.numberOfPlayers);
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
      _actionEditing.removeFutureActionsForPlayer(
          i, street, actions.length - 1);
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
    if (lockService.isLocked) return;
    final insertIndex = index ?? actions.length;
    _clearBetDisplays();
    _actionEditing.insertAction(insertIndex, entry,
        recordHistory: recordHistory);
    if (entry.action == 'fold') {
      _playFoldAnimation(entry.playerIndex);
    }
    _triggerBetDisplay(entry);
    if (['bet', 'raise', 'call', 'all-in'].contains(entry.action) &&
        (entry.amount ?? 0) > 0) {
      // Animation handled via ActionEditingService
    }
    _deductStackAfterAction(entry);
    _updateCurrentPot(entry);
    _applyOverbetRefunds();
    _clearActiveHighlight();
  }

  void _insertAction(int index, ActionEntry entry) {
    if (lockService.isLocked) return;
    lockService.safeSetState(this, () {
      _addAction(entry, index: index);
      _clearActiveHighlight();
    });
  }

  void onActionSelected(ActionEntry entry) {
    lockService.safeSetState(this, () {
      _addAutoFolds(entry);
      if (entry.action == 'fold') {
        _triggerFoldDisplay(entry.playerIndex);
        _playFoldTrashAnimation(entry.playerIndex);
        final refund = _calculateFoldRefund(entry.playerIndex);
        if (refund > 0) {
          _applyRefund(entry.playerIndex, refund);
        }
        _addAction(entry);
        _actionEditing.removeFutureActionsForPlayer(
            entry.playerIndex, entry.street, actions.length - 1);
      } else {
        _addAction(entry);
      }
      _clearActiveHighlight();
    });
  }

  /// Public handler for player actions that also triggers animations.
  void handlePlayerAction(ActionEntry entry) {
    onActionSelected(entry);
  }

  /// Handler used during demo playback to insert actions with custom
  /// animations.
  void handleAnalyzerAction(ActionEntry entry) {
    if (lockService.isLocked) return;
    lockService.safeSetState(this, () {
      _addAction(entry, recordHistory: false);
      if (widget.demoMode &&
          (entry.action == 'bet' || entry.action == 'raise') &&
          entry.amount != null &&
          entry.amount! > 0) {
        _handleBetAction(entry);
      }
    });
  }

  void _editAction(int index, ActionEntry entry) {
    if (lockService.isLocked) return;
    lockService.safeSetState(this, () {
      _clearBetDisplays();
      _actionEditing.editAction(index, entry);
      _triggerBetDisplay(entry);
      if (['bet', 'raise', 'call', 'all-in'].contains(entry.action) &&
          (entry.amount ?? 0) > 0) {
        // Animation handled via ActionEditingService
      }
      _deductStackAfterAction(entry);
      _recomputeCurrentPot();
      _clearActiveHighlight();
    });
  }


  void _deleteAction(int index,
      {bool recordHistory = true, bool withSetState = true}) {
    void perform() {
      _actionEditing.deleteAction(index, recordHistory: recordHistory);
    }

      if (withSetState) {
      lockService.safeSetState(this, () {
        perform();
        _recomputeCurrentPot();
        _clearActiveHighlight();
      });
    } else {
      perform();
      _recomputeCurrentPot();
      _clearActiveHighlight();
    }
  }

  void _reorderAction(int oldIndex, int newIndex) {
    if (lockService.isLocked) return;
    lockService.safeSetState(this, () {
      _actionEditing.reorderAction(oldIndex, newIndex);
      _recomputeCurrentPot();
      _clearActiveHighlight();
    });
  }

  void _duplicateAction(int index) {
    if (lockService.isLocked) return;
    lockService.safeSetState(this, () {
      final original = actions[index];
      final copy = ActionEntry(
        original.street,
        original.playerIndex,
        original.action,
        amount: original.amount,
        generated: original.generated,
        manualEvaluation: original.manualEvaluation,
        timestamp: original.timestamp,
      );
      _actionEditing.insertAction(index + 1, copy);
      _recomputeCurrentPot();
      _clearActiveHighlight();
    });
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
      await _clearTableState();
      lockService.safeSetState(this, () {
        _deleteAction(actionIndex, withSetState: false);
        _clearActiveHighlight();
      });
    }
  }

  void _undoAction() {
    final beforeActions = List<ActionEntry>.from(actions);
    final beforeStacks = {
      for (int i = 0; i < numberOfPlayers; i++) i: _stackService.getStackForPlayer(i)
    };
    lockService.safeSetState(this, () {
      _undoRedoService.undo();
      _animateTimeline = true;
    });
    final afterActions = actions;
    final afterStacks = {
      for (int i = 0; i < numberOfPlayers; i++) i: _stackService.getStackForPlayer(i)
    };
    _debugPanelSetState?.call(() {});
    final refunds = <int, int>{};
    for (final i in beforeStacks.keys) {
      final diff = afterStacks[i]! - beforeStacks[i]!;
      if (diff > 0) refunds[i] = diff;
    }
    if (refunds.isNotEmpty) {
      _playUndoRefundAnimations(refunds);
    } else {
      ActionEntry? undone;
      ActionEntry? foldUndone;
      if (beforeActions.length > afterActions.length) {
        for (int i = beforeActions.length - 1; i >= afterActions.length; i--) {
          final a = beforeActions[i];
          if (a.action == 'fold') {
            foldUndone = a;
            break;
          }
          if ((['bet', 'raise', 'call', 'all-in'].contains(a.action)) &&
              a.amount != null) {
            undone = a;
            break;
          }
        }
      } else {
        for (int i = 0; i < beforeActions.length && i < afterActions.length; i++) {
          final b = beforeActions[i];
          final a = afterActions[i];
          if (b.street != a.street ||
              b.playerIndex != a.playerIndex ||
              b.action != a.action ||
              b.amount != a.amount) {
            if (b.action == 'fold') {
              foldUndone = b;
            } else if ((['bet', 'raise', 'call', 'all-in'].contains(b.action)) &&
                b.amount != null) {
              undone = b;
            }
            break;
          }
        }
      }
      if (foldUndone != null) {
        _playFoldAnimation(foldUndone.playerIndex);
        final refund = _calculateFoldRefund(foldUndone.playerIndex);
        if (refund > 0) {
          _triggerFoldChipReturn(ActionEntry(
              foldUndone.street, foldUndone.playerIndex, 'fold',
              amount: refund));
        }
      } else if (undone != null) {
        _playBetReturnAnimation(undone);
        _triggerFoldChipReturn(undone);
      }
    }
    _clearActiveHighlight();
  }

  void _redoAction() {
    lockService.safeSetState(this, () {
      _undoRedoService.redo();
      _animateTimeline = true;
    });
    _debugPanelSetState?.call(() {});
    _clearActiveHighlight();
  }

  void _previousStreet() {
    if (lockService.isLocked || !_boardManager.canReverseStreet()) return;
    lockService.safeSetState(this, () {
      _actionTagService.clear();
      _boardManager.reverseStreet();
      _undoRedoService.recordSnapshot();
    });
    _debugPanelSetState?.call(() {});
  }

  void _nextStreet() {
    if (lockService.isLocked || !_boardManager.canAdvanceStreet()) return;
    lockService.safeSetState(this, () {
      _actionTagService.clear();
      _boardManager.advanceStreet();
      _undoRedoService.recordSnapshot();
    });
    _debugPanelSetState?.call(() {});
  }

    int updatedHeroIndex = _playerManager.heroIndex;

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
      _playerEditing.removePlayer(
        index,
        heroIndexOverride: updatedHeroIndex,
        actions: actions,
        hintFlags: _playerManager.showActionHints,
      );
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
      await _clearTableState();
      lockService.safeSetState(this, () {
        _playerManager.reset();
        _undoRedoService.resetHistory();
        _foldedPlayers.reset();
        _allInPlayers.reset();
        _boardManager.clearBoard();
        _actionTagService.clear();
        _stackService.reset(
            Map<int, int>.from(_playerManager.initialStacks));
        _playbackManager.resetHand();
        _handContext.clear();
      });
      _startNewHand();
    }
  }

  void _cancelHandAnalysis() {
    _clearActiveHighlight();
    _activeTimer?.cancel();
    _centerChipTimer?.cancel();
    _centerChipOrigin = null;
    for (final t in _betTimers.values) {
      t.cancel();
    }
    _betTimers.clear();
    _boardKey.currentState?.cancelPendingReveals();
    _boardManager.cancelBoardReveal();
    _boardReveal.cancelBoardReveal();
    _clearBetDisplays();
    _clearShowdown();
    _potSync.reset();
    for (int i = 0; i < _displayedPots.length; i++) {
      _displayedPots[i] = 0;
    }
    _sidePots.clear();
    _playbackManager.resetHand();
    lockService.safeSetState(this, () {});
  }

  Future<void> _startNewHandFromFab() async {
    await resetAll();
    _handContext.clear();
    if (_timelineController.hasClients) {
      _timelineController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _defaultHandName() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    return 'Раздача от $day.$month.$year';
  }

  double _handFillProgress() {
    final totalCards = numberOfPlayers * 2 + 5;
    int filled = boardCards.length;
    for (final cards in playerCards.take(numberOfPlayers)) {
      filled += cards.length;
    }
    if (totalCards == 0) return 0;
    return (filled / totalCards).clamp(0.0, 1.0);
  }


  Future<void> _exportEvaluationQueue() async {
    await _importExportService.exportEvaluationQueue(context);
  }

  Future<void> _exportQueueToClipboard() async {
    await _importExportService.exportQueueToClipboard(context);
  }

  Future<void> _importQueueFromClipboard() async {
    await _importExportService.importQueueFromClipboard(context);
    lockService.safeSetState(this, () {});
    _debugPanelSetState?.call(() {});
  }

  Future<void> _exportFullEvaluationQueueState() async {
    await _importExportService.exportFullQueueState(context);
  }

  Future<void> _importFullEvaluationQueueState() async {
    await _importExportService.importFullQueueState(context);
    if (mounted) setState(() {});
    _debugPanelSetState?.call(() {});
  }

  Future<void> _restoreFullEvaluationQueueState() async {
    await _importExportService.restoreFullQueueState(context);
    if (mounted) setState(() {});
    _debugPanelSetState?.call(() {});
  }

  Future<void> _backupEvaluationQueue() async {
    await _importExportService.backupEvaluationQueue(context);
  }

  Future<void> _quickBackupEvaluationQueue() async {
    await _importExportService.quickBackupEvaluationQueue(context);
    _debugPanelSetState?.call(() {});
  }

  Future<void> _exportEvaluationQueueSnapshot({bool showNotification = true}) async {
    await _importExportService.exportEvaluationQueueSnapshot(
      context,
      showNotification: showNotification,
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

  Future<void> _initializeDebugPreferences() async {
    await _debugPrefs.loadAllPreferences();
    if (_debugPrefs.snapshotRetentionEnabled) {
      await _importExportService.cleanupOldEvaluationSnapshots();
    }
    if (mounted) lockService.safeSetState(this, () {});
  }

  Future<void> _exportArchive(String subfolder, String archivePrefix) async {
    await _importExportService.exportArchive(context, subfolder, archivePrefix);
    if (mounted) setState(() {});
  }

  Future<void> _exportAllEvaluationBackups() async {
    await _importExportService.exportAllEvaluationBackups(context);
  }

  Future<void> _exportAutoBackups() async {
    await _importExportService.exportAutoBackups(context);
  }

  Future<void> _exportSnapshots() async {
    await _importExportService.exportSnapshots(context);
  }

  Future<void> _restoreFromAutoBackup() async {
    await _importExportService.restoreFromAutoBackup(context);
    if (mounted) setState(() {});
    _debugPanelSetState?.call(() {});
  }

  Future<void> _exportAllEvaluationSnapshots() async {
    await _importExportService.exportAllEvaluationSnapshots(context);
  }

  Future<void> _importEvaluationQueue() async {
    await _importExportService.importEvaluationQueue(context);
    _debugPanelSetState?.call(() {});
    unawaited(_debugPrefs.setEvaluationQueueResumed(false));
  }

  Future<void> _restoreEvaluationQueue() async {
    await _importExportService.restoreEvaluationQueue(context);
  }

  Future<void> _bulkImportEvaluationQueue() async {
    await _importExportService.bulkImportEvaluationQueue(context);
    if (mounted) setState(() {});
    _debugPanelSetState?.call(() {});
  }


  Future<void> _importEvaluationQueueSnapshot() async {
    await _importExportService.importEvaluationQueueSnapshot(context);
    if (mounted) setState(() {});
    _debugPanelSetState?.call(() {});
  }

  Future<void> _bulkImportEvaluationSnapshots() async {
    await _importExportService.bulkImportEvaluationSnapshots(context);
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
      await _importExportService.cleanupOldEvaluationSnapshots();
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

  void _foldAllOpponents() {
    const color = Colors.red;
    for (int i = 0; i < numberOfPlayers; i++) {
      if (i == heroIndex) continue;
      setPlayerLastAction(context.read<PlayerZoneRegistry>(),
          players[i].name, 'Fold', color, 'fold');
    }
  }


  SavedHand _currentSavedHand({
    String? name,
    String? tournamentId,
    int? buyIn,
    int? totalPrizePool,
    int? numberOfEntrants,
    String? gameType,
    String? category,
  }) {
    return _handImportExportService.buildHand(
      name: name ?? _defaultHandName(),
      playerManager: _playerManager,
      stackService: _stackService,
      boardManager: _boardManager,
      actionSync: _actionSync,
      potSync: _potSync,
      actionHistory: _actionHistory,
      foldedPlayers: _foldedPlayers,
      allInPlayers: _allInPlayers,
      actionTags: _actionTagService,
      queueService: _queueService,
      playbackManager: _playbackManager,
      boardReveal: _boardReveal,
      handContext: _handContext,
      tournamentId: tournamentId ?? _handContext.tournamentId,
      buyIn: buyIn ?? _handContext.buyIn,
      totalPrizePool: totalPrizePool ?? _handContext.totalPrizePool,
      numberOfEntrants: numberOfEntrants ?? _handContext.numberOfEntrants,
      gameType: gameType ?? _handContext.gameType,
      category: category,
      activePlayerIndex: activePlayerIndex,
    );
  }

  Future<String> saveHand() async {
    _addQualityTags();
    if (!await _ensureGameInfo()) return '';
    final hand = _currentSavedHand(
      gameType: _handContext.gameType,
      category: _handContext.category,
    );
    return _handImportExportService.serializeHand(hand);
  }

  void loadHand(String jsonStr) {
    final hand = _handImportExportService.deserializeHand(jsonStr);
    _stackService = _handRestore.restoreHand(hand);
    _playerManager.attachStackManager(_stackService);
    _actionSync.attachStackManager(_stackService);
    _potSync.stackService = _stackService;
    _displayedStacks
      ..clear()
      ..addAll(_stackService.currentStacks);
    _actionSync.updatePlaybackIndex(_playbackManager.playbackIndex);
    _boardManager.startBoardTransition();
    _startNewHand();
  }

  TrainingSpot _currentTrainingSpot() {
    return _trainingImportExportService.buildSpot(
      playerManager: _playerManager,
      boardManager: _boardManager,
      actionSync: _actionSync,
      stackManager: _stackService,
      tournamentId: _handContext.tournamentId,
      buyIn: _handContext.buyIn,
      totalPrizePool: _handContext.totalPrizePool,
      numberOfEntrants: _handContext.numberOfEntrants,
      gameType: _handContext.gameType,
    );
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
  void loadTrainingSpot(TrainingSpot data) {
    lockService.safeSetState(this, () {
      _trainingImportExportService.applySpot(
        data,
        playerManager: _playerManager,
        boardManager: _boardManager,
        actionSync: _actionSync,
        playbackManager: _playbackManager,
        handContext: _handContext,
      );
    });
    _boardManager.startBoardTransition();
    _startNewHand();
  }

  Future<void> saveCurrentHand() async {
    if (_transitionHistory.isLocked) return;
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
    if (!await _ensureGameInfo()) return;
    final hand = _currentSavedHand(
      name: handName,
      gameType: _handContext.gameType,
      category: _handContext.category,
    );
    await _handManager.add(hand);
    lockService.safeSetState(this, () => _handContext.currentHandName = handName);
  }

  void loadLastSavedHand() {
    if (_transitionHistory.isLocked) return;
    final hand = _handManager.lastHand;
    if (hand == null) return;
    _stackService = _handRestore.restoreHand(hand);
    _playerManager.attachStackManager(_stackService);
    _actionSync.attachStackManager(_stackService);
    _potSync.stackService = _stackService;
    _displayedStacks
      ..clear()
      ..addAll(_stackService.currentStacks);
    _actionSync.updatePlaybackIndex(_playbackManager.playbackIndex);
    _boardManager.startBoardTransition();
    _startNewHand();
  }

  Future<void> loadHandByName() async {
    if (_transitionHistory.isLocked) return;
    final selected = await _handManager.selectHand(context);
    if (selected != null) {
        _stackService = _handRestore.restoreHand(selected);
        _playerManager.attachStackManager(_stackService);
        _actionSync.attachStackManager(_stackService);
        _potSync.stackService = _stackService;
        _displayedStacks
          ..clear()
          ..addAll(_stackService.currentStacks);
        _actionSync.updatePlaybackIndex(_playbackManager.playbackIndex);
        _boardManager.startBoardTransition();
        _startNewHand();
      }
  }


  Future<void> exportLastSavedHand() async {
    if (_transitionHistory.isLocked) return;
    await _handImportExportService.exportLastHand(context);
  }

  Future<void> exportAllHands() async {
    if (_transitionHistory.isLocked) return;
    await _handImportExportService.exportAllHands(context);
  }

  Future<void> importHandFromClipboard() async {
    if (_transitionHistory.isLocked) return;
    final hand = await _handImportExportService.importHandFromClipboard(context);
    if (hand != null) {
      _stackService = _handRestore.restoreHand(hand);
      _playerManager.attachStackManager(_stackService);
      _actionSync.attachStackManager(_stackService);
      _potSync.stackService = _stackService;
      _displayedStacks
        ..clear()
        ..addAll(_stackService.currentStacks);
      _actionSync.updatePlaybackIndex(_playbackManager.playbackIndex);
      _boardManager.startBoardTransition();
      _startNewHand();
    }
  }

  Future<void> importAllHandsFromClipboard() async {
    if (_transitionHistory.isLocked) return;
    await _handImportExportService.importAllHandsFromClipboard(context);
  }

  Future<void> exportTrainingSpotToClipboard() async {
    if (_transitionHistory.isLocked) return;
    await _trainingImportExportService.exportToClipboard(
        context, _currentTrainingSpot());
  }

  Future<void> importTrainingSpotFromClipboard() async {
    if (_transitionHistory.isLocked) return;
    final spot = await _trainingImportExportService.importFromClipboard(context);
    if (spot != null) {
      loadTrainingSpot(spot);
    }
  }

  Future<void> exportTrainingSpotToFile() async {
    if (_transitionHistory.isLocked) return;
    await _trainingImportExportService.exportToFile(
        context, _currentTrainingSpot());
  }

  Future<void> importTrainingSpotFromFile() async {
    if (_transitionHistory.isLocked) return;
    final spot = await _trainingImportExportService.importFromFile(context);
    if (spot != null) loadTrainingSpot(spot);
  }

  Future<void> exportTrainingArchive() async {
    if (_transitionHistory.isLocked) return;
    await _trainingImportExportService
        .exportArchive(context, [_currentTrainingSpot()]);
  }

  Future<void> exportPlayerProfileToClipboard() async {
    if (_transitionHistory.isLocked) return;
    await _playerManager.exportProfileToClipboard(context);
  }

  Future<void> importPlayerProfileFromClipboard() async {
    if (_transitionHistory.isLocked) return;
    await _playerManager.importProfileFromClipboard(context);
  }

  Future<void> exportPlayerProfileToFile() async {
    if (_transitionHistory.isLocked) return;
    await _playerManager.exportProfileToFile(context);
  }

  Future<void> importPlayerProfileFromFile() async {
    if (_transitionHistory.isLocked) return;
    await _playerManager.importProfileFromFile(context);
  }

  Future<void> exportPlayerProfileArchive() async {
    if (_transitionHistory.isLocked) return;
    await _playerManager.exportProfileArchive(context);
  }



  @override
  void dispose() {
    _activeTimer?.cancel();
    _playerManager.removeListener(_onPlayerManagerChanged);
    _playbackManager.removeListener(_onPlaybackManagerChanged);
    _stackService.removeListener(_onStackServiceChanged);
    _foldedPlayers.removeListener(_onFoldedPlayersChanged);
    _allInPlayers.removeListener(_onAllInPlayersChanged);
    for (final c in _foldControllers.values) {
      c.dispose();
    }
    for (final c in _stackIncreaseControllers.values) {
      c.dispose();
    }
    _stackIncreaseControllers.clear();
    for (final t in _betTimers.values) {
      t.cancel();
    }
    _betTimers.clear();
    _autoNextHandTimer?.cancel();
    _demoAnimations.dispose();
    _centerChipTimer?.cancel();
    _removeMessageOverlays();
    _processingService.cleanup();
    _centerChipController.dispose();
    _potGrowthController.dispose();
    _potCountController.dispose();
    _timelineController.dispose();
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
    final pot = _potSync.pots[currentStreet];
    final totalPot = _potSync.pots.reduce(max);
    final double? sprValue =
        pot > 0 ? effectiveStack / pot : null;

    final hint = _validationHint;

    return Provider<PokerAnalyzerScreenState>.value(
      value: this,
      child: Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        floatingActionButtonLocation: widget.demoMode
          ? FloatingActionButtonLocation.endTop
          : FloatingActionButtonLocation.endFloat,
      floatingActionButton: widget.demoMode
          ? AnimatedOpacity(
              opacity: _showReplayDemoButton ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: FloatingActionButton(
                heroTag: 'replayDemoFab',
                onPressed: _replayDemo,
                child: const Icon(Icons.replay),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: _isHandEmpty
                      ? const FloatingActionButton.extended(
                          key: ValueKey('newHandFab'),
                          heroTag: 'newHandFab',
                          onPressed: _startNewHandFromFab,
                          label: Text('Новая раздача'),
                          icon: Icon(Icons.add),
                        )
                      : const SizedBox.shrink(key: ValueKey('noNewHandFab')),
                ),
                const SizedBox(height: 12),
                const FloatingActionButton(
                  heroTag: 'debugFab',
                  onPressed: _showDebugPanel,
                  child: Icon(Icons.bug_report),
                ),
              ],
            ),
        child: LayoutBuilder(
            builder: (context, constraints) {
              final landscape = constraints.maxWidth > constraints.maxHeight;
              final shortest = constraints.biggest.shortestSide;
              _uiScale = shortest < 600 ? 0.8 : 1.0;


              final content = <Widget>[
                AnalyzerHUDPanel(
                  handName: _handContext.currentHandName ?? 'New Hand',
                  playerCount: numberOfPlayers,
                  streetName: ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'][currentStreet],
                  onEdit: loadHandByName,
                  handCompletionProgress: _handFillProgress(),
                  numberOfPlayers: numberOfPlayers,
                  playerPositions: playerPositions,
                  playerTypes: playerTypes,
                  onPlayerCountChanged:
                      lockService.isLocked ? null : _onPlayerCountChanged,
                  disabled: lockService.isLocked,
                  handProgressStep: _handProgressStep(),
                ),
                SmartInboxContainer(message: hint),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    'Effective Stack (Current Street): $currentStreetEffectiveStack BB',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                GameplayAreaWidget(
                  landscape: landscape,
                  uiScale: _uiScale,
                ),
                const Expanded(child: ActionEditor()),
                const Expanded(child: EvaluationPanel()),
              ];
              return AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(children: content),
              );
            },
          ),
        ),
      ),
    ),
    )
  }

  List<Widget> _buildPlayerWidgets(int i, double scale) {
    final screenSize = MediaQuery.of(context).size;
    final double infoScale = numberOfPlayers > 8 ? 0.85 : 1.0;
    final tableWidth = screenSize.width * 0.9 * scale;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

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
    final offset = TableGeometryHelper.positionForPlayer(
        i, numberOfPlayers, tableWidth, tableHeight);
    final dx = offset.dx;
    final dy = offset.dy;
    const bias = 0.0;

    final String position = playerPositions[index] ?? '';
    final int dealerIndex = playerPositions.entries
        .firstWhere((e) => e.value == 'BTN', orElse: () => const MapEntry(0, ''))
        .key;
    final int stack = _displayedStacks[index] ??
        _stackService.getStackForPlayer(index);
    final String tag = _actionTagService.getTag(index) ?? '';
    final bool isActive = activePlayerIndex == index;
    final bool isFolded = _foldedPlayers.isPlayerFolded(index);
    final bool isAllIn = _allInPlayers.isPlayerAllIn(index);
    final int pot = _potSync.pots[currentStreet];
    final double? playerSpr = pot > 0 ? stack / pot.toDouble() : null;

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
    final int totalInvested = _stackService.getTotalInvested(index);

    final Color? actionColor =
        (lastAction?.action == 'bet' || lastAction?.action == 'raise')
            ? Colors.green
            : lastAction?.action == 'call'
                ? Colors.blue
                : null;
    final double maxRadius = 36 * scale;
    final double radius = (_potSync.pots[currentStreet] > 0)
        ? min(
            maxRadius,
            (invested / _potSync.pots[currentStreet]) * maxRadius,
          )
        : 0.0;

    final widgets = <Widget>[
      AnimatedOpacity(
        opacity: isActive ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: _ActivePlayerHighlight(
          position: Offset(centerX + dx, centerY + dy),
          scale: scale * infoScale,
          bias: bias,
        ),
      ),
      if (isActive && !lockService.isLocked)
        Positioned(
          left: centerX + dx - 12 * scale,
          top: centerY + dy + bias - 90 * scale,
          child: TurnCountdownOverlay(
            scale: scale,
            onComplete: () => _onPlayerTimeExpired(index),
            showSeconds: true,
          ),
        ),
      // action arrow behind player widgets
      Positioned(
        left: centerX + dx,
        top: centerY + dy + bias + 12,
        child: IgnorePointer(
          child: AnimatedOpacity(
            opacity: (lastStreetAction != null &&
                    lastStreetAction.playerIndex == index &&
                    (lastStreetAction.action == 'bet' ||
                        lastStreetAction.action == 'raise' ||
                        lastStreetAction.action == 'call'))
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
                  color: AppColors.accent.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.6),
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
          child: AnimatedScale(
            scale: isFolded ? 0.9 : 1.0,
            duration: const Duration(milliseconds: 400),
            child: AnimatedOpacity(
              opacity: isFolded
                  ? 0.4
                  : (_focusOnHero && index != _playerManager.heroIndex
                      ? 0.3
                      : 1.0),
              duration: const Duration(milliseconds: 400),
              child: AbsorbPointer(
                absorbing: lockService.isLocked,
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
            remainingStack:
                _displayedStacks[index] ?? _stackService.getStackForPlayer(index),
            streetInvestment: invested,
            currentBet: currentBet,
            lastAction: lastAction?.action,
            showLastIndicator: lastStreetAction?.playerIndex == index,
            isActive: isActive,
            isFolded: isFolded,
            isHero: index == _playerManager.heroIndex,
            isOpponent: index == opponentIndex,
            revealCards: _showdownPlayers.contains(index),
            playerTypeIcon: _playerTypeEmoji(
                _playerManager.playerTypes[index]),
            playerTypeLabel: _playerManager.numberOfPlayers > 9
                ? null
                : _playerTypeLabel(_playerManager.playerTypes[index]),
            positionLabel:
                _playerManager.numberOfPlayers <= 9
                    ? _positionLabelForIndex(index)
                    : null,
            blindLabel: (_playerManager.playerPositions[index] == 'SB' ||
                    _playerManager.playerPositions[index] == 'BB')
                ? _playerManager.playerPositions[index]
                : null,
            timersDisabled: lockService.isLocked,
            isBust: _bustedPlayers.contains(index),
            onCardTap: lockService.isLocked
                ? null
                : (cardIndex) => _onPlayerCardTap(index, cardIndex),
            onTap: () => _onPlayerTap(index),
            onDoubleTap: lockService.isLocked
                ? null
                : () => _setHeroIndex(index),
            onLongPress: lockService.isLocked ? null : () => _showPlayerProfile(index),
            onEdit: lockService.isLocked ? null : () => _editPlayerInfo(index),
            onStackTap: lockService.isLocked
                ? null
                : (value) => lockService.safeSetState(this, () {
                      _playerEditing.setInitialStack(index, value);
                    }),
            onRemove: _playerManager.numberOfPlayers > 2 && !lockService.isLocked
                ? () {
                    _removePlayer(index);
                  }
                : null,
            onTimeExpired: () => _onPlayerTimeExpired(index),
              ),
            ),
          ),
        ),
      ),
      if (lastAmountAction != null)
        Positioned(
          left: centerX + dx - 24 * scale,
          top: centerY + dy + bias - 80 * scale,
          child: ChipAmountWidget(
            amount: lastAmountAction.amount!.toDouble(),
            color: ActionFormattingHelper.actionColor(
                lastAmountAction.action),
            scale: scale,
          ),
        ),
      Positioned(
        left: centerX + dx - 8 * scale,
        top: centerY + dy + bias + 50 * scale,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: _currentStreetBet(index) > 0
              ? BetStackChips(
                  key: ValueKey(_currentStreetBet(index)),
                  amount: _currentStreetBet(index),
                  scale: scale * 0.9,
                )
              : SizedBox(key: const ValueKey('empty'), height: 16 * scale),
        ),
      ),
      if (currentBet > 0 && !isFolded)
        Positioned(
          left: centerX + dx - 16 * scale,
          top: centerY + dy + bias + 60 * scale,
          child: PlayerBetIndicator(
            action: lastAmountAction!.action,
            amount: currentBet,
            scale: scale * 0.8,
          ),
        ),
      Positioned(
        left: centerX + dx - 12 * scale,
        top: centerY + dy + bias + 70 * scale,
        child: PlayerStackChips(
          stack: stack,
          scale: scale * 0.9,
          isBust: _bustedPlayers.contains(index),
        ),
      ),
      Positioned(
        left: centerX + dx - 20 * scale,
        top: centerY + dy + bias + 84 * scale,
        child: PlayerStackValue(
          stack: stack,
          scale: scale * 0.9,
          isBust: _bustedPlayers.contains(index),
        ),
      ),
      Positioned(
        left: centerX + dx - 20 * scale,
        top: centerY + dy + bias + 90 * scale,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(6),
          ),
          child: AnimatedOpacity(
            opacity: _bustedPlayers.contains(index) ? 0.3 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Text(
                '${ActionFormattingHelper.formatAmount(_stackService.currentStacks[index] ?? 0)} BB',
                key: ValueKey(_stackService.currentStacks[index] ?? 0),
                style: TextStyle(
                  color: _bustedPlayers.contains(index) ? Colors.grey : Colors.white,
                  fontSize: 10 * scale,
                ),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: centerX + dx - 20 * scale,
        top: centerY + dy + bias + 102 * scale,
        child: SPRLabel(spr: playerSpr, scale: scale * 0.8),
      ),
      if (isFolded)
        Positioned(
          left: centerX + dx - 24 * scale,
          top: centerY + dy + bias - 40 * scale,
          child: Container(
            padding:
                EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'FOLDED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      if (_foldControllers.containsKey(index))
        Positioned(
          left: centerX + dx - 15 * scale,
          top: centerY + dy + bias - 50 * scale,
          child: FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.0)
                .animate(CurvedAnimation(
                    parent: _foldControllers[index]!, curve: Curves.easeOut)),
            child: ScaleTransition(
              scale: Tween(begin: 1.0, end: 0.0)
                  .animate(CurvedAnimation(
                      parent: _foldControllers[index]!,
                      curve: Curves.easeOut)),
              child: Image.asset(
                'assets/cards/card_back.png',
                width: 30 * scale,
                height: 42 * scale,
                color: Colors.red.shade900,
              ),
            ),
          ),
        ),
      if (isAllIn)
        Positioned(
          left: centerX + dx - 24 * scale,
          top: centerY + dy + bias - 54 * scale,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: Container(
              key: const ValueKey('allin'),
              padding: EdgeInsets.symmetric(
                  horizontal: 6 * scale, vertical: 2 * scale),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(0.8),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Text(
                'ALL-IN',
                style: TextStyle(
                  color: Colors.purpleAccent,
                  fontSize: 10 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      Positioned(
        left: centerX + dx - 20 * scale,
        top: centerY + dy + bias + 108 * scale,
        child:
            TotalInvestedLabel(total: totalInvested, scale: scale * 0.8),
      ),
      Positioned(
        left: centerX + dx - 20 * scale,
        top: centerY + dy + bias + 120 * scale,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: _recentBets[index] != null
              ? BetSizeLabel(
                  key: ValueKey(_recentBets[index]!.id),
                  amount: _recentBets[index]!.amount,
                  color: _recentBets[index]!.color,
                  scale: scale * 0.9,
                )
              : const SizedBox(height: 0, width: 0),
        ),
      ),
      if (_betDisplays[index] != null)
        Positioned(
          left: centerX + dx + (cos(angle) < 0 ? -60 * scale : 40 * scale),
          top: centerY + dy + bias + 40 * scale,
          child: BetDisplayWidget(
            key: ValueKey(_betDisplays[index]!.id),
            amount: _betDisplays[index]!.amount,
            color: _betDisplays[index]!.color,
            scale: scale * 0.7,
          ),
        ),
      Positioned(
        left: centerX + dx + (cos(angle) < 0 ? -45 * scale : 30 * scale),
        top: centerY + dy + bias + 50 * scale,
        child: MiniStackWidget(
          stack: _stackService.currentStacks[index] ?? 0,
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
              lastAction.amount != null
                  ? '${lastAction.action.toUpperCase()} ${lastAction.amount}'
                  : lastAction.action.toUpperCase(),
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
      Positioned(
        left: centerX + dx + 40 * scale,
        top: centerY + dy + bias - 40 * scale,
        child: PlayerNoteButton(
          note: _playerManager.playerNotes[index],
          scale: scale,
          onPressed: () => _editPlayerNote(index),
        ),
      ),
      if (index == dealerIndex)
        Positioned(
          left: centerX + dx + (cos(angle) < 0 ? -50 * scale : 40 * scale),
          top: centerY + dy + bias - 70 * scale,
          child: _DealerButtonIndicator(scale: scale),
        ),
    ];

    if (invested > 0) {
      if (_potSync.pots[currentStreet] > 0 &&
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
    final tableWidth = screenSize.width * 0.9 * scale;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

    final visibleActions =
        actions.take(_playbackManager.playbackIndex).toList();

    final index = (i + _viewIndex()) % numberOfPlayers;
    final angle = 2 * pi * i / numberOfPlayers + pi / 2;
    final offset = TableGeometryHelper.positionForPlayer(
        i, numberOfPlayers, tableWidth, tableHeight);
    final dx = offset.dx;
    final dy = offset.dy;
    const bias = 0.0;

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
            (lastAction.action == 'bet' ||
                lastAction.action == 'raise' ||
                lastAction.action == 'call'));

    if (!showTrail) return [];

    final fraction = _potSync.pots[currentStreet] > 0
        ? invested / _potSync.pots[currentStreet]
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

class _PlaybackNarrationOverlay extends StatefulWidget {
  final String? text;

  const _PlaybackNarrationOverlay({required this.text});

  @override
  State<_PlaybackNarrationOverlay> createState() => _PlaybackNarrationOverlayState();
}

class _PlaybackNarrationOverlayState extends State<_PlaybackNarrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.text != null && widget.text!.isNotEmpty) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _PlaybackNarrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      if (widget.text != null && widget.text!.isNotEmpty) {
        _controller.forward(from: 0);
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text == null || widget.text!.isEmpty) {
      return const SizedBox.shrink();
    }
    return FadeTransition(
      opacity: _controller,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.text!,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}



class _ActivePlayerHighlight extends StatefulWidget {
  final Offset position;
  final double scale;
  final double bias;

  const _ActivePlayerHighlight({
    required this.position,
    required this.scale,
    required this.bias,
  });

  @override
  State<_ActivePlayerHighlight> createState() => _ActivePlayerHighlightState();
}

class _ActivePlayerHighlightState extends State<_ActivePlayerHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.15)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double avatarRadius = 55 * widget.scale;
    final double highlightRadius = avatarRadius + 6 * widget.scale;
    const Color color = Colors.yellowAccent;
    return Positioned(
      left: widget.position.dx - highlightRadius,
      top: widget.position.dy + widget.bias - highlightRadius,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulse.value,
              child: child,
            );
          },
          child: Container(
            width: highlightRadius * 2,
            height: highlightRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.6),
                width: 4 * widget.scale,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12 * widget.scale,
                  spreadRadius: 4 * widget.scale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DealerButtonIndicator extends StatefulWidget {
  final double scale;

  const _DealerButtonIndicator({Key? key, required this.scale}) : super(key: key);

  @override
  State<_DealerButtonIndicator> createState() => _DealerButtonIndicatorState();
}

class _DealerButtonIndicatorState extends State<_DealerButtonIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 20 * widget.scale,
        height: 20 * widget.scale,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
        ),
        alignment: Alignment.center,
        child: Text(
          'D',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 12 * widget.scale,
          ),
        ),
      ),
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

}


/// Collapsed view of action history with tabs for each street.



class StreetActionInputWidget extends StatefulWidget {
  final int currentStreet;
  final int numberOfPlayers;
  final Map<int, String> playerPositions;
  final ActionHistoryService actionHistory;
  final void Function(ActionEntry) onAdd;
  final void Function(int, ActionEntry) onEdit;
  final void Function(int) onDelete;

  const StreetActionInputWidget({
    super.key,
    required this.currentStreet,
    required this.numberOfPlayers,
    required this.playerPositions,
    required this.actionHistory,
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
    final amount = _needAmount ? double.tryParse(_controller.text) : null;
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
          final bool need = act == 'bet' || act == 'raise' || act == 'call';
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
                      ctx.findAncestorStateOfType<PokerAnalyzerScreenState>()?
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
                      ctx.findAncestorStateOfType<PokerAnalyzerScreenState>()?
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
                          ? double.tryParse(c.text)
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
    final streetActions =
        widget.actionHistory.actionsForStreet(widget.currentStreet);

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
              onChanged: (v) => context.findAncestorStateOfType<PokerAnalyzerScreenState>()?.lockService.safeSetState(this, () => _player = v ?? _player),
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
              onChanged: (v) => context.findAncestorStateOfType<PokerAnalyzerScreenState>()?.lockService.safeSetState(this, () => _action = v ?? _action),
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
                      _editDialog(widget.actionHistory.indexOf(a), a),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      widget.onDelete(widget.actionHistory.indexOf(a)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

