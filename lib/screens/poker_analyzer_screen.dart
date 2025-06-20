import 'dart:math';
import 'dart:async';
import 'dart:convert';
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
import '../models/training_spot.dart';
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
import '../widgets/bet_stack_chips.dart';
import '../widgets/card_selector.dart';
import '../widgets/player_bet_indicator.dart';
import '../widgets/player_stack_chips.dart';
import '../widgets/spr_label.dart';
import '../widgets/total_invested_label.dart';
import '../widgets/chip_stack_widget.dart';
import '../widgets/chip_amount_widget.dart';
import '../widgets/mini_stack_widget.dart';
import '../widgets/bet_stack_indicator.dart';
import '../widgets/bet_display_widget.dart';
import '../widgets/player_stack_value.dart';
import '../widgets/player_note_button.dart';
import '../widgets/bet_size_label.dart';
import '../widgets/turn_countdown_overlay.dart';
import '../helpers/poker_position_helper.dart';
import '../models/saved_hand.dart';
import '../models/player_model.dart';
import '../models/action_evaluation_request.dart';
import '../widgets/action_timeline_widget.dart';
import '../services/pot_sync_service.dart';
import '../widgets/chip_moving_widget.dart';
import '../widgets/chip_stack_moving_widget.dart';
import '../widgets/refund_chip_stack_moving_widget.dart';
import '../widgets/bet_flying_chips.dart';
import '../widgets/bet_to_center_animation.dart';
import '../widgets/bet_slide_chips.dart';
import '../widgets/all_in_chips_animation.dart';
import '../widgets/win_chips_animation.dart';
import '../widgets/chip_reward_animation.dart';
import '../widgets/win_amount_widget.dart';
import '../widgets/win_text_widget.dart';
import '../widgets/pot_chip_animation.dart';
import '../widgets/pot_collection_chips.dart';
import '../widgets/trash_flying_chips.dart';
import '../widgets/fold_flying_cards.dart';
import '../widgets/fold_refund_animation.dart';
import '../widgets/undo_refund_animation.dart';
import '../widgets/refund_amount_widget.dart';
import '../widgets/reveal_card_animation.dart';
import '../widgets/clear_table_cards.dart';
import '../widgets/fold_reveal_animation.dart';
import '../widgets/table_cleanup_overlay.dart';
import '../widgets/deal_card_animation.dart';
import '../widgets/playback_progress_bar.dart';
import '../widgets/street_indicator.dart';
import '../widgets/street_transition_overlay.dart';
import '../services/stack_manager_service.dart';
import '../services/player_manager_service.dart';
import '../services/player_profile_service.dart';
import '../services/player_editing_service.dart';
import '../services/hand_restore_service.dart';
import '../services/action_tag_service.dart';
import '../helpers/date_utils.dart';
import '../widgets/evaluation_request_tile.dart';
import '../helpers/debug_helpers.dart';
import '../helpers/table_geometry_helper.dart';
import '../helpers/action_formatting_helper.dart';
import '../services/backup_manager_service.dart';
import '../services/debug_snapshot_service.dart';
import '../services/action_sync_service.dart';
import '../services/undo_redo_service.dart';
import '../services/action_editing_service.dart';
import '../services/transition_lock_service.dart';
import '../services/transition_history_service.dart';
import '../services/all_in_players_service.dart';
import '../services/current_hand_context_service.dart';
import '../services/folded_players_service.dart';
import '../services/action_history_service.dart';
import '../services/service_registry.dart';
import '../../plugins/plugin_manager.dart';
import '../../plugins/plugin_loader.dart';
import '../../plugins/plugin.dart';



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
  });

  @override
  State<PokerAnalyzerScreen> createState() => _PokerAnalyzerScreenState();
}

class _PokerAnalyzerScreenState extends State<PokerAnalyzerScreen>
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
  List<int> _sidePots = [];
  late TransitionLockService lockService;
  final GlobalKey<_BoardCardsSectionState> _boardKey =
      GlobalKey<_BoardCardsSectionState>();
  late final ScrollController _timelineController;
  bool _animateTimeline = false;
  bool isPerspectiveSwitched = false;
  bool _focusOnHero = false;

  final Map<int, _BetDisplayInfo> _recentBets = {};
  final Map<int, _BetDisplayInfo> _betDisplays = {};
  final Map<int, _BetDisplayInfo> _centerBetStacks = {};
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
  bool _potAnimationPlayed = false;
  bool _winnerRevealPlayed = false;
  bool _pendingPotAnimation = false;
  bool _tableCleanupPlayed = false;
  final Set<int> _bustedPlayers = {};

  int _resetAnimationCount = 0;
  bool _waitingForAutoReset = false;

  // Previous card state used to trigger deal animations.
  List<CardModel> _prevBoardCards = [];
  final List<List<CardModel>> _prevPlayerCards =
      List.generate(10, (_) => <CardModel>[]);

  String? _playbackNarration;



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
    final invested = _stackService.getInvestmentForStreet(playerIndex, currentStreet);
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
    if (overlay == null) return;
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
              amount: entry.amount!,
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
              amount: entry.amount!,
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
        amount: entry.amount!,
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
        entry.generated) return;
    _playFoldRefundAnimation(entry.playerIndex, entry.amount!);
  }

  void _handleBetAction(ActionEntry entry, {int potIndex = 0}) {
    if (!['bet', 'raise', 'call', 'all-in'].contains(entry.action) ||
        entry.amount == null ||
        entry.amount! <= 0 ||
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
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;
    final perp = Offset(-sin(angle), cos(angle));
    final control = Offset(
      midX + perp.dx * 20 * scale,
      midY - (40 + ChipStackMovingWidget.activeCount * 8) * scale,
    );
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (_) => PotChipAnimation(
        start: start,
        end: end,
        control: control,
        amount: entry.amount!,
        scale: scale,
        onCompleted: () {
          overlayEntry.remove();
          _animatePotGrowth();
        },
      ),
    );
    overlay.insert(overlayEntry);
  }


  void _playShowdownReveal() {
    final active = [
      for (int i = 0; i < numberOfPlayers; i++)
        if (!_foldedPlayers.isPlayerFolded(i)) i
    ];
    if (active.length < 2) return;

    final winners = <int>{
      if (_winnings != null && _winnings!.isNotEmpty) ..._winnings!.keys,
      if ((_winnings == null || _winnings!.isEmpty) && _winnerIndex != null)
        _winnerIndex!,
    };

    final revealPlayers = [
      for (final p in active)
        if (winners.contains(p) ||
            players[p].revealedCards.whereType<CardModel>().isNotEmpty)
          p
    ];

    _showdownPlayers
      ..clear()
      ..addAll(revealPlayers);
    _showdownActive = true;
    _winnerRevealPlayed = false;
    lockService.safeSetState(this, () {});

    for (int j = 0; j < revealPlayers.length; j++) {
      final player = revealPlayers[j];
      Future.delayed(Duration(milliseconds: 300 * j), () {
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
    final totalDelay = 300 * revealPlayers.length + 400;
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
    _cleanupWinnerCards();
    _showdownPlayers.clear();
    _showdownActive = false;
    _potAnimationPlayed = false;
    _winnerRevealPlayed = false;
    _pendingPotAnimation = false;
    _centerBetStacks.clear();
    lockService.safeSetState(this, () {});
  }

  void _clearBetDisplays() {
    if (_betDisplays.isEmpty &&
        _centerBetStacks.isEmpty &&
        _actionBetStacks.isEmpty &&
        _betSlideOverlays.isEmpty) return;
    setState(() {
      _betDisplays.clear();
      _centerBetStacks.clear();
      _actionBetStacks.clear();
      _betSlideOverlays.forEach((_, entry) => entry.remove());
      _betSlideOverlays.clear();
    });
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
    if (overlay == null) return;
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

  Future<void> _autoResetAfterShowdown() async {
    if (_tableCleanupPlayed) return;
    _tableCleanupPlayed = true;
    await _clearTableState();
    if (!mounted) return;
    _resetHandState();
    lockService.unlock();
  }

  void _resetHandState() {
    lockService.safeSetState(this, () {
      _clearShowdown();
      _boardManager.clearBoard();
      _playerManager.reset();
      _actionSync.clearAnalyzerActions();
      _actionHistory.clear();
      _winnings = null;
      _winnerIndex = null;
      _returns = null;
      for (int i = 0; i < _displayedPots.length; i++) {
      _displayedPots[i] = 0;
      }
      _sidePots.clear();
      _playbackNarration = null;
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


  void _playReturnChipAnimation(ActionEntry entry) {
    if (!['bet', 'raise', 'call', 'all-in'].contains(entry.action) ||
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
        amount: entry.amount!,
        color: color,
        scale: scale,
        onCompleted: () => overlayEntry.remove(),
      ),
    );
    overlay.insert(overlayEntry);
  }

  void _playFoldRefundAnimation(int playerIndex, int amount) {
    if (amount <= 0) return;
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
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (_) => FoldRefundAnimation(
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
          _onResetAnimationComplete();
        },
      ),
    );
    _registerResetAnimation();
    overlay.insert(overlayEntry);
  }

  void _playUndoRefundAnimations(Map<int, int> refunds) {
    if (refunds.isEmpty) return;
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

  void _playShowCardsAnimation(int playerIndex, {List<CardModel>? cards}) {
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

    final totalDelay = 300 * winners.length + 400;
    Future.delayed(Duration(milliseconds: totalDelay), () {
      if (!mounted) return;
      _playPotCollectionAnimation(winners);
      if (_boardReveal.revealedBoardCards.length < 5) {
        _pendingPotAnimation = true;
      }
    });
  }

  void _playPotCollectionAnimation(Set<int> winners) {
    final overlay = Overlay.of(context);
    if (overlay == null || winners.isEmpty) return;

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

    final wins = _winnings;
    int delay = 0;
    for (final playerIndex in winners) {
      final amount = wins != null && wins.isNotEmpty
          ? wins[playerIndex] ?? 0
          : (_winnerIndex == playerIndex ? _potSync.pots[currentStreet] : 0);
      if (amount <= 0) continue;
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
      Future.delayed(Duration(milliseconds: 150 * delay), () {
        if (!mounted) return;
        late OverlayEntry entry;
        entry = OverlayEntry(
          builder: (_) => PotCollectionChips(
            start: start,
            end: end,
            control: control,
            amount: amount,
            scale: scale,
            onCompleted: () => entry.remove(),
          ),
        );
        overlay.insert(entry);

        // Show chips arriving at the winner after the pot leaves center.
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          late OverlayEntry winEntry;
          winEntry = OverlayEntry(
            builder: (_) => WinChipsAnimation(
              start: start,
              end: end,
              control: control,
              amount: amount,
              scale: scale,
              onCompleted: () {
                winEntry.remove();
                final startStack = _displayedStacks[playerIndex] ??
                    _stackService.getStackForPlayer(playerIndex);
                final endStack = startStack + amount;
                _animateStackIncrease(playerIndex, startStack, endStack);
              },
            ),
          );
          overlay.insert(winEntry);
        });
      });
      delay++;
    }

    final cleanupDelay = 150 * (delay == 0 ? 0 : delay - 1) + 900;
    Future.delayed(Duration(milliseconds: cleanupDelay), () {
      if (!mounted) return;
      _autoResetAfterShowdown();
    });
  }

  void _cleanupWinnerCards() {
    final overlay = Overlay.of(context);
    if (overlay == null) return;
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
    if (overlay == null) return;
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
    Color color = Colors.orangeAccent,
    double scale = 1.0,
    double fadeStart = 0.3,
  }) {
    if (targets.isEmpty) return;
    final overlay = Overlay.of(context);
    if (overlay == null) return;
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
          onCompleted: () => overlayEntry.remove(),
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
              showWinTextOverlay(
                context: context,
                position: labelPos,
                text: '$playerName wins the pot',
                scale: scale * tableScale,
              );
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


  void _playPotWinAnimation() {
    if (_potAnimationPlayed) return;
    final wins = _winnings;
    final returns = _returns;
    final overlay = Overlay.of(context);
    if (overlay != null) {
      int delay = 0;
      if (wins != null && wins.isNotEmpty) {
        _showPotWinAnimations(
          overlay,
          wins,
          delay,
          Colors.orangeAccent,
          highlight: true,
          fadeStart: 0.6,
        );
        delay += 150 * wins.length;
      } else if (_winnerIndex != null) {
        _showPotWinAnimations(
          overlay,
          {_winnerIndex!: _potSync.pots[currentStreet]},
          delay,
          Colors.orangeAccent,
          highlight: true,
          fadeStart: 0.6,
        );
        delay += 150;
      }
      if (returns != null && returns.isNotEmpty) {
        returns.forEach((player, amount) {
          Future.delayed(Duration(milliseconds: delay), () {
            if (!mounted) return;
            _playFoldRefundAnimation(player, amount);
          });
          delay += 150;
        });
      }
    }
    _potAnimationPlayed = true;

    // Fade out the central pot after the chips move away.
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

  /// Plays the pot win animation once showdown reveals have finished.
  void _showPotWinAnimation() {
    if (_potAnimationPlayed) return;
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    int delay = 0;
    final wins = _winnings;
    if (wins != null && wins.isNotEmpty) {
      _showPotWinAnimations(
        overlay,
        wins,
        delay,
        Colors.orangeAccent,
        highlight: true,
        fadeStart: 0.6,
      );
      delay += 150 * wins.length;
    } else if (_winnerIndex != null) {
      _showPotWinAnimations(
        overlay,
        {_winnerIndex!: _potSync.pots[currentStreet]},
        delay,
        Colors.orangeAccent,
        highlight: true,
        fadeStart: 0.6,
      );
      delay += 150;
    } else {
      return;
    }

    final returns = _returns;
    if (returns != null && returns.isNotEmpty) {
      returns.forEach((player, amount) {
        Future.delayed(Duration(milliseconds: delay), () {
          if (!mounted) return;
          _playFoldRefundAnimation(player, amount);
        });
        delay += 150;
      });
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

  void _playShowdownRewardAnimation() {
    if (_potAnimationPlayed) return;
    final overlay = Overlay.of(context);
    if (overlay == null) return;

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
        final info = _BetDisplayInfo(entry.amount!, color);
        _recentBets[index] = info;
        _betDisplays[index] = info;
        _centerBetStacks[index] = info;
        _actionBetStacks[index] = entry.amount!;
      });
      final overlay = Overlay.of(context);
      if (overlay != null) {
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
          builder: (_) => BetToCenterAnimation(
            start: start,
            end: end,
            control: control,
            amount: entry.amount!,
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
            amount: entry.amount!,
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
      }
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

  void _computeSidePots() {
    _potSync.updateSidePots();
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
    _computeSidePots();
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
    _undoRedoService.recordSnapshot();
    _actionTagService.clear();
    _boardManager.reverseStreet();
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
    _undoRedoService.recordSnapshot();
    _actionTagService.clear();
    _boardManager.advanceStreet();
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

  void _playAll() {
    if (lockService.isLocked) return;
    _playbackManager.seek(0);
    _playbackManager.updatePlaybackState();
    _playbackManager.startPlayback(
      stepDelay: const Duration(milliseconds: 1500),
      canAdvance: () => !lockService.isLocked && _resetAnimationCount == 0,
    );
  }

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
    _serviceRegistry = ServiceRegistry();
    final PluginManager pluginManager = PluginManager();
    final PluginLoader loader = PluginLoader();
    for (final Plugin plugin in loader.loadBuiltInPlugins()) {
      pluginManager.load(plugin);
    }
    pluginManager.initializeAll(_serviceRegistry);

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
            debugSnapshotService: _debugSnapshotService,
          ));
    _processingService = _serviceRegistry.get<EvaluationProcessingService>();
    _serviceRegistry.register<TransitionLockService>(widget.lockService);
    lockService = _serviceRegistry.get<TransitionLockService>();
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
    ));
    _actionEditing = _serviceRegistry.get<ActionEditingService>();
    Future(() => _initializeDebugPreferences());
    Future.microtask(_queueService.loadQueueSnapshot);
    _computeSidePots();
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
            SavedHandImportExportService(_handManager);
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
      lockService.safeSetState(this, () => activePlayerIndex = null);
    }
  }

  void _clearActiveHighlight() {
    if (activePlayerIndex != null) {
      lockService.safeSetState(this, () => activePlayerIndex = null);
    }
  }

  Future<void> _onOpponentCardTap(int cardIndex) async {
    if (lockService.isLocked) return;
    if (opponentIndex == null) opponentIndex = activePlayerIndex;
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
    if (lockService.isLocked) return;
    lockService.safeSetState(this, () => activePlayerIndex = index);
    final result = await _showActionPicker();
    if (result == null) return;
    String action = result['action'] as String;
    int? amount = result['amount'] as int?;
    if (action == 'all-in') {
      amount = _stackService.getStackForPlayer(index);
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

  void _onPlaybackManagerChanged() {
    if (mounted) {
      _clearBetDisplays();
      final prevSides = List<int>.from(_sidePots);
      _computeSidePots();
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
        activePlayerIndex = _playbackManager.lastActionPlayerIndex;
      });
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
      _prevPlaybackIndex = _playbackManager.playbackIndex;
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
  }

  void _playDealAnimations() {
    final overlay = Overlay.of(context);
    if (overlay == null) return;
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
    if (overlay == null) return;
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

  void _playFlopRevealAnimation() {
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    if (boardCards.length < 3) return;
    final double scale = TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 -
            TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final center = Offset(centerX, centerY);
    final baseY = centerY - 52 * scale;

    int delay = 0;
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
      delay += 120;
    }
  }

  void _playTurnRevealAnimation() {
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    if (boardCards.length < 4) return;
    final double scale = TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 -
            TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final center = Offset(centerX, centerY);
    final baseY = centerY - 52 * scale;

    final visible = BoardSyncService.stageCardCounts[2];
    final x = centerX + (3 - (visible - 1) / 2) * 44 * scale;
    late OverlayEntry e;
    e = OverlayEntry(
      builder: (_) => DealCardAnimation(
        start: center,
        end: Offset(x, baseY),
        card: boardCards[3],
        scale: scale,
        onCompleted: () => e.remove(),
      ),
    );
    overlay.insert(e);
  }

  void _playRiverRevealAnimation() {
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    if (boardCards.length < 5) return;
    final double scale = TableGeometryHelper.tableScale(numberOfPlayers);
    final screen = MediaQuery.of(context).size;
    final centerX = screen.width / 2 + 10;
    final centerY =
        screen.height / 2 -
            TableGeometryHelper.centerYOffset(numberOfPlayers, scale);
    final center = Offset(centerX, centerY);
    final baseY = centerY - 52 * scale;

    final visible = BoardSyncService.stageCardCounts[3];
    final x = centerX + (4 - (visible - 1) / 2) * 44 * scale;
    late OverlayEntry e;
    e = OverlayEntry(
      builder: (_) => DealCardAnimation(
        start: center,
        end: Offset(x, baseY),
        card: boardCards[4],
        scale: scale,
        onCompleted: () => e.remove(),
      ),
    );
    overlay.insert(e);
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
      delay += 400;
    }
    if (boardCards.length >= 4) {
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) _playTurnRevealAnimation();
      });
      delay += 400;
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
        final cards = boardCards.take(3).map(_cardToDebugString).join(' ');
        _playbackNarration = 'Flop revealed: $cards';
      }
    } else if (currentStreet == 2) {
      _playTurnRevealAnimation();
      if (boardCards.length >= 4) {
        _playbackNarration =
            'Turn revealed: ${_cardToDebugString(boardCards[3])}';
      }
    } else if (currentStreet == 3) {
      _playRiverRevealAnimation();
      if (boardCards.length >= 5) {
        _playbackNarration =
            'River revealed: ${_cardToDebugString(boardCards[4])}';
      }
    }
  }

  void _playStreetTransition(int street) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;
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
      _computeSidePots();
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
          _playFoldRefundAnimation(entry.playerIndex, refund);
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
        _clearActiveHighlight();
      });
    } else {
      perform();
      _clearActiveHighlight();
    }
  }

  void _reorderAction(int oldIndex, int newIndex) {
    if (lockService.isLocked) return;
    lockService.safeSetState(this, () {
      _actionEditing.reorderAction(oldIndex, newIndex);
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
      _undoRedoService.recordSnapshot();
      _actionTagService.clear();
      _boardManager.reverseStreet();
    });
    _debugPanelSetState?.call(() {});
  }

  void _nextStreet() {
    if (lockService.isLocked || !_boardManager.canAdvanceStreet()) return;
    lockService.safeSetState(this, () {
      _undoRedoService.recordSnapshot();
      _actionTagService.clear();
      _boardManager.advanceStreet();
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

  String _defaultHandName() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    return 'Раздача от $day.$month.$year';
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


  SavedHand _currentSavedHand({
    String? name,
    String? tournamentId,
    int? buyIn,
    int? totalPrizePool,
    int? numberOfEntrants,
    String? gameType,
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
      activePlayerIndex: activePlayerIndex,
    );
  }

  String saveHand() {
    _addQualityTags();
    final hand = _currentSavedHand();
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
    final hand = _currentSavedHand(name: handName);
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
    _centerChipTimer?.cancel();
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
              onChanged: lockService.isLocked ? null : _onPlayerCountChanged,
              disabled: lockService.isLocked,
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
                    absorbing: lockService.isLocked,
                    child: _BoardCardsSection(
                      key: _boardKey,
                      scale: scale,
                      currentStreet: currentStreet,
                      boardCards: boardCards,
                      revealedBoardCards: _boardReveal.revealedBoardCards,
                      onCardSelected: selectBoardCard,
                      onCardLongPress: _removeBoardCard,
                      canEditBoard: (i) => _boardEditing.canEditBoard(context, i),
                      usedCards: _boardEditing.usedCardKeys(),
                      editingDisabled: lockService.isLocked,
                      potSync: _potSync,
                      boardReveal: widget.boardReveal,
                      showPot: !_showdownActive,
                    ),
                  ),
                  _PlayerZonesSection(
                    numberOfPlayers: numberOfPlayers,
                    scale: scale,
                    playerPositions: playerPositions,
                    opponentCardRow: AbsorbPointer(
                      absorbing: lockService.isLocked,
                      child: _OpponentCardRowSection(
                        scale: scale,
                        players: players,
                        activePlayerIndex: activePlayerIndex,
                        opponentIndex: opponentIndex,
                        onCardTap:
                            lockService.isLocked ? null : _onOpponentCardTap,
                      ),
                    ),
                    playerBuilder: _buildPlayerWidgets,
                    chipTrailBuilder: _buildChipTrail,
                  ),
                  _BetStacksOverlaySection(
                    scale: scale,
                    state: this,
                  ),
                  _ActionBetStackOverlaySection(
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
                    pots: _potSync.pots,
                    sidePots: _sidePots,
                    playbackManager: _playbackManager,
                    centerChipAction: _centerChipAction,
                    showCenterChip: _showCenterChip,
                    centerChipOrigin: _centerChipOrigin,
                    centerChipController: _centerChipController,
                    potGrowth: _potGrowthAnimation,
                    potCount: _potCountAnimation,
                    centerBets: _centerBetStacks,
                    actionColor: ActionFormattingHelper.actionColor,
                  ),
                  _ActionHistorySection(
                    actionHistory: _actionHistory,
                    playerPositions: playerPositions,
                    expandedStreets: _expandedHistoryStreets,
                    onToggleStreet: (index) {
                      lockService.safeSetState(this, () {
                        _actionHistory.toggleStreet(index);
                      });
                    },
                  ),
                  _PerspectiveSwitchButton(
                    isPerspectiveSwitched: isPerspectiveSwitched,
                    onToggle: () => lockService.safeSetState(this,
                        () => isPerspectiveSwitched = !isPerspectiveSwitched),
                  ),
                  _PlaybackNarrationOverlay(text: _playbackNarration),
                  StreetIndicator(street: currentStreet),
                  _HudOverlaySection(
                    streetName:
                        ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'][currentStreet],
                    potText: ActionFormattingHelper
                        .formatAmount(_potSync.pots[currentStreet]),
                    stackText:
                        ActionFormattingHelper.formatAmount(effectiveStack),
                    sprText: sprValue != null
                        ? 'SPR: ${sprValue.toStringAsFixed(1)}'
                        : null,
                  ),
                  if (lockService.isLocked)
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
    _TotalPotTracker(
      potSync: _potSync,
      currentStreet: currentStreet,
      sidePots: _sidePots,
    ),
    AbsorbPointer(
      absorbing: lockService.isLocked,
      child: PlaybackProgressBar(
        playbackIndex: _playbackManager.playbackIndex,
        actionCount: actions.length,
        onSeek: (index) {
          lockService.safeSetState(this, () {
            _playbackManager.seek(index);
            _playbackManager.updatePlaybackState();
          });
        },
      ),
    ),
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: AbsorbPointer(
        absorbing: lockService.isLocked,
        child: Column(
          children: [
            ...List.generate(
              4,
              (i) => CollapsibleStreetSection(
                street: i,
                actions: savedActions,
                pots: _potSync.pots,
                stackSizes: _stackService.currentStacks,
                playerPositions: playerPositions,
                onEdit: _editAction,
                onDelete: _deleteAction,
                onInsert: _insertAction,
                onDuplicate: _duplicateAction,
                onReorder: _reorderAction,
                visibleCount: _playbackManager.playbackIndex,
                evaluateActionQuality: _evaluateActionQuality,
              ),
            ),
          ],
        ),
      ),
    ),
    AbsorbPointer(
      absorbing: lockService.isLocked,
      child: ActionHistoryExpansionTile(
        actions: visibleActions,
        playerPositions: playerPositions,
        pots: _potSync.pots,
        stackSizes: _stackService.currentStacks,
        onEdit: _editAction,
        onDelete: _deleteAction,
        onInsert: _insertAction,
        onDuplicate: _duplicateAction,
        onReorder: _reorderAction,
        visibleCount: _playbackManager.playbackIndex,
        evaluateActionQuality: _evaluateActionQuality,
      ),
    StreetActionsWidget(
      currentStreet: currentStreet,
      canGoPrev: _boardManager.canReverseStreet(),
      onPrevStreet:
          lockService.isLocked ? null : () => lockService.safeSetState(this, _reverseStreet),
      onStreetChanged: (index) {
        if (lockService.isLocked) return;
        lockService.safeSetState(this, () {
          _undoRedoService.recordSnapshot();
          _changeStreet(index);
        });
      },
            ),
            AbsorbPointer(
              absorbing: lockService.isLocked,
              child: StreetActionInputWidget(
                currentStreet: currentStreet,
                numberOfPlayers: numberOfPlayers,
                playerPositions: playerPositions,
                actionHistory: _actionHistory,
                onAdd: handlePlayerAction,
                onEdit: _editAction,
                onDelete: _deleteAction,
              ),
            ),
            AbsorbPointer(
              absorbing: lockService.isLocked,
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
                focusPlayerIndex: _focusOnHero ? heroIndex : null,
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
                elapsedTime: _playbackManager.elapsedTime,
                onPlay: _play,
                onPause: _pause,
                onPlayAll: _playAll,
                onStepBackward: _stepBackwardPlayback,
                onStepForward: _stepForwardPlayback,
                onPlaybackReset: _resetPlayback,
                onSeek: _seekPlayback,
                onSave: () => saveCurrentHand(),
                onLoadLast: loadLastSavedHand,
                onLoadByName: () => loadHandByName(),
                onExportLast: exportLastSavedHand,
                onExportAll: exportAllHands,
                onImport: importHandFromClipboard,
                onImportAll: importAllHandsFromClipboard,
                onReset: _resetHand,
                onBack: _cancelHandAnalysis,
                focusOnHero: _focusOnHero,
                onFocusChanged: (v) => setState(() => _focusOnHero = v),
                backDisabled: _showdownActive,
                disabled: _transitionHistory.isLocked,
              ),
            ),
            Expanded(
              child: AbsorbPointer(
                absorbing: lockService.isLocked,
                child: _HandEditorSection(
                  actionHistory: _actionHistory,
                  playerPositions: playerPositions,
                  heroIndex: heroIndex,
                  commentController: _handContext.commentController,
                  tagsController: _handContext.tagsController,
                  tournamentIdController: _handContext.tournamentIdController,
                  buyInController: _handContext.buyInController,
                  prizePoolController: _handContext.totalPrizePoolController,
                  entrantsController: _handContext.numberOfEntrantsController,
                  gameTypeController: _handContext.gameTypeController,
                  currentStreet: currentStreet,
                  pots: _potSync.pots,
                  stackSizes: _stackService.currentStacks,
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
              loadTrainingSpot(
                  TrainingSpot.fromJson(Map<String, dynamic>.from(data)));
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
      if (isActive)
        _ActivePlayerHighlight(
          position: Offset(centerX + dx, centerY + dy),
          scale: scale * infoScale,
          bias: bias,
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
            amount: lastAmountAction!.amount!.toDouble(),
            color: ActionFormattingHelper.actionColor(
                lastAmountAction!.action),
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
                '$stack BB',
                key: ValueKey(stack),
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
              : SizedBox(height: 0, width: 0),
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
      Positioned(
        left: centerX + dx + 40 * scale,
        top: centerY + dy + bias - 40 * scale,
        child: PlayerNoteButton(
          note: _playerManager.playerNotes[index],
          scale: scale,
          onPressed: () => _editPlayerNote(index),
        ),
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

class _PlaybackNarrationOverlay extends StatelessWidget {
  final String? text;

  const _PlaybackNarrationOverlay({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text == null || text!.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text!,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _BetDisplayInfo {
  final int amount;
  final Color color;
  final String id;

  _BetDisplayInfo(this.amount, this.color) : id = const Uuid().v4();
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
    final Color color = Theme.of(context).colorScheme.primary;
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
  final List<int> sidePots;
  final PlaybackManagerService playbackManager;
  final ActionEntry? centerChipAction;
  final bool showCenterChip;
  final Offset? centerChipOrigin;
  final Animation<double> centerChipController;
  final Animation<double> potGrowth;
  final Animation<int> potCount;
  final Color Function(String) actionColor;
  final Map<int, _BetDisplayInfo> centerBets;

  const _PotAndBetsOverlaySection({
    required this.scale,
    required this.numberOfPlayers,
    required this.currentStreet,
    required this.viewIndex,
    required this.actions,
    required this.pots,
    required this.sidePots,
    required this.playbackManager,
    required this.centerChipAction,
    required this.showCenterChip,
    required this.centerChipOrigin,
    required this.centerChipController,
    required this.potGrowth,
    required this.potCount,
    required this.centerBets,
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
                child: ScaleTransition(
                  scale: potGrowth,
                  child: AnimatedBuilder(
                    animation: potCount,
                    builder: (_, __) => BetStackChips(
                      amount: potCount.value,
                      scale: scale,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (int i = 0; i < sidePots.length; i++) {
      final offsetY = 36 * scale * (i + 1);
      final amount = sidePots[i];
      items.add(
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(0, offsetY),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: BetStackChips(
                    key: ValueKey('side-$i-$amount'),
                    amount: amount,
                    scale: scale,
                  ),
                ),
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
            child: AnimatedOpacity(
              opacity: showCenterChip ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: AnimatedBuilder(
                animation: centerChipController,
                builder: (_, child) {
                  final start = centerChipOrigin ?? Offset(centerX, centerY);
                  final pos = Offset.lerp(start, Offset(centerX, centerY),
                      centerChipController.value)!;
                  return Transform.translate(
                    offset: Offset(pos.dx - centerX, pos.dy - centerY),
                    child: Transform.scale(
                      scale: centerChipController.value,
                      child: Align(
                        alignment: Alignment.center,
                        child: child,
                      ),
                    ),
                  );
                },
                child: ChipAmountWidget(
                  amount: centerChipAction!.amount!.toDouble(),
                  color: actionColor(centerChipAction!.action),
                  scale: scale,
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
      if (['bet', 'raise', 'call', 'all-in'].contains(lastAction.action) &&
          lastAction.amount != null) {
        final angle = 2 * pi * i / numberOfPlayers + pi / 2;
        final dx = radiusX * cos(angle);
        final dy = radiusY * sin(angle);
        final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
        final start = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
        final end = Offset(centerX, centerY);
        final animate =
            playbackManager.shouldAnimatePlayer(currentStreet, index);
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

    centerBets.forEach((player, info) {
      final i = (player - viewIndex + numberOfPlayers) % numberOfPlayers;
      final angle = 2 * pi * i / numberOfPlayers + pi / 2;
      final dx = radiusX * cos(angle);
      final dy = radiusY * sin(angle);
      final bias = TableGeometryHelper.verticalBiasFromAngle(angle) * scale;
      final start = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
      final end = Offset(centerX, centerY);
      final pos = Offset.lerp(start, end, 0.75)!;
      final chipScale = scale * 0.8;
      items.add(Positioned(
        left: pos.dx - 8 * chipScale,
        top: pos.dy - 8 * chipScale,
        child: BetStackIndicator(
          amount: info.amount,
          color: info.color,
          scale: chipScale,
          duration: const Duration(milliseconds: 1700),
          onComplete: () {},
        ),
      ));
    });

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

class _ActionBetStackOverlaySection extends StatelessWidget {
  final double scale;
  final _PokerAnalyzerScreenState state;

  const _ActionBetStackOverlaySection({
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

    final chips = <Widget>[];
    for (int i = 0; i < state.numberOfPlayers; i++) {
      final index = (i + state._viewIndex()) % state.numberOfPlayers;
      final amount = state._actionBetStacks[index];
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: amount != null
              ? BetStackChips(
                  key: ValueKey(amount),
                  amount: amount,
                  scale: chipScale,
                )
              : SizedBox(key: const ValueKey('empty'), height: 16 * chipScale),
        ),
      ));
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
        final animate =
            state._playbackManager.shouldAnimatePlayer(state.currentStreet, index);
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
  final ActionHistoryService actionHistory;
  final Map<int, String> playerPositions;
  final Set<int> expandedStreets;
  final ValueChanged<int> onToggleStreet;

  const _ActionHistorySection({
    required this.actionHistory,
    required this.playerPositions,
    required this.expandedStreets,
    required this.onToggleStreet,
  });

  @override
  Widget build(BuildContext context) {
    return ActionHistoryOverlay(
      actionHistory: actionHistory,
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
  final PotSyncService potSync;
  final void Function(int, CardModel) onCardSelected;
  final void Function(int) onCardLongPress;
  final bool Function(int index)? canEditBoard;
  final Set<String> usedCards;
  final bool editingDisabled;
  final BoardRevealService boardReveal;
  final bool showPot;

  const _BoardCardsSection({
    Key? key,
    required this.scale,
    required this.currentStreet,
    required this.boardCards,
    required this.revealedBoardCards,
    required this.onCardSelected,
    required this.onCardLongPress,
    required this.potSync,
    required this.boardReveal,
    this.canEditBoard,
    this.usedCards = const {},
    this.editingDisabled = false,
    this.showPot = true,
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
        potSync: widget.potSync,
        showPot: widget.showPot,
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
  final Duration elapsedTime;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onPlayAll;
  final VoidCallback onStepBackward;
  final VoidCallback onStepForward;
  final VoidCallback onPlaybackReset;
  final ValueChanged<double> onSeek;
  final VoidCallback onReset;
  final VoidCallback onBack;
  final bool focusOnHero;
  final ValueChanged<bool> onFocusChanged;
  final bool backDisabled;
  final bool disabled;

  const _PlaybackControlsSection({
    required this.isPlaying,
    required this.playbackIndex,
    required this.actionCount,
    required this.elapsedTime,
    required this.onPlay,
    required this.onPause,
    required this.onPlayAll,
    required this.onStepBackward,
    required this.onStepForward,
    required this.onPlaybackReset,
    required this.onSeek,
    required this.onReset,
    required this.onBack,
    required this.focusOnHero,
    required this.onFocusChanged,
    this.backDisabled = false,
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
              icon: Icon(Icons.replay, color: iconColor),
              onPressed: disabled ? null : onPlaybackReset,
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
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: actionCount > 0 ? playbackIndex / actionCount : 0.0,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.secondary),
              ),
              const SizedBox(height: 4),
              Text(
                "Step \$playbackIndex / \$actionCount" +
                    (isPlaying ? " - " + _formatDuration(elapsedTime) : ""),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: disabled ? null : (isPlaying ? onPause : onPlayAll),
              child: Text(isPlaying ? "Pause" : "Play All"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: disabled ? null : onStepBackward,
              child: const Text('Step Back'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: disabled ? null : onStepForward,
              child: const Text('Step Forward'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: backDisabled ? null : onBack,
          child: const Text('Назад'),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onReset,
          child: const Text('Сбросить раздачу'),
        ),
        SwitchListTile(
          title: const Text('Focus on Hero', style: TextStyle(color: Colors.white)),
          value: focusOnHero,
          onChanged: disabled ? null : onFocusChanged,
          activeColor: Colors.deepPurple,
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
  final Duration elapsedTime;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onPlayAll;
  final VoidCallback onStepBackward;
  final VoidCallback onStepForward;
  final VoidCallback onPlaybackReset;
  final ValueChanged<double> onSeek;
  final VoidCallback onSave;
  final VoidCallback onLoadLast;
  final VoidCallback onLoadByName;
  final VoidCallback onExportLast;
  final VoidCallback onExportAll;
  final VoidCallback onImport;
  final VoidCallback onImportAll;
  final VoidCallback onReset;
  final VoidCallback onBack;
  final bool focusOnHero;
  final ValueChanged<bool> onFocusChanged;
  final bool backDisabled;
  final bool disabled;

  const _PlaybackAndHandControls({
    required this.isPlaying,
    required this.playbackIndex,
    required this.actionCount,
    required this.elapsedTime,
    required this.onPlay,
    required this.onPause,
    required this.onPlayAll,
    required this.onStepBackward,
    required this.onStepForward,
    required this.onPlaybackReset,
    required this.onSeek,
    required this.onSave,
    required this.onLoadLast,
    required this.onLoadByName,
    required this.onExportLast,
    required this.onExportAll,
    required this.onImport,
    required this.onImportAll,
    required this.onReset,
    required this.onBack,
    required this.focusOnHero,
    required this.onFocusChanged,
    this.backDisabled = false,
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
          elapsedTime: elapsedTime,
          onPlay: onPlay,
          onPause: onPause,
          onPlayAll: onPlayAll,
          onStepBackward: onStepBackward,
          onStepForward: onStepForward,
          onPlaybackReset: onPlaybackReset,
          onSeek: onSeek,
          onReset: onReset,
          onBack: onBack,
          focusOnHero: focusOnHero,
          onFocusChanged: onFocusChanged,
          backDisabled: backDisabled,
          disabled: disabled,
        ),
      ],
    );
  }
}

/// Collapsed view of action history with tabs for each street.
class _CollapsibleActionHistorySection extends StatelessWidget {
  final ActionHistoryService actionHistory;
  final Map<int, String> playerPositions;
  final int heroIndex;

  const _CollapsibleActionHistorySection({
    required this.actionHistory,
    required this.playerPositions,
    required this.heroIndex,
  });

  @override
  Widget build(BuildContext context) {
    return CollapsibleActionHistory(
      actionHistory: actionHistory,
      playerPositions: playerPositions,
      heroIndex: heroIndex,
    );
  }
}

class _HandNotesSection extends StatelessWidget {
  final TextEditingController commentController;
  final TextEditingController tagsController;
  final TextEditingController tournamentIdController;
  final TextEditingController buyInController;
  final TextEditingController prizePoolController;
  final TextEditingController entrantsController;
  final TextEditingController gameTypeController;

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

class _TournamentInfoSection extends StatefulWidget {
  final TextEditingController idController;
  final TextEditingController buyInController;
  final TextEditingController prizePoolController;
  final TextEditingController entrantsController;
  final TextEditingController gameTypeController;

  const _TournamentInfoSection({
    required this.idController,
    required this.buyInController,
    required this.prizePoolController,
    required this.entrantsController,
    required this.gameTypeController,
  });

  @override
  State<_TournamentInfoSection> createState() => _TournamentInfoSectionState();
}

class _TournamentInfoSectionState extends State<_TournamentInfoSection> {
  bool _open = false;

  bool get _allEmpty =>
      widget.idController.text.isEmpty &&
      widget.buyInController.text.isEmpty &&
      widget.prizePoolController.text.isEmpty &&
      widget.entrantsController.text.isEmpty &&
      widget.gameTypeController.text.isEmpty;

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text('$label: $value',
          style: const TextStyle(color: Colors.white70)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = <Widget>[];
    if (widget.idController.text.isNotEmpty) {
      summary.add(_summaryRow('ID', widget.idController.text));
    }
    if (widget.buyInController.text.isNotEmpty) {
      summary.add(_summaryRow('Buy-In', widget.buyInController.text));
    }
    if (widget.prizePoolController.text.isNotEmpty) {
      summary.add(_summaryRow('Prize Pool', widget.prizePoolController.text));
    }
    if (widget.entrantsController.text.isNotEmpty) {
      summary.add(_summaryRow('Entrants', widget.entrantsController.text));
    }
    if (widget.gameTypeController.text.isNotEmpty) {
      summary.add(_summaryRow('Game', widget.gameTypeController.text));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Tournament Info',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child:
                        const Icon(Icons.expand_more, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          if (!_open && summary.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: summary,
              ),
            ),
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              duration: const Duration(milliseconds: 300),
              heightFactor: _open ? 1 : 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8.0, vertical: 4.0),
                child: Column(
                  children: [
                    TextField(
                      controller: widget.idController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Tournament ID',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: widget.buyInController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Buy-In',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: widget.prizePoolController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Prize Pool',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: widget.entrantsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Entrants',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: widget.gameTypeController.text.isEmpty
                          ? null
                          : widget.gameTypeController.text,
                      decoration: const InputDecoration(
                        labelText: 'Game Type',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      dropdownColor: Colors.grey[900],
                      items: const [
                        DropdownMenuItem(
                            value: "Hold'em NL", child: Text("Hold'em NL")),
                        DropdownMenuItem(value: 'Omaha PL', child: Text('Omaha PL')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) =>
                          setState(() => widget.gameTypeController.text = v ?? ''),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreetActionsSection extends StatelessWidget {
  final int street;
  final ActionHistoryService actionHistory;
  final List<int> pots;
  final Map<int, int> stackSizes;
  final Map<int, String> playerPositions;
  final PotSyncService potSync;
  final List<ActionEntry> allActions;
  final void Function(int, ActionEntry) onEdit;
  final void Function(int) onDelete;
  final void Function(int index, ActionEntry entry) onInsert;
  final void Function(int) onDuplicate;
  final void Function(int, int) onReorder;
  final int? visibleCount;
  final String Function(ActionEntry)? evaluateActionQuality;

  const _StreetActionsSection({
    required this.street,
    required this.actionHistory,
    required this.pots,
    required this.stackSizes,
    required this.playerPositions,
    required this.potSync,
    required this.allActions,
    required this.onEdit,
    required this.onDelete,
    required this.onInsert,
    required this.onDuplicate,
    required this.onReorder,
    this.visibleCount,
    this.evaluateActionQuality,
  });

  @override
  Widget build(BuildContext context) {
    final pot = pots[street];
    final effStack = potSync.calculateEffectiveStackForStreet(
        street, allActions, playerPositions.length);
    final double? sprValue = pot > 0 ? effStack / pot : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: StreetActionsList(
        street: street,
        actions: actionHistory.actionsForStreet(street,
            collapsed: false),
        pots: pots,
        stackSizes: stackSizes,
        playerPositions: playerPositions,
        numberOfPlayers: playerPositions.length,
        onEdit: onEdit,
        onDelete: onDelete,
        onInsert: onInsert,
        onDuplicate: onDuplicate,
        onReorder: onReorder,
        visibleCount: visibleCount,
        evaluateActionQuality: evaluateActionQuality,
        sprValue: sprValue,
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
  final ActionHistoryService actionHistory;
  final Map<int, String> playerPositions;
  final int heroIndex;
  final TextEditingController commentController;
  final TextEditingController tagsController;
  final int currentStreet;
  final List<int> pots;
  final Map<int, int> stackSizes;
  final void Function(int, ActionEntry) onEdit;
  final void Function(int) onDelete;
  final int? visibleCount;
  final String Function(ActionEntry)? evaluateActionQuality;
  final VoidCallback onAnalyze;

  const _HandEditorSection({
    required this.actionHistory,
    required this.playerPositions,
    required this.heroIndex,
    required this.commentController,
    required this.tagsController,
    required this.tournamentIdController,
    required this.buyInController,
    required this.prizePoolController,
    required this.entrantsController,
    required this.gameTypeController,
    required this.currentStreet,
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
          actionHistory: _actionHistory,
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
                _TournamentInfoSection(
                  idController: tournamentIdController,
                  buyInController: buyInController,
                  prizePoolController: prizePoolController,
                  entrantsController: entrantsController,
                  gameTypeController: gameTypeController,
                ),
                _StreetActionsSection(
                  street: currentStreet,
                  actionHistory: _actionHistory,
                  pots: pots,
                  stackSizes: stackSizes,
                  playerPositions: playerPositions,
                  potSync: _potSync,
                  allActions: actions,
                  onEdit: onEdit,
                  onDelete: onDelete,
                  onInsert: _insertAction,
                  onDuplicate: _duplicateAction,
                  onReorder: _reorderAction,
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

class _TotalPotTracker extends StatelessWidget {
  final PotSyncService potSync;
  final int currentStreet;
  final List<int> sidePots;

  const _TotalPotTracker({
    required this.potSync,
    required this.currentStreet,
    required this.sidePots,
  });

  @override
  Widget build(BuildContext context) {
    final currentPot =
        currentStreet < potSync.pots.length ? potSync.pots[currentStreet] : 0;
    final sideTotal = sidePots.fold<int>(0, (p, e) => p + e);
    final totalPot = currentPot + sideTotal;
    if (totalPot <= 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        'Total Pot: ${ActionFormattingHelper.formatAmount(totalPot)}',
        style: const TextStyle(
          color: Colors.orangeAccent,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

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
    s._processingService.debugPanelCallback = setState;
    _searchController.text = s._debugPrefs.searchQuery;
  }

  @override
  void dispose() {
    s._debugPanelSetState = null;
    s._processingService.debugPanelCallback = null;
    _searchController.dispose();
    super.dispose();
  }

  Widget _btn(String label, VoidCallback? onPressed,
      {bool disableDuringTransition = false}) {
    final cb = disableDuringTransition
        ? s.lockService.transitionSafe(onPressed)
        : onPressed;
    final disabled = disableDuringTransition && s._transitionHistory.isLocked;
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
        await s._importExportService.bulkImportEvaluationBackups(s.context);
        if (s.mounted) s.lockService.safeSetState(s, () {});
        s._debugPanelSetState?.call(() {});
      },
      'Bulk Import Auto-Backups': () async {
        await s._importExportService.bulkImportAutoBackups(s.context);
        if (s.mounted) s.lockService.safeSetState(s, () {});
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
        await s._importExportService.importQuickBackups(s.context);
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
          s._queueService.failed.isEmpty
              ? null
              : () async {
                  await s._processingService.retryFailedEvaluations();
                  if (s.mounted) s.lockService.safeSetState(s, () {});
                },
      'Export Snapshot Now': s._processingService.processing
          ? null
          : () => s._exportEvaluationQueueSnapshot(showNotification: true),
      'Backup Queue Now': s._processingService.processing
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
            if (v) await s._importExportService.cleanupOldEvaluationSnapshots();
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

  Widget _pinHeroSwitch() {
    return Row(
      children: [
        const Expanded(child: Text('Pin Hero Position')),
        Switch(
          value: s._debugPrefs.pinHeroPosition,
          onChanged: (v) async {
            await s._debugPrefs.setPinHeroPosition(v);
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
          disabled || s._processingService.processing
              ? null
              : () async {
                  await s._processingService.processQueue();
                  if (s.mounted) s.lockService.safeSetState(s, () {});
                },
      'Start Evaluation Processing':
          disabled || s._processingService.processing
              ? null
              : () async {
                  await s._processingService.processQueue();
                  if (s.mounted) s.lockService.safeSetState(s, () {});
                },
      s._processingService.pauseRequested ? 'Resume' : 'Pause':
          disabled || !s._processingService.processing
              ? null
              : () async {
                  await s._processingService.togglePauseProcessing();
                  if (s.mounted) s.lockService.safeSetState(s, () {});
                },
      'Cancel Evaluation Processing':
          !s._processingService.processing && disabled
              ? null
              : () async {
                  await s._processingService.cancelProcessing();
                  if (s.mounted) s.lockService.safeSetState(s, () {});
                },
      'Force Evaluation Restart': disabled
          ? null
          : () async {
              await s._processingService.forceRestartProcessing();
              if (s.mounted) s.lockService.safeSetState(s, () {});
            },
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
        state._pinHeroSwitch(),
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
        ActionFormattingHelper.formatAmount(s._potSync.pots[s.currentStreet]);
    final int hudEffStack = s._potSync.calculateEffectiveStackForStreet(
        s.currentStreet, s.actions, s.numberOfPlayers);
    final double? hudSprValue = s._potSync.pots[s.currentStreet] > 0
        ? hudEffStack / s._potSync.pots[s.currentStreet]
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
        _DebugPanelDialogState._vGap,
        debugDiag('Pin Hero Position', s._debugPrefs.pinHeroPosition),
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
            !s._actionHistory.expandedStreets.contains(street),
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
        disableDuringTransition ? s.lockService.transitionSafe(onPressed) : onPressed;
    final disabled = disableDuringTransition && s.lockService.isLocked;
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
                'Initial ${s._stackService.getInitialStack(i)}, '
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
            if (s._actionTagService.toMap().isNotEmpty)
              for (final entry in s._actionTagService.toMap().entries) ...[
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
        _dialogBtn('Export Spot To Clipboard', s.exportTrainingSpotToClipboard,
            disableDuringTransition: true),
        _dialogBtn('Import Spot From Clipboard', s.importTrainingSpotFromClipboard,
            disableDuringTransition: true),
        _dialogBtn('Export Spot To File', s.exportTrainingSpotToFile,
            disableDuringTransition: true),
        _dialogBtn('Import Spot From File', s.importTrainingSpotFromFile,
            disableDuringTransition: true),
        _dialogBtn('Export Spot Archive', s.exportTrainingArchive,
            disableDuringTransition: true),
        _dialogBtn('Export Profile To Clipboard',
            s.exportPlayerProfileToClipboard,
            disableDuringTransition: true),
        _dialogBtn('Import Profile From Clipboard',
            s.importPlayerProfileFromClipboard,
            disableDuringTransition: true),
        _dialogBtn('Export Profile To File', s.exportPlayerProfileToFile,
            disableDuringTransition: true),
        _dialogBtn('Import Profile From File', s.importPlayerProfileFromFile,
            disableDuringTransition: true),
        _dialogBtn('Export Profile Archive', s.exportPlayerProfileArchive,
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
          s._transitionHistory.isLocked
              ? null
              : s._undoAction,
        ),
        _dialogBtn(
          'Redo',
          s._transitionHistory.isLocked
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

 
String _formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, "0");
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, "0");
  return "$minutes:$seconds";
}

