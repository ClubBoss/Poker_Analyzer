import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/evaluation_queue_service.dart';
import '../services/debug_preferences_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/card_model.dart';
import '../models/action_entry.dart';
import '../services/playback_manager_service.dart';
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
import '../models/street_investments.dart';
import '../helpers/pot_calculator.dart';
import '../widgets/chip_moving_widget.dart';
import '../services/stack_manager_service.dart';
import '../services/player_manager_service.dart';
import '../helpers/date_utils.dart';
import '../widgets/evaluation_request_tile.dart';
import '../helpers/debug_helpers.dart';
import '../helpers/table_geometry_helper.dart';
import '../helpers/action_formatting_helper.dart';
import '../services/backup_manager_service.dart';

enum _ActionChangeType { add, edit, delete }

class _ActionHistoryEntry {
  final _ActionChangeType type;
  final int index;
  final ActionEntry? oldEntry;
  final ActionEntry? newEntry;
  final int prevStreet;
  final int newStreet;

  _ActionHistoryEntry(
    this.type,
    this.index, {
    this.oldEntry,
    this.newEntry,
    required this.prevStreet,
    required this.newStreet,
  });
}

class _StateSnapshot {
  final int street;
  final int boardStreet;
  final List<CardModel> board;
  final int playbackIndex;

  _StateSnapshot({
    required this.street,
    required this.boardStreet,
    required this.board,
    required this.playbackIndex,
  });
}

class PokerAnalyzerScreen extends StatefulWidget {
  final SavedHand? initialHand;

  const PokerAnalyzerScreen({super.key, this.initialHand});

  @override
  State<PokerAnalyzerScreen> createState() => _PokerAnalyzerScreenState();
}

class _PokerAnalyzerScreenState extends State<PokerAnalyzerScreen>
    with TickerProviderStateMixin {
  late SavedHandManagerService _handManager;
  List<SavedHand> get savedHands => _handManager.hands;
  late PlayerManagerService _playerManager;
  int get heroIndex => _playerManager.heroIndex;
  set heroIndex(int v) => _playerManager.heroIndex = v;
  String get _heroPosition => _playerManager.heroPosition;
  set _heroPosition(String v) => _playerManager.heroPosition = v;
  int get numberOfPlayers => _playerManager.numberOfPlayers;
  set numberOfPlayers(int v) => _playerManager.numberOfPlayers = v;
  List<List<CardModel>> get playerCards => _playerManager.playerCards;
  List<CardModel> get boardCards => _playerManager.boardCards;
  List<PlayerModel> get players => _playerManager.players;
  Map<int, String> get playerPositions => _playerManager.playerPositions;
  Map<int, PlayerType> get playerTypes => _playerManager.playerTypes;
  Map<int, int> get _initialStacks => _playerManager.initialStacks;
  List<bool> get _showActionHints => _playerManager.showActionHints;
  final List<CardModel> revealedBoardCards = [];
  int? get opponentIndex => _playerManager.opponentIndex;
  set opponentIndex(int? v) => _playerManager.opponentIndex = v;
  int currentStreet = 0;
  int boardStreet = 0;
  final List<ActionEntry> actions = [];
  late PlaybackManagerService _playbackManager;
  final PotCalculator _potCalculator = PotCalculator();
  late StackManagerService _stackService;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  Set<String> get allTags => _handManager.allTags;
  Set<String> get tagFilters => _handManager.tagFilters;
  set tagFilters(Set<String> v) => _handManager.tagFilters = v;
  int? activePlayerIndex;
  Timer? _activeTimer;
  final Map<int, String?> _actionTags = {};
  final Set<int> _foldedPlayers = {};
  final List<_ActionHistoryEntry> _undoStack = [];
  final List<_ActionHistoryEntry> _redoStack = [];
  final List<_StateSnapshot> _undoSnapshots = [];
  final List<_StateSnapshot> _redoSnapshots = [];

  bool debugLayout = false;
  final Set<int> _expandedHistoryStreets = {};

  ActionEntry? _centerChipAction;
  bool _showCenterChip = false;
  Timer? _centerChipTimer;
  late AnimationController _centerChipController;
  bool _showAllRevealedCards = false;
  bool isPerspectiveSwitched = false;
  String? _currentHandName;


  /// Handles evaluation queue state and processing.
  late final EvaluationQueueService _queueService;

  List<ActionEvaluationRequest> get _pendingEvaluations => _queueService.pending;
  List<ActionEvaluationRequest> get _completedEvaluations => _queueService.completed;
  List<ActionEvaluationRequest> get _failedEvaluations => _queueService.failed;
  bool get _processingEvaluations => _queueService.processing;
  set _processingEvaluations(bool v) => _queueService.processing = v;
  bool get _pauseProcessingRequested => _queueService.pauseRequested;
  set _pauseProcessingRequested(bool v) => _queueService.pauseRequested = v;
  bool get _cancelProcessingRequested => _queueService.cancelRequested;
  set _cancelProcessingRequested(bool v) => _queueService.cancelRequested = v;


  /// Allows updating the debug panel while it's open.
  StateSetter? _debugPanelSetState;
  late BackupManagerService _backupManager;

  // Backup directories
  static const String _backupsFolder = 'evaluation_backups';
  static const String _autoBackupsFolder = 'evaluation_autobackups';
  static const String _snapshotsFolder = 'evaluation_snapshots';
  static const String _exportsFolder = 'evaluation_exports';

  Future<Directory> _getBackupDirectory(String subfolder) async {
    final dir = await getApplicationDocumentsDirectory();
    final target = Directory('${dir.path}/$subfolder');
    try {
      await target.create(recursive: true);
    } catch (_) {}
    return target;
  }

  Future<void> _writeJsonFile(File file, Object data) async {
    try {
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to write ${file.path}: $e');
      }
      rethrow;
    }
  }

  Future<dynamic> _readJsonFile(File file) async {
    final content = await file.readAsString();
    return jsonDecode(content);
  }

  String _timestamp() => DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());

  Future<void> _cleanupOldFiles(String subfolder, int retentionLimit) async {
    try {
      final dir = await _getBackupDirectory(subfolder);

      final entries = <MapEntry<File, DateTime>>[];
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final stat = await entity.stat();
            entries.add(MapEntry(entity, stat.modified));
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Failed to stat ${entity.path}: $e');
            }
          }
        }
      }

      entries.sort((a, b) => b.value.compareTo(a.value));
      for (final entry in entries.skip(retentionLimit)) {
        try {
          await entry.key.delete();
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Failed to delete ${entry.key.path}: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Cleanup error: $e');
      }
    }
  }

  static const int _snapshotRetentionLimit = 50;
  static const int _backupRetentionLimit = 30;
  /// Number of automatic queue backups to retain.
  static const int _autoBackupRetentionLimit = 50;
  final DebugPreferencesService _debugPrefs = DebugPreferencesService();

  /// Evaluation processing delay, snapshot retention and other debug
  /// preferences are managed by [_debugPrefs].

  static const _pendingOrderKey = 'pending_queue_order';
  static const _failedOrderKey = 'failed_queue_order';
  static const _completedOrderKey = 'completed_queue_order';

  static const List<int> _stageCardCounts = [0, 3, 4, 5];
  static const List<String> _stageNames = ['Preflop', 'Flop', 'Turn', 'River'];

  /// Determine which board stage a particular card index belongs to.
  int _stageForBoardIndex(int index) {
    if (index <= 2) return 1; // Flop
    if (index == 3) return 2; // Turn
    return 3; // River
  }



  String _queueEntryId(ActionEvaluationRequest r) => r.id;


  ActionEvaluationRequest _decodeEvaluationRequest(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    if (map['id'] == null || map['id'] is! String || (map['id'] as String).isEmpty) {
      map['id'] = const Uuid().v4();
    }
    return ActionEvaluationRequest.fromJson(map);
  }

  List<ActionEvaluationRequest> _decodeEvaluationList(dynamic list) {
    final items = <ActionEvaluationRequest>[];
    if (list is List) {
      for (final item in list) {
        if (item is Map) {
          try {
            items.add(_decodeEvaluationRequest(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
    }
    return items;
  }

  /// Decode a backup JSON object into separate pending, failed and completed
  /// evaluation lists. Supports both the legacy list-only format containing
  /// only pending requests and the newer map format with all three queues.
  Map<String, List<ActionEvaluationRequest>> _decodeBackupQueues(dynamic json) {
    if (json is List) {
      return {
        'pending': _decodeEvaluationList(json),
        'failed': <ActionEvaluationRequest>[],
        'completed': <ActionEvaluationRequest>[],
      };
    } else if (json is Map) {
      return {
        'pending': _decodeEvaluationList(json['pending']),
        'failed': _decodeEvaluationList(json['failed']),
        'completed': _decodeEvaluationList(json['completed']),
      };
    }
    throw const FormatException();
  }

  Map<String, dynamic> _currentQueueState() => {
        'pending': [for (final e in _pendingEvaluations) e.toJson()],
        'failed': [for (final e in _failedEvaluations) e.toJson()],
        'completed': [for (final e in _completedEvaluations) e.toJson()],
      };

  void _applySavedOrder(
      List<ActionEvaluationRequest> list, List<String>? order) {
    if (order == null || order.isEmpty) return;
    final remaining = List<ActionEvaluationRequest>.from(list);
    final reordered = <ActionEvaluationRequest>[];
    for (final key in order) {
      final idx = remaining.indexWhere((e) => e.id == key);
      if (idx != -1) {
        reordered.add(remaining.removeAt(idx));
      }
    }
    reordered.addAll(remaining);
    list
      ..clear()
      ..addAll(reordered);
  }

  void _startAutoBackupTimer() {
    _autoBackupTimer?.cancel();
    _autoBackupTimer =
        Timer.periodic(const Duration(minutes: 15), (_) => _autoBackupEvaluationQueue());
  }

  Future<void> _autoBackupEvaluationQueue() async {
    if (_autoBackupRunning) return;
    _autoBackupRunning = true;
    try {
      final backupDir = await _getBackupDirectory(_autoBackupsFolder);
      final file = File('${backupDir.path}/auto_${_timestamp()}.json');
      await _writeJsonFile(file, _currentQueueState());
      await _cleanupOldAutoBackups();
      if (kDebugMode) {
        debugPrint('Auto backup created: ${file.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Auto backup error: $e');
      }
    } finally {
      _autoBackupRunning = false;
    }
  }

  Future<void> _cleanupOldAutoBackups() async {
    await _cleanupOldFiles(_autoBackupsFolder, _autoBackupRetentionLimit);
  }

  Widget _queueSection(String label, List<ActionEvaluationRequest> queue) {
    final filtered = _debugPrefs.applyAdvancedFilters(queue);
    return debugQueueSection(label, filtered,
        _debugPrefs.advancedFilters.isEmpty && !_debugPrefs.sortBySpr &&
            _debugPrefs.searchQuery.isEmpty
            ? (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex -= 1;
                setState(() {
                  final item = queue.removeAt(oldIndex);
                  queue.insert(newIndex, item);
                });
                _queueService.persist();
                _debugPanelSetState?.call(() {});
              }
            : (_, __) {});
  }


  void setPosition(int playerIndex, String position) {
    setState(() {
      _playerManager.setPosition(playerIndex, position);
    });
  }

  void _onPlayerCountChanged(int value) {
    setState(() {
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
    return _playerManager.heroIndex;
  }

  int _inferBoardStreet() {
    final count = boardCards.length;
    if (count >= _stageCardCounts[3]) return 3;
    if (count >= _stageCardCounts[2]) return 2;
    if (count >= _stageCardCounts[1]) return 1;
    return 0;
  }

  bool _isBoardStageComplete(int stage) {
    return boardCards.length >= _stageCardCounts[stage];
  }

  void _ensureBoardStreetConsistent() {
    final inferred = _inferBoardStreet();
    if (inferred != boardStreet) {
      boardStreet = inferred;
      currentStreet = inferred;
    }
  }

  void _updateRevealedBoardCards() {
    final visible = _stageCardCounts[currentStreet];
    revealedBoardCards
      ..clear()
      ..addAll(boardCards.take(visible));
  }

  void _triggerCenterChip(ActionEntry entry) {
    if (!['bet', 'raise', 'call', 'all-in'].contains(entry.action) ||
        entry.amount == null ||
        entry.generated) {
      return;
    }
    _centerChipTimer?.cancel();
    _centerChipController.forward(from: 0);
    setState(() {
      _centerChipAction = entry;
      _showCenterChip = true;
    });
    _centerChipTimer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _centerChipController.reverse();
      setState(() {
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

  void _recomputeFoldedPlayers() {
    _foldedPlayers
      ..clear()
      ..addAll({
        for (final a in actions)
          if (a.action == 'fold') a.playerIndex
      });
  }

  _StateSnapshot _currentSnapshot() => _StateSnapshot(
        street: currentStreet,
        boardStreet: boardStreet,
        board: List<CardModel>.from(boardCards),
        playbackIndex: _playbackManager.playbackIndex,
      );

  void _recordSnapshot() {
    _ensureBoardStreetConsistent();
    _undoSnapshots.add(_currentSnapshot());
    _redoSnapshots.clear();
  }

  void _applySnapshot(_StateSnapshot snap) {
    currentStreet = snap.street;
    boardCards
      ..clear()
      ..addAll(snap.board);
    boardStreet = snap.boardStreet;
    if (currentStreet != boardStreet) {
      currentStreet = boardStreet;
    }
    _playbackManager.seek(snap.playbackIndex);
    _updateRevealedBoardCards();
    _playbackManager.updatePlaybackState();
  }

  void _updateRevealedBoardCards() {
    final visibleCount = _stageCardCounts[currentStreet];
    revealedBoardCards
      ..clear()
      ..addAll(boardCards.take(visibleCount));
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
    final tags = _tagsController.text
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
    _tagsController.text = tags.join(', ');
  }


  Future<void> _editPlayerInfo(int index) async {
    final disableCards = index != _playerManager.heroIndex;

    await showDialog(
      context: context,
      builder: (context) => _PlayerEditorSection(
        initialStack: _playerManager.initialStacks[index] ?? 0,
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
          setState(() {
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
            _stackService =
                StackManagerService(Map<int, int>.from(_playerManager.initialStacks));
            _playbackManager.stackService = _stackService;
            _playbackManager.updatePlaybackState();
          });
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _queueService = EvaluationQueueService();
    _backupManager = BackupManagerService(
      queueService: _queueService,
      debugPrefs: _debugPrefs,
    );
    _centerChipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _playerManager = PlayerManagerService()..addListener(_onPlayerManagerChanged);
    _stackService =
        StackManagerService(Map<int, int>.from(_playerManager.initialStacks));
    _playbackManager = PlaybackManagerService(
      actions: actions,
      stackService: _stackService,
      potCalculator: _potCalculator,
    )..addListener(_onPlaybackManagerChanged);
    _playerManager.updatePositions();
    boardStreet = _inferBoardStreet();
    currentStreet = boardStreet;
    _updateRevealedBoardCards();
    _playbackManager.updatePlaybackState();
    _updateRevealedBoardCards();
    if (widget.initialHand != null) {
      _applySavedHand(widget.initialHand!);
    }
    Future(() => _cleanupOldEvaluationBackups());
    Future(() async {
      await _debugPrefs.loadSnapshotRetentionPreference();
      if (_debugPrefs.snapshotRetentionEnabled) {
        await _cleanupOldEvaluationSnapshots();
      }
      setState(() {});
    });
    Future(() async {
      await _debugPrefs.loadProcessingDelayPreference();
      setState(() {});
    });
    Future(() async {
      await _debugPrefs.loadQueueFilterPreference();
      setState(() {});
    });
    Future(() async {
      await _debugPrefs.loadAdvancedFilterPreference();
      setState(() {});
    });
    Future(() async {
      await _debugPrefs.loadSearchQueryPreference();
      setState(() {});
    });
    Future(() async {
      await _debugPrefs.loadSortBySprPreference();
      setState(() {});
    });
    Future(() async {
      await _debugPrefs.loadQueueResumedPreference();
      setState(() {});
    });
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
    setState(() => _playerManager.selectCard(index, card));
  }

  Future<void> _onPlayerCardTap(int index, int cardIndex) async {
    final selectedCard = await showCardSelector(context);
    if (selectedCard == null) return;
    setState(() =>
        _playerManager.setPlayerCard(index, cardIndex, selectedCard));
  }

  void _onPlayerTimeExpired(int index) {
    if (activePlayerIndex == index) {
      setState(() => activePlayerIndex = null);
    }
  }

  Future<void> _onOpponentCardTap(int cardIndex) async {
    if (opponentIndex == null) opponentIndex = activePlayerIndex;
    final idx = opponentIndex ?? 0;
    await _onRevealedCardTap(idx, cardIndex);
  }

  Future<void> _onRevealedCardTap(int playerIndex, int cardIndex) async {
    final selected = await showCardSelector(context);
    if (selected == null) return;
    setState(() =>
        _playerManager.setRevealedCard(playerIndex, cardIndex, selected));
  }

  /// Inform the user when they attempt to skip a board stage while editing.
  /// [prevStage] and [nextStage] are indices into [_stageNames].
  void _showBoardSkipWarning(int prevStage, int nextStage) {
    if (!mounted) return;
    final prevName = _stageNames[prevStage];
    final nextName = _stageNames[nextStage];
    final count = _stageCardCounts[prevStage];
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Add $count cards on the $prevName before editing the $nextName.',
          ),
        ),
      );
  }

  /// Check if a board card can be added at [index] without skipping streets.
  /// Returns `true` if the preceding stage is complete. Otherwise shows a
  /// warning and returns `false`.
  bool _canAddBoardCard(int index) {
    final stage = _stageForBoardIndex(index);
    if (index > boardCards.length) {
      final expectedStage = _stageForBoardIndex(boardCards.length);
      _showBoardSkipWarning(expectedStage, stage);
      return false;
    }
    if (!_isBoardStageComplete(stage - 1)) {
      _showBoardSkipWarning(stage - 1, stage);
      return false;
    }
    return true;
  }

  bool _canEditBoard(int index) => _canAddBoardCard(index);

  void selectBoardCard(int index, CardModel card) {
    if (!_canEditBoard(index)) return;
    setState(() {
      _recordSnapshot();
      _playerManager.selectBoardCard(index, card);
      _ensureBoardStreetConsistent();
      _updateRevealedBoardCards();
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
    setState(() => activePlayerIndex = index);
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
      setState(() {});
    }
  }

  void _onPlayerManagerChanged() {
    final prevStreet = boardStreet;
    _ensureBoardStreetConsistent();
    if (boardStreet != prevStreet) {
      _playbackManager.updatePlaybackState();
    }
    _updateRevealedBoardCards();
    if (mounted) setState(() {});
  }






  void _clearEvaluationQueue() {
    setState(() {
      _pendingEvaluations.clear();
      _completedEvaluations.clear();
      _failedEvaluations.clear();
    });
    _queueService.persist();
    unawaited(_debugPrefs.setEvaluationQueueResumed(false));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evaluation queue cleared')),
      );
    }
    _debugPanelSetState?.call(() {});
  }

  void _clearPendingQueue() {
    if (_pendingEvaluations.isEmpty) return;
    setState(() {
      _pendingEvaluations.clear();
    });
    _queueService.persist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pending queue cleared')),
      );
    }
    _debugPanelSetState?.call(() {});
  }

  void _clearFailedQueue() {
    if (_failedEvaluations.isEmpty) return;
    setState(() {
      _failedEvaluations.clear();
    });
    _queueService.persist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed queue cleared')),
      );
    }
    _debugPanelSetState?.call(() {});
  }

  void _clearCompletedQueue() {
    if (_completedEvaluations.isEmpty) return;
    setState(() {
      _completedEvaluations.clear();
    });
    _queueService.persist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completed queue cleared')),
      );
    }
    _debugPanelSetState?.call(() {});
  }

  void _clearCompletedEvaluations() {
    final count = _completedEvaluations.length;
    if (count == 0) return;
    setState(() {
      _completedEvaluations.clear();
    });
    _queueService.persist();
    _debugPanelSetState?.call(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cleared $count completed evaluations')),
      );
    }
  }

  int _deduplicateList(
      List<ActionEvaluationRequest> list, Set<String> seenIds) {
    final originalLength = list.length;
    final unique = <ActionEvaluationRequest>[];
    for (final entry in list) {
      if (seenIds.add(entry.id)) unique.add(entry);
    }
    list
      ..clear()
      ..addAll(unique);
    return originalLength - unique.length;
  }

  void _removeDuplicateEvaluations() {
    try {
      var removed = 0;
      setState(() {
        final seen = <String>{};
        removed += _deduplicateList(_pendingEvaluations, seen);
        removed += _deduplicateList(_failedEvaluations, seen);
        removed += _deduplicateList(_completedEvaluations, seen);
      });
      if (removed > 0) {
        _queueService.persist();
      }
      if (mounted) {
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

  void _resolveQueueConflicts() {
    try {
      var removed = 0;
      setState(() {
        final seen = <String>{};

        final newCompleted = <ActionEvaluationRequest>[];
        for (final e in _completedEvaluations) {
          if (seen.add(e.id)) {
            newCompleted.add(e);
          } else {
            removed++;
          }
        }

        final newFailed = <ActionEvaluationRequest>[];
        for (final e in _failedEvaluations) {
          if (seen.add(e.id)) {
            newFailed.add(e);
          } else {
            removed++;
          }
        }

        final newPending = <ActionEvaluationRequest>[];
        for (final e in _pendingEvaluations) {
          if (seen.add(e.id)) {
            newPending.add(e);
          } else {
            removed++;
          }
        }

        _completedEvaluations
          ..clear()
          ..addAll(newCompleted);
        _failedEvaluations
          ..clear()
          ..addAll(newFailed);
        _pendingEvaluations
          ..clear()
          ..addAll(newPending);
      });

      if (removed > 0) {
        _queueService.persist();
      }
      if (mounted) {
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

  void _sortEvaluationQueues() {
    try {
      setState(() {
        _pendingEvaluations.sort(_compareEvaluationRequests);
        _failedEvaluations.sort(_compareEvaluationRequests);
        _completedEvaluations.sort(_compareEvaluationRequests);
      });
      _queueService.persist();
      if (mounted) {
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

  void _toggleEvaluationProcessingPause() {
    setState(() {
      _pauseProcessingRequested = !_pauseProcessingRequested;
    });
    _debugPanelSetState?.call(() {});
    if (!_pauseProcessingRequested && !_processingEvaluations &&
        _pendingEvaluations.isNotEmpty) {
      _queueService.processQueue();
    }
  }

  void _cancelEvaluationProcessing() {
    setState(() {
      _cancelProcessingRequested = true;
      _pauseProcessingRequested = false;
      _pendingEvaluations.clear();
      _processingEvaluations = false;
    });
    _queueService.persist();
    _debugPanelSetState?.call(() {});
  }

  Future<void> _forceRestartEvaluationProcessing() async {
    if (_processingEvaluations) {
      setState(() {
        _cancelProcessingRequested = true;
        _pauseProcessingRequested = false;
      });
      _debugPanelSetState?.call(() {});
      while (_processingEvaluations) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
    if (mounted) {
      setState(() {
        _processingEvaluations = false;
        _cancelProcessingRequested = false;
      });
    } else {
      _processingEvaluations = false;
      _cancelProcessingRequested = false;
    }
    _debugPanelSetState?.call(() {});
    if (_pendingEvaluations.isNotEmpty) {
      _queueService.processQueue();
    }
  }

  void _retryFailedEvaluations() {
    _queueService.retryFailedEvaluations().then((_) {
      if (mounted) {
        setState(() {});
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
      actions.removeAt(idx);
    }
    if (_playbackManager.playbackIndex > actions.length) {
      _playbackManager.seek(actions.length);
    }
    try {
      final last =
          actions.lastWhere((a) => a.playerIndex == playerIndex);
      _actionTags[playerIndex] =
          '${last.action}${last.amount != null ? ' ${last.amount}' : ''}';
    } catch (_) {
      _actionTags.remove(playerIndex);
    }
    _recomputeFoldedPlayers();
    _playbackManager.updatePlaybackState();
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
    final prevStreet = currentStreet;
    final inferred = _inferBoardStreet();
    if (inferred > currentStreet) {
      currentStreet = inferred;
      boardStreet = inferred;
      _updateRevealedBoardCards();
    }
    if (entry.street != currentStreet) {
      entry = ActionEntry(currentStreet, entry.playerIndex, entry.action,
          amount: entry.amount, generated: entry.generated);
    }
    final insertIndex = index ?? actions.length;
    if (recordHistory) {
      _recordSnapshot();
    }
    if (index != null) {
      actions.insert(index, entry);
    } else {
      actions.add(entry);
    }
    if (recordHistory) {
      _undoStack.add(_ActionHistoryEntry(_ActionChangeType.add, insertIndex,
          newEntry: entry, prevStreet: prevStreet, newStreet: currentStreet));
      _redoStack.clear();
    }
    if (entry.action == 'fold') {
      _foldedPlayers.add(entry.playerIndex);
    }
    _actionTags[entry.playerIndex] =
        '${entry.action}${entry.amount != null ? ' ${entry.amount}' : ''}';
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
    _recomputeFoldedPlayers();
    if (_playbackManager.playbackIndex > actions.length) {
      _playbackManager.seek(actions.length);
    }
    _updateRevealedBoardCards();
    _playbackManager.updatePlaybackState();
  }

  void onActionSelected(ActionEntry entry) {
    setState(() {
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
    actions[index] = entry;
    if (recordHistory) {
      _undoStack.add(_ActionHistoryEntry(_ActionChangeType.edit, index,
          oldEntry: previous, newEntry: entry,
          prevStreet: currentStreet, newStreet: currentStreet));
      _redoStack.clear();
    }
    _recomputeFoldedPlayers();
    _actionTags[entry.playerIndex] =
        '${entry.action}${entry.amount != null ? ' ${entry.amount}' : ''}';
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
    setState(() {
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
      final removed = actions.removeAt(index);
      if (recordHistory) {
        _undoStack.add(_ActionHistoryEntry(_ActionChangeType.delete, index,
            oldEntry: removed,
            prevStreet: currentStreet,
            newStreet: currentStreet));
        _redoStack.clear();
      }
      if (_playbackManager.playbackIndex > actions.length) {
        _playbackManager.seek(actions.length);
      }
      // Update action tag for player whose action was removed
      try {
        final last = actions.lastWhere((a) => a.playerIndex == removed.playerIndex);
        _actionTags[removed.playerIndex] =
            '${last.action}${last.amount != null ? ' ${last.amount}' : ''}';
      } catch (_) {
        _actionTags.remove(removed.playerIndex);
      }
      _recomputeFoldedPlayers();
      _playbackManager.updatePlaybackState();
    }

    if (withSetState) {
      setState(perform);
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
      setState(() {
        _deleteAction(actionIndex, withSetState: false);
      });
    }
  }

  void _undoAction() {
    if (_undoStack.isEmpty) {
      if (_undoSnapshots.isEmpty) return;
      setState(() {
        final snap = _undoSnapshots.removeLast();
        _redoSnapshots.add(_currentSnapshot());
        _applySnapshot(snap);
      });
      _debugPanelSetState?.call(() {});
      return;
    }
    setState(() {
      final op = _undoStack.removeLast();
      final snap =
          _undoSnapshots.isNotEmpty ? _undoSnapshots.removeLast() : null;
      switch (op.type) {
        case _ActionChangeType.add:
          _deleteAction(op.index, recordHistory: false, withSetState: false);
          break;
        case _ActionChangeType.edit:
          _updateAction(op.index, op.oldEntry!, recordHistory: false);
          break;
        case _ActionChangeType.delete:
          _addAction(op.oldEntry!, index: op.index, recordHistory: false);
          break;
      }
      currentStreet = op.prevStreet;
      _updateRevealedBoardCards();
      _playbackManager.updatePlaybackState();
      _redoStack.add(op);
      if (snap != null) {
        _redoSnapshots.add(_currentSnapshot());
        _applySnapshot(snap);
      }
    });
    _debugPanelSetState?.call(() {});
  }

  void _redoAction() {
    if (_redoStack.isEmpty) {
      if (_redoSnapshots.isEmpty) return;
      setState(() {
        final snap = _redoSnapshots.removeLast();
        _undoSnapshots.add(_currentSnapshot());
        _applySnapshot(snap);
      });
      _debugPanelSetState?.call(() {});
      return;
    }
    setState(() {
      final op = _redoStack.removeLast();
      final snap =
          _redoSnapshots.isNotEmpty ? _redoSnapshots.removeLast() : null;
      switch (op.type) {
        case _ActionChangeType.add:
          _addAction(op.newEntry!, index: op.index, recordHistory: false);
          break;
        case _ActionChangeType.edit:
          _updateAction(op.index, op.newEntry!, recordHistory: false);
          break;
        case _ActionChangeType.delete:
          _deleteAction(op.index, recordHistory: false, withSetState: false);
          break;
      }
      currentStreet = op.newStreet;
      _updateRevealedBoardCards();
      _playbackManager.updatePlaybackState();
      _undoStack.add(op);
      if (snap != null) {
        _undoSnapshots.add(_currentSnapshot());
        _applySnapshot(snap);
      }
    });
    _debugPanelSetState?.call(() {});
  }

  Future<void> _removePlayer(int index) async {
    if (_playerManager.numberOfPlayers <= 2) return;

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

    setState(() {
      _playerManager.removePlayer(
        index,
        heroIndexOverride: updatedHeroIndex,
        actions: actions,
        actionTags: _actionTags,
        hintFlags: _playerManager.showActionHints,
      );
      if (_playbackManager.playbackIndex > actions.length) {
        _playbackManager.seek(actions.length);
      }
      _stackService =
          StackManagerService(Map<int, int>.from(_playerManager.initialStacks));
      _playbackManager.stackService = _stackService;
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
      setState(() {
        _playerManager.reset();
        actions.clear();
        _foldedPlayers.clear();
        currentStreet = 0;
        _updateRevealedBoardCards();
        _actionTags.clear();
        _playbackManager.animatedPlayersPerStreet.clear();
        _stackService =
            StackManagerService(Map<int, int>.from(_playerManager.initialStacks));
        _playbackManager.stackService = _stackService;
        _playbackManager.resetHand();
        _commentController.clear();
        _tagsController.clear();
        _currentHandName = null;
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
    setState(() {});
    _debugPanelSetState?.call(() {});
  }

  Future<void> _exportFullEvaluationQueueState() async {
    await _backupManager.exportFullQueueState(context);
  }

  Future<void> _importFullEvaluationQueueState() async {
    try {
      final exportDir = await _getBackupDirectory(_exportsFolder);
      if (!await exportDir.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No export files found')),
          );
        }
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        initialDirectory: exportDir.path,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;

      final decoded = await _readJsonFile(File(path));
      final queues = _decodeBackupQueues(decoded);
      final pending = queues['pending']!;
      final failed = queues['failed']!;
      final completed = queues['completed']!;

      if (!mounted) return;
      setState(() {
        _pendingEvaluations
          ..clear()
          ..addAll(pending);
        _failedEvaluations
          ..clear()
          ..addAll(failed);
        _completedEvaluations
          ..clear()
          ..addAll(completed);
      });
      _debugPanelSetState?.call(() {});
      _queueService.persist();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Imported ${pending.length} pending, ${failed.length} failed, ${completed.length} completed evaluations')),
      );
      _debugPanelSetState?.call(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to import queue state')),
        );
      }
    }
  }

  Future<void> _restoreFullEvaluationQueueState() async {
    try {
      final exportDir = await _getBackupDirectory(_exportsFolder);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        initialDirectory: exportDir.path,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;

      final decoded = await _readJsonFile(File(path));
      final queues = _decodeBackupQueues(decoded);
      final pending = queues['pending']!;
      final failed = queues['failed']!;
      final completed = queues['completed']!;

      if (!mounted) return;
      setState(() {
        _pendingEvaluations
          ..clear()
          ..addAll(pending);
        _failedEvaluations
          ..clear()
          ..addAll(failed);
        _completedEvaluations
          ..clear()
          ..addAll(completed);
      });
      _debugPanelSetState?.call(() {});
      _queueService.persist();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Restored ${pending.length} pending, ${failed.length} failed, ${completed.length} completed evaluations')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to restore full queue state')),
        );
      }
    }
  }

  Future<void> _backupEvaluationQueue() async {
    await _backupManager.backupEvaluationQueue(context);
  }

  Future<void> _quickBackupEvaluationQueue() async {
    await _backupManager.quickBackupEvaluationQueue(context);
    _debugPanelSetState?.call(() {});
  }

  Future<void> _importQuickBackups() async {
    await _backupManager.importQuickBackups(context);
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
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/evaluation_current_queue.json');
      bool resumed = false;
      if (await file.exists()) {
        final decoded = await _readJsonFile(file);
        final pending = <ActionEvaluationRequest>[];
        final failed = <ActionEvaluationRequest>[];
        final completed = <ActionEvaluationRequest>[];
        if (decoded is List) {
          pending.addAll(_decodeEvaluationList(decoded));
        } else if (decoded is Map) {
          pending.addAll(_decodeEvaluationList(decoded['pending']));
          failed.addAll(_decodeEvaluationList(decoded['failed']));
          completed.addAll(_decodeEvaluationList(decoded['completed']));
        }

        final prefs = await SharedPreferences.getInstance();
        _applySavedOrder(pending, prefs.getStringList(_pendingOrderKey));
        _applySavedOrder(failed, prefs.getStringList(_failedOrderKey));
        _applySavedOrder(completed, prefs.getStringList(_completedOrderKey));

        if (mounted) {
          setState(() {
            _pendingEvaluations
              ..clear()
              ..addAll(pending);
            _failedEvaluations
              ..clear()
              ..addAll(failed);
            _completedEvaluations
              ..clear()
              ..addAll(completed);
            resumed =
                pending.isNotEmpty || failed.isNotEmpty || completed.isNotEmpty;
            s._debugPrefs.setEvaluationQueueResumed(resumed);
          });
          _debugPanelSetState?.call(() {});
        } else {
          resumed =
              pending.isNotEmpty || failed.isNotEmpty || completed.isNotEmpty;
          s._debugPrefs.setEvaluationQueueResumed(resumed);
          _pendingEvaluations
            ..clear()
            ..addAll(pending);
          _failedEvaluations
            ..clear()
            ..addAll(failed);
          _completedEvaluations
            ..clear()
            ..addAll(completed);
        }
        try {
          await file.delete();
        } catch (_) {}
        _queueService.persist();
        _debugPanelSetState?.call(() {});
      }
      await s._debugPrefs.setEvaluationQueueResumed(resumed);
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
    if (mounted) setState(() {});
  }

  Future<void> _processNextEvaluation() async {
    await _queueService.processQueue();
    if (mounted) setState(() {});
  }

  Future<void> _cleanupOldEvaluationBackups() async {
    await _backupManager.cleanupOldEvaluationBackups();
  }

  Future<void> _cleanupOldEvaluationSnapshots() async {
    await _backupManager.cleanupOldEvaluationSnapshots();
  }

  Future<void> _exportArchive(String subfolder, String archivePrefix) async {
    String emptyMsg;
    String failMsg;
    String dialogTitle;
    switch (subfolder) {
      case _backupsFolder:
        emptyMsg = 'No backup files found';
        failMsg = 'Failed to export backups';
        dialogTitle = 'Save Backups Archive';
        break;
      case _autoBackupsFolder:
        emptyMsg = 'No auto-backup files found';
        failMsg = 'Failed to export auto-backups';
        dialogTitle = 'Save Auto-Backups Archive';
        break;
      case _snapshotsFolder:
        emptyMsg = 'No snapshot files found';
        failMsg = 'Failed to export snapshots';
        dialogTitle = 'Save Snapshots Archive';
        break;
      default:
        emptyMsg = 'No files found';
        failMsg = 'Failed to export archive';
        dialogTitle = 'Save Archive';
    }

    try {
      final dir = await _getBackupDirectory(subfolder);
      if (!await dir.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(emptyMsg)));
        }
        return;
      }

      final files = await dir.list(recursive: true).whereType<File>().toList();

      if (files.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(emptyMsg)));
        }
        return;
      }

      final archive = Archive();
      for (final file in files) {
        final data = await file.readAsBytes();
        final name = file.path.substring(dir.path.length + 1);
        archive.addFile(ArchiveFile(name, data.length, data));
      }

      final bytes = ZipEncoder().encode(archive);
      if (bytes == null) throw Exception('Could not create archive');

      final fileName = '${archivePrefix}_${_timestamp()}.zip';
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (savePath == null) return;

      final zipFile = File(savePath);
      await zipFile.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      final name = savePath.split(Platform.pathSeparator).last;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Archive saved: $name')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failMsg)));
      }
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _exportAllEvaluationBackups() async {
    await _exportArchive(_backupsFolder, 'evaluation_backups');
  }

  Future<void> _exportAutoBackups() async {
    await _exportArchive(_autoBackupsFolder, 'evaluation_autobackups');
  }

  Future<void> _exportSnapshots() async {
    await _exportArchive(_snapshotsFolder, 'evaluation_snapshots');
  }

  Future<void> _restoreFromAutoBackup() async {
    try {
      final backupDir = await _getBackupDirectory(_autoBackupsFolder);
      if (!await backupDir.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No auto-backup files found')),
          );
        }
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        initialDirectory: backupDir.path,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      final decoded = await _readJsonFile(File(path));
      final queues = _decodeBackupQueues(decoded);
      final pending = queues["pending"]!;
      final failed = queues["failed"]!;
      final completed = queues["completed"]!;

      if (!mounted) return;
      setState(() {
        _pendingEvaluations
          ..clear()
          ..addAll(pending);
        _failedEvaluations
          ..clear()
          ..addAll(failed);
        _completedEvaluations
          ..clear()
          ..addAll(completed);
      });
      _debugPanelSetState?.call(() {});
      _queueService.persist();
      unawaited(_debugPrefs.setEvaluationQueueResumed(false));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Restored ${pending.length} pending, ${failed.length} failed, ${completed.length} completed evaluations')),
      );
      _debugPanelSetState?.call(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to restore auto-backup')),
        );
      }
    }
  }

  Future<void> _exportAllEvaluationSnapshots() async {
    await _exportArchive(_snapshotsFolder, 'evaluation_snapshots');
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
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) return;

      final importedPending = <ActionEvaluationRequest>[];
      final importedFailed = <ActionEvaluationRequest>[];
      final importedCompleted = <ActionEvaluationRequest>[];
      int skipped = 0;

      for (final f in result.files) {
        final path = f.path;
        if (path == null) {
          skipped++;
          continue;
        }
        try {
          final decoded = await _readJsonFile(File(path));
          final queues = _decodeBackupQueues(decoded);
          importedPending.addAll(queues['pending']!);
          importedFailed.addAll(queues['failed']!);
          importedCompleted.addAll(queues['completed']!);
        } catch (_) {
          skipped++;
        }
      }

      if (!mounted) return;
      setState(() {
        _pendingEvaluations.addAll(importedPending);
        _failedEvaluations.addAll(importedFailed);
        _completedEvaluations.addAll(importedCompleted);
      });
      _debugPanelSetState?.call(() {});
      _queueService.persist();
      unawaited(_debugPrefs.setEvaluationQueueResumed(false));

      final total =
          importedPending.length + importedFailed.length + importedCompleted.length;
      final msg = skipped == 0
          ? 'Imported $total evaluations from ${result.files.length} files'
          : 'Imported $total evaluations, $skipped files skipped';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bulk import failed')),
        );
      }
    }
  }

  Future<void> _bulkImportEvaluationBackups() async {
    try {
      final backupDir = await _getBackupDirectory(_backupsFolder);
      if (!await backupDir.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No backup files found')),
          );
        }
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: true,
        initialDirectory: backupDir.path,
      );
      if (result == null || result.files.isEmpty) return;

      final importedPending = <ActionEvaluationRequest>[];
      final importedFailed = <ActionEvaluationRequest>[];
      final importedCompleted = <ActionEvaluationRequest>[];
      int skipped = 0;

      for (final f in result.files) {
        final path = f.path;
        if (path == null) {
          skipped++;
          continue;
        }
        try {
          final decoded = await _readJsonFile(File(path));
          final queues = _decodeBackupQueues(decoded);
          importedPending.addAll(queues['pending']!);
          importedFailed.addAll(queues['failed']!);
          importedCompleted.addAll(queues['completed']!);
        } catch (_) {
          skipped++;
        }
      }

      if (!mounted) return;
      setState(() {
        _pendingEvaluations.addAll(importedPending);
        _failedEvaluations.addAll(importedFailed);
        _completedEvaluations.addAll(importedCompleted);
      });
      _debugPanelSetState?.call(() {});
      _queueService.persist();
      unawaited(_debugPrefs.setEvaluationQueueResumed(false));

      final total =
          importedPending.length + importedFailed.length + importedCompleted.length;
      final msg = skipped == 0
          ? 'Imported $total evaluations from ${result.files.length} files'
          : 'Imported $total evaluations, $skipped files skipped';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to import backups')),
        );
      }
    }
  }

  Future<void> _importQuickBackups() async {
    await _backupManager.importQuickBackups(context);
    _debugPanelSetState?.call(() {});
  }

  Future<void> _bulkImportAutoBackups() async {
    try {
      final backupDir = await _getBackupDirectory(_autoBackupsFolder);
      if (!await backupDir.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No auto-backup files found')),
          );
        }
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: true,
        initialDirectory: backupDir.path,
      );
      if (result == null || result.files.isEmpty) return;

      final importedPending = <ActionEvaluationRequest>[];
      final importedFailed = <ActionEvaluationRequest>[];
      final importedCompleted = <ActionEvaluationRequest>[];
      int skipped = 0;

      for (final f in result.files) {
        final path = f.path;
        if (path == null) {
          skipped++;
          continue;
        }
        try {
          final decoded = await _readJsonFile(File(path));
          final queues = _decodeBackupQueues(decoded);
          importedPending.addAll(queues['pending']!);
          importedFailed.addAll(queues['failed']!);
          importedCompleted.addAll(queues['completed']!);
        } catch (_) {
          skipped++;
        }
      }

      if (!mounted) return;
      setState(() {
        _pendingEvaluations.addAll(importedPending);
        _failedEvaluations.addAll(importedFailed);
        _completedEvaluations.addAll(importedCompleted);
      });
      _debugPanelSetState?.call(() {});
      _queueService.persist();
      unawaited(_debugPrefs.setEvaluationQueueResumed(false));

      final total =
          importedPending.length + importedFailed.length + importedCompleted.length;
      final msg = skipped == 0
          ? 'Imported $total evaluations from ${result.files.length} files'
          : 'Imported $total evaluations, $skipped files skipped';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to import auto-backups')),
        );
      }
    }
  }

  Future<void> _importEvaluationQueueSnapshot() async {
    try {
      final snapDir = await _getBackupDirectory(_snapshotsFolder);
      if (!await snapDir.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No snapshot files found')),
          );
        }
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        initialDirectory: snapDir.path,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      final decoded = await _readJsonFile(File(path));
      final queues = _decodeBackupQueues(decoded);
      final pending = queues['pending']!;
      final failed = queues['failed']!;
      final completed = queues['completed']!;

      if (!mounted) return;
      setState(() {
        _pendingEvaluations
          ..clear()
          ..addAll(pending);
        _failedEvaluations
          ..clear()
          ..addAll(failed);
        _completedEvaluations
          ..clear()
          ..addAll(completed);
      });
      _queueService.persist();
      unawaited(_debugPrefs.setEvaluationQueueResumed(false));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Imported ${pending.length} pending, ${failed.length} failed, ${completed.length} completed evaluations')),
      );
      _debugPanelSetState?.call(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to import snapshot')),
        );
      }
    }
  }

  Future<void> _bulkImportEvaluationSnapshots() async {
    try {
      final snapDir = await _getBackupDirectory(_snapshotsFolder);
      if (!await snapDir.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No snapshot files found')),
          );
        }
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: true,
        initialDirectory: snapDir.path,
      );
      if (result == null || result.files.isEmpty) return;

      final importedPending = <ActionEvaluationRequest>[];
      final importedFailed = <ActionEvaluationRequest>[];
      final importedCompleted = <ActionEvaluationRequest>[];
      int skipped = 0;

      for (final f in result.files) {
        final path = f.path;
        if (path == null) {
          skipped++;
          continue;
        }
        try {
          final decoded = await _readJsonFile(File(path));
          final queues = _decodeBackupQueues(decoded);
          importedPending.addAll(queues['pending']!);
          importedFailed.addAll(queues['failed']!);
          importedCompleted.addAll(queues['completed']!);
        } catch (_) {
          skipped++;
        }
      }

      if (!mounted) return;
      setState(() {
        _pendingEvaluations.addAll(importedPending);
        _failedEvaluations.addAll(importedFailed);
        _completedEvaluations.addAll(importedCompleted);
      });
      _debugPanelSetState?.call(() {});
      _queueService.persist();
      unawaited(_debugPrefs.setEvaluationQueueResumed(false));

      final total =
          importedPending.length + importedFailed.length + importedCompleted.length;
      final msg = skipped == 0
          ? 'Imported $total evaluations from ${result.files.length} files'
          : 'Imported $total evaluations, $skipped files skipped';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to import snapshots')),
        );
      }
    }
  }


  Future<void> _showDebugPanel() async {
    setState(() => _debugPrefs.isDebugPanelOpen = true);
    await showDialog<void>(
      context: context,
      builder: (context) => _DebugPanelDialog(parent: this),
    );
    setState(() => _debugPrefs.isDebugPanelOpen = false);
    _debugPanelSetState = null;
  }

  Future<void> _resetDebugPanelPreferences() async {
    await _debugPrefs.clearAll();
    if (_debugPrefs.snapshotRetentionEnabled) {
      await _cleanupOldEvaluationSnapshots();
    }
    setState(() {});
    _debugPanelSetState?.call(() {});
  }


  SavedHand _currentSavedHand({String? name}) {
    _ensureBoardStreetConsistent();
    final stacks =
        _stackService.calculateEffectiveStacksPerStreet(actions, numberOfPlayers);
    final collapsed = [
      for (int i = 0; i < 4; i++)
        if (!_expandedHistoryStreets.contains(i)) i
    ];
    return SavedHand(
      name: name ?? _defaultHandName(),
      heroIndex: _playerManager.heroIndex,
      heroPosition: _playerManager.heroPosition,
      numberOfPlayers: _playerManager.numberOfPlayers,
      playerCards: [
        for (int i = 0; i < _playerManager.numberOfPlayers; i++)
          List<CardModel>.from(_playerManager.playerCards[i])
      ],
      boardCards: List<CardModel>.from(_playerManager.boardCards),
      boardStreet: boardStreet,
      revealedCards: [
        for (int i = 0; i < _playerManager.numberOfPlayers; i++)
          [for (final c in _playerManager.players[i].revealedCards) if (c != null) c]
      ],
      opponentIndex: opponentIndex,
      activePlayerIndex: activePlayerIndex,
      actions: List<ActionEntry>.from(actions),
      stackSizes: Map<int, int>.from(_playerManager.initialStacks),
      remainingStacks: {
        for (int i = 0; i < _playerManager.numberOfPlayers; i++)
          i: _stackService.getStackForPlayer(i)
      },
      playerPositions: Map<int, String>.from(_playerManager.playerPositions),
      playerTypes: Map<int, PlayerType>.from(_playerManager.playerTypes),
      comment: _commentController.text.isNotEmpty ? _commentController.text : null,
      tags: _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      commentCursor: _commentController.selection.baseOffset >= 0
          ? _commentController.selection.baseOffset
          : null,
      tagsCursor: _tagsController.selection.baseOffset >= 0
          ? _tagsController.selection.baseOffset
          : null,
      isFavorite: false,
      date: DateTime.now(),
      effectiveStacksPerStreet: stacks,
      collapsedHistoryStreets: collapsed.isEmpty ? null : collapsed,
      foldedPlayers:
          _foldedPlayers.isEmpty ? null : List<int>.from(_foldedPlayers),
      actionTags:
          _actionTags.isEmpty ? null : Map<int, String?>.from(_actionTags),
      pendingEvaluations:
          _pendingEvaluations.isEmpty ? null : List<ActionEvaluationRequest>.from(_pendingEvaluations),
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
    _applySavedHand(hand);
  }

  void _applySavedHand(SavedHand hand) {
    setState(() {
      _currentHandName = hand.name;
      _playerManager.heroIndex = hand.heroIndex;
      _playerManager.heroPosition = hand.heroPosition;
      _playerManager.numberOfPlayers = hand.numberOfPlayers;
      for (int i = 0; i < _playerManager.playerCards.length; i++) {
        _playerManager.playerCards[i]
          ..clear()
          ..addAll(i < hand.playerCards.length ? hand.playerCards[i] : []);
      }
      _playerManager.boardCards
        ..clear()
        ..addAll(hand.boardCards);
      for (int i = 0; i < _playerManager.players.length; i++) {
        final list = _playerManager.players[i].revealedCards;
        list.fillRange(0, list.length, null);
        if (i < hand.revealedCards.length) {
          final from = hand.revealedCards[i];
          for (int j = 0; j < list.length && j < from.length; j++) {
            list[j] = from[j];
          }
        }
      }
      opponentIndex = hand.opponentIndex;
      activePlayerIndex = hand.activePlayerIndex;
      actions
        ..clear()
        ..addAll(hand.actions);
      _playerManager.initialStacks
        ..clear()
        ..addAll(hand.stackSizes);
      _stackService = StackManagerService(
        Map<int, int>.from(_playerManager.initialStacks),
        remainingStacks: hand.remainingStacks,
      );
      _playbackManager.stackService = _stackService;
      _playerManager.playerPositions
        ..clear()
        ..addAll(hand.playerPositions);
      _playerManager.playerTypes
        ..clear()
        ..addAll(hand.playerTypes ??
            {for (final k in hand.playerPositions.keys) k: PlayerType.unknown});
      _commentController.text = hand.comment ?? '';
      _tagsController.text = hand.tags.join(', ');
      _commentController.selection = TextSelection.collapsed(
          offset: hand.commentCursor != null &&
                  hand.commentCursor! <= _commentController.text.length
              ? hand.commentCursor!
              : _commentController.text.length);
      _tagsController.selection = TextSelection.collapsed(
          offset:
              hand.tagsCursor != null && hand.tagsCursor! <= _tagsController.text.length
                  ? hand.tagsCursor!
                  : _tagsController.text.length);
      _actionTags
        ..clear()
        ..addAll(hand.actionTags ?? {});
      _pendingEvaluations
        ..clear()
        ..addAll(hand.pendingEvaluations ?? []);
      _foldedPlayers
        ..clear()
        ..addAll(hand.foldedPlayers ??
            [for (final a in hand.actions) if (a.action == 'fold') a.playerIndex]);
      _expandedHistoryStreets
        ..clear()
        ..addAll([
          for (int i = 0; i < 4; i++)
            if (hand.collapsedHistoryStreets == null ||
                !hand.collapsedHistoryStreets!.contains(i))
              i
        ]);
      boardStreet = hand.boardStreet;
      currentStreet = hand.boardStreet;
      _ensureBoardStreetConsistent();
      _updateRevealedBoardCards();
      final seekIndex =
          hand.playbackIndex > hand.actions.length ? hand.actions.length : hand.playbackIndex;
      _playbackManager.seek(seekIndex);
      _playbackManager.animatedPlayersPerStreet.clear();
      _playbackManager.updatePlaybackState();
      _playerManager.updatePositions();
      if (hand.foldedPlayers == null) {
        _recomputeFoldedPlayers();
      }
    });
    _queueService.persist();
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

    setState(() {
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

      _updateRevealedBoardCards();

      actions
        ..clear()
        ..addAll(newActions);

      _recomputeFoldedPlayers();

      playerPositions
        ..clear()
        ..addAll(newPositions);

      currentStreet = 0;
      _updateRevealedBoardCards();
      _playbackManager.resetHand();
      _playbackManager.updatePlaybackState();
      _playerManager.updatePositions();
      _currentHandName = null;
    });
  }

  Future<void> saveCurrentHand() async {
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
    setState(() => _currentHandName = handName);
  }

  void loadLastSavedHand() {
    if (savedHands.isEmpty) return;
    final hand = savedHands.last;
    _applySavedHand(hand);
  }

  Future<void> loadHandByName() async {
    final selected = await _handManager.selectHand(context);
    if (selected != null) {
      _applySavedHand(selected);
    }
  }


  Future<void> exportLastSavedHand() async {
    await _handManager.exportLastHand(context);
  }

  Future<void> exportAllHands() async {
    await _handManager.exportAllHands(context);
  }

  Future<void> importHandFromClipboard() async {
    final hand = await _handManager.importHandFromClipboard(context);
    if (hand != null) {
      _applySavedHand(hand);
    }
  }

  Future<void> importAllHandsFromClipboard() async {
    await _handManager.importAllHandsFromClipboard(context);
  }



  @override
  void dispose() {
    _activeTimer?.cancel();
    _playerManager.removeListener(_onPlayerManagerChanged);
    _playbackManager.dispose();
    _centerChipTimer?.cancel();
    _queueService.cleanup();
    _centerChipController.dispose();
    _commentController.dispose();
    _tagsController.dispose();
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
        _stackService.calculateEffectiveStack(currentStreet, visibleActions);
    final currentStreetEffectiveStack = _stackService
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
              handName: _currentHandName ?? 'New Hand',
              playerCount: numberOfPlayers,
              streetName: ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'][currentStreet],
              onEdit: loadHandByName,
            ),
            _PlayerCountSelector(
              numberOfPlayers: numberOfPlayers,
              playerPositions: playerPositions,
              playerTypes: playerTypes,
              onChanged: _onPlayerCountChanged,
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
                  _BoardCardsSection(
                    scale: scale,
                    currentStreet: currentStreet,
                    boardCards: boardCards,
                    revealedBoardCards: revealedBoardCards,
                    onCardSelected: selectBoardCard,
                    canEditBoard: _canEditBoard,
                    visibleActions: visibleActions,
                  ),
                  _PlayerZonesSection(
                    numberOfPlayers: numberOfPlayers,
                    scale: scale,
                    playerPositions: playerPositions,
                    opponentCardRow: _OpponentCardRowSection(
                      scale: scale,
                      players: players,
                      activePlayerIndex: activePlayerIndex,
                      opponentIndex: opponentIndex,
                      onCardTap: _onOpponentCardTap,
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
                      setState(() {
                        if (_expandedHistoryStreets.contains(index)) {
                          _expandedHistoryStreets.remove(index);
                        } else {
                          _expandedHistoryStreets.add(index);
                        }
                      });
                    },
                  ),
                  _PerspectiveSwitchButton(
                    isPerspectiveSwitched: isPerspectiveSwitched,
                    onToggle: () => setState(
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
                _RevealAllCardsButton(
                  showAllRevealedCards: _showAllRevealedCards,
                  onToggle: () => setState(
                      () => _showAllRevealedCards = !_showAllRevealedCards),
                )
              ],
        ),
      ),
    ),
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
    ActionHistoryExpansionTile(
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
      onStreetChanged: (index) {
        setState(() {
          _recordSnapshot();
          currentStreet = index;
          _updateRevealedBoardCards();
          _actionTags.clear();
          _playbackManager.animatedPlayersPerStreet
              .putIfAbsent(index, () => <int>{});
          _updateRevealedBoardCards();
        });
              },
            ),
            StreetActionInputWidget(
              currentStreet: currentStreet,
              numberOfPlayers: numberOfPlayers,
              actions: actions,
              playerPositions: playerPositions,
              onAdd: onActionSelected,
              onEdit: _editAction,
              onDelete: _deleteAction,
            ),
            ActionTimelineWidget(
              actions: visibleActions,
              playbackIndex: _playbackManager.playbackIndex,
              onTap: (index) {
                setState(() {
                  _playbackManager.seek(index);
                  _playbackManager.updatePlaybackState(); // Перестраиваем экран
                });
              },
              playerPositions: playerPositions,
              scale: scale,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _PlaybackAndHandControls(
                isPlaying: _playbackManager.isPlaying,
                playbackIndex: _playbackManager.playbackIndex,
                actionCount: actions.length,
                onPlay: () => _playbackManager.startPlayback(),
                onPause: _playbackManager.pausePlayback,
                onStepBackward: _playbackManager.stepBackward,
                onStepForward: () => _playbackManager.stepForward(),
                onSeek: (v) {
                  _playbackManager.seek(v.round());
                },
                onSave: () => saveCurrentHand(),
                onLoadLast: loadLastSavedHand,
                onLoadByName: () => loadHandByName(),
                onExportLast: exportLastSavedHand,
                onExportAll: exportAllHands,
                onImport: importHandFromClipboard,
                onImportAll: importAllHandsFromClipboard,
                onReset: _resetHand,
              ),
            ),
            Expanded(
              child: _HandEditorSection(
                historyActions: visibleActions,
                playerPositions: playerPositions,
                heroIndex: heroIndex,
                commentController: _commentController,
                tagsController: _tagsController,
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
    final String tag = _actionTags[index] ?? '';
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
          child: PlayerInfoWidget(
            position: position,
            stack: stack,
            tag: tag,
            cards: _showAllRevealedCards &&
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
            isHero: index == _playerManager.heroIndex,
            isOpponent: index == opponentIndex,
            playerTypeIcon: '',
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
            onCardTap: (cardIndex) => _onPlayerCardTap(index, cardIndex),
            onTap: () => _onPlayerTap(index),
            onDoubleTap: () => setState(() {
              _playerManager.setHeroIndex(index);
            }),
            onLongPress: () => _editPlayerInfo(index),
            onEdit: () => _editPlayerInfo(index),
            onStackTap: (value) => setState(() {
              _playerManager.setInitialStack(index, value);
              _stackService =
                  StackManagerService(Map<int, int>.from(_playerManager.initialStacks));
              _playbackManager.stackService = _stackService;
              _playbackManager.updatePlaybackState();
            }),
            onRemove: _playerManager.numberOfPlayers > 2 ? () {
              _removePlayer(index);
            } : null,
            onTimeExpired: () => _onPlayerTimeExpired(index),
          ),
        ),
      ),
      Positioned(
        left: centerX + dx - 8 * scale,
        top: centerY + dy + bias - 70 * scale,
        child: _playerTypeIcon(_playerManager.playerTypes[index]),
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
            duration: const Duration(milliseconds: 300),
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

    if (debugLayout) {
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
  final void Function(int) onCardTap;

  const _OpponentCardRowSection({
    required this.scale,
    required this.players,
    required this.activePlayerIndex,
    required this.opponentIndex,
    required this.onCardTap,
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
              onTap: () => onCardTap(i),
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
      final invested = state.actions
          .where((a) =>
              a.playerIndex == index &&
              a.street == state.currentStreet &&
              (a.action == 'call' || a.action == 'bet' || a.action == 'raise') &&
              a.amount != null)
          .fold<int>(0, (sum, a) => sum + (a.amount ?? 0));
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
      final invested = state.actions
          .where((a) =>
              a.playerIndex == index &&
              a.street == state.currentStreet &&
              (a.action == 'call' || a.action == 'bet' || a.action == 'raise') &&
              a.amount != null)
          .fold<int>(0, (sum, a) => sum + (a.amount ?? 0));
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

class _BoardCardsSection extends StatelessWidget {
  final double scale;
  final int currentStreet;
  final List<CardModel> boardCards;
  final List<CardModel> revealedBoardCards;
  final List<ActionEntry> visibleActions;
  final void Function(int, CardModel) onCardSelected;
  final bool Function(int index)? canEditBoard;

  const _BoardCardsSection({
    required this.scale,
    required this.currentStreet,
    required this.boardCards,
    required this.revealedBoardCards,
    required this.onCardSelected,
    required this.visibleActions,
    this.canEditBoard,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: BoardDisplay(
        key: ValueKey(currentStreet),
        scale: scale,
        currentStreet: currentStreet,
        boardCards: boardCards,
        revealedBoardCards: revealedBoardCards,
        onCardSelected: onCardSelected,
        canEditBoard: canEditBoard,
        visibleActions: visibleActions,
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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous, color: Colors.white),
              onPressed: onStepBackward,
            ),
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: isPlaying ? onPause : onPlay,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white),
              onPressed: onStepForward,
            ),
            Expanded(
              child: Slider(
                value: playbackIndex.toDouble(),
                min: 0,
                max: actionCount > 0 ? actionCount.toDouble() : 1,
                onChanged: onSeek,
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

  const _SaveLoadControlsSection({
    required this.onSave,
    required this.onLoadLast,
    required this.onLoadByName,
    required this.onExportLast,
    required this.onExportAll,
    required this.onImport,
    required this.onImportAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.save, color: Colors.white),
          onPressed: onSave,
        ),
        IconButton(
          icon: const Icon(Icons.folder_open, color: Colors.white),
          onPressed: onLoadLast,
        ),
        IconButton(
          icon: const Icon(Icons.list, color: Colors.white),
          onPressed: onLoadByName,
        ),
        IconButton(
          icon: const Icon(Icons.upload, color: Colors.white),
          onPressed: onExportLast,
        ),
        IconButton(
          icon: const Icon(Icons.file_upload, color: Colors.white),
          onPressed: onExportAll,
        ),
        IconButton(
          icon: const Icon(Icons.download, color: Colors.white),
          onPressed: onImport,
        ),
        IconButton(
          icon: const Icon(Icons.file_download, color: Colors.white),
          onPressed: onImportAll,
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
  final ValueChanged<int> onChanged;

  const _PlayerCountSelector({
    required this.numberOfPlayers,
    required this.playerPositions,
    required this.playerTypes,
    required this.onChanged,
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
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
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
                  setState(() =>
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
              onChanged: (v) => setState(() => _isHero = v),
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
                          : (v) => setState(() => _card1 = v != null && _card1 != null
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
                          : (v) => setState(() => _card1 = v != null && _card1 != null
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
                          : (v) => setState(() => _card2 = v != null && _card2 != null
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
                          : (v) => setState(() => _card2 = v != null && _card2 != null
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
                  onChanged: (v) => setState(() => p = v ?? p),
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
                  onChanged: (v) => setState(() => act = v ?? act),
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
              onChanged: (v) => setState(() => _player = v ?? _player),
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
              onChanged: (v) => setState(() => _action = v ?? _action),
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

  Widget _btn(String label, VoidCallback? onPressed) {
    return ElevatedButton(onPressed: onPressed, child: Text(label));
  }

  Widget _buttonsWrap(Map<String, VoidCallback?> actions) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in actions.entries) _btn(entry.key, entry.value),
      ],
    );
  }

class _QueueTools extends StatelessWidget {
  const _QueueTools({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final _PokerAnalyzerScreenState s = state.s;
    final bool noQueues = s._pendingEvaluations.isEmpty &&
        s._failedEvaluations.isEmpty &&
        s._completedEvaluations.isEmpty;

    return state._buttonsWrap(<String, VoidCallback?>{
      'Import Evaluation Queue': s._importEvaluationQueue,
      'Restore Evaluation Queue': s._restoreEvaluationQueue,
      'Restore From Auto-Backup': s._restoreFromAutoBackup,
      'Bulk Import Evaluation Queue': s._bulkImportEvaluationQueue,
      'Bulk Import Backups': s._bulkImportEvaluationBackups,
      'Bulk Import Auto-Backups': s._bulkImportAutoBackups,
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
      'Import Quick Backups': s._importQuickBackups,
      'Export All Backups': s._exportAllEvaluationBackups,
      'Clear Pending':
          s._pendingEvaluations.isEmpty ? null : s._clearPendingQueue,
      'Clear Failed':
          s._failedEvaluations.isEmpty ? null : s._clearFailedQueue,
      'Clear Completed':
          s._completedEvaluations.isEmpty ? null : s._clearCompletedQueue,
      'Clear Evaluation Queue': s._pendingEvaluations.isEmpty &&
              s._completedEvaluations.isEmpty
          ? null
          : s._clearEvaluationQueue,
      'Remove Duplicates': noQueues ? null : s._removeDuplicateEvaluations,
      'Resolve Conflicts': noQueues ? null : s._resolveQueueConflicts,
      'Sort Queues': noQueues ? null : s._sortEvaluationQueues,
      'Clear Completed Evaluations':
          s._completedEvaluations.isEmpty ? null : s._clearCompletedEvaluations,
    });
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
          s._failedEvaluations.isEmpty ? null : s._retryFailedEvaluations,
      'Export Snapshot Now': s._processingEvaluations
          ? null
          : () => s._exportEvaluationQueueSnapshot(showNotification: true),
      'Backup Queue Now': s._processingEvaluations
          ? null
          : () async {
              await s._backupEvaluationQueue();
              s._debugPanelSetState?.call(() {});
            },
    });
  }
}

  Widget _buttonsColumn(Map<String, VoidCallback?> actions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in actions.entries) ...[
          Align(alignment: Alignment.centerLeft, child: _btn(entry.key, entry.value)),
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
            s.setState(() {});
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
            s.setState(() {});
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
    final disabled = s._pendingEvaluations.isEmpty;
    return state._buttonsWrap({
      'Process Next':
          disabled || s._processingEvaluations ? null : s._processNextEvaluation,
      'Start Evaluation Processing':
          disabled || s._processingEvaluations ? null : s._processEvaluationQueue,
      s._pauseProcessingRequested ? 'Resume' : 'Pause':
          disabled || !s._processingEvaluations ? null : s._toggleEvaluationProcessingPause,
      'Cancel Evaluation Processing':
          !s._processingEvaluations && disabled ? null : s._cancelEvaluationProcessing,
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
            s.setState(() {});
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
                s.setState(() {});
                s._debugPanelSetState?.call(() {});
              },
            ),
            CheckboxListTile(
              title: const Text('Only hands with opponent cards'),
              value: s._debugPrefs.advancedFilters.contains('opponent'),
              onChanged: (_) {
                s._debugPrefs.toggleAdvancedFilter('opponent');
                s.setState(() {});
                s._debugPanelSetState?.call(() {});
              },
            ),
            CheckboxListTile(
              title: const Text('Only failed evaluations'),
              value: s._debugPrefs.advancedFilters.contains('failed'),
              onChanged: (_) {
                s._debugPrefs.toggleAdvancedFilter('failed');
                s.setState(() {});
                s._debugPanelSetState?.call(() {});
              },
            ),
            CheckboxListTile(
              title: const Text('Only high SPR (>=3)'),
              value: s._debugPrefs.advancedFilters.contains('highspr'),
              onChanged: (_) {
                s._debugPrefs.toggleAdvancedFilter('highspr');
                s.setState(() {});
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
            s.setState(() {});
            s._debugPanelSetState?.call(() {});
          },
        ),
        _DebugPanelDialogState._vGap,
        Builder(
          builder: (context) {
            final sections = <Widget>[];
            if (s._debugPrefs.queueFilters.contains('pending')) {
              sections.add(state._queueSection('Pending', s._pendingEvaluations));
            }
            if (s._debugPrefs.queueFilters.contains('failed')) {
              sections.add(state._queueSection('Failed', s._failedEvaluations));
            }
            if (s._debugPrefs.queueFilters.contains('completed')) {
              sections.add(
                  state._queueSection('Completed', s._completedEvaluations));
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
    final results = s._completedEvaluations.length > 50
        ? s._completedEvaluations
            .sublist(s._completedEvaluations.length - 50)
        : s._completedEvaluations;
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
        debugDiag('Pending', s._pendingEvaluations.length),
        debugDiag('Failed', s._failedEvaluations.length),
        debugDiag('Completed', s._completedEvaluations.length),
        debugDiag('Total Processed',
            s._completedEvaluations.length + s._failedEvaluations.length),
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
    final int hudEffStack = s._stackService.calculateEffectiveStackForStreet(
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
        debugDiag('Pending Action Evaluations', s._pendingEvaluations.length),
        debugDiag(
          'Processed',
          '${s._completedEvaluations.length} / ${s._pendingEvaluations.length + s._completedEvaluations.length}',
        ),
        debugDiag('Failed', s._failedEvaluations.length),
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
        debugCheck('stackSizes', mapEquals(hand.stackSizes, s._initialStacks),
            hand.stackSizes.toString(), s._initialStacks.toString()),
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
        debugDiag('Debug Layout', s.debugLayout),
        _DebugPanelDialogState._vGap,
        debugDiag('Perspective Switched', s.isPerspectiveSwitched),
        _DebugPanelDialogState._vGap,
        debugDiag('Show All Revealed Cards', s._showAllRevealedCards),
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



  TextButton _dialogBtn(String label, VoidCallback onPressed) {
    return TextButton(onPressed: onPressed, child: Text(label));
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
                'Initial ${s._initialStacks[i] ?? 0}, '
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
                s._stackService.calculateEffectiveStackForStreet(
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
            if (s._actionTags.isNotEmpty)
              for (final entry in s._actionTags.entries) ...[
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
                      s.setState(() {});
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
        _dialogBtn('Export Evaluation Queue', s._exportEvaluationQueue),
        _dialogBtn('Export Full Queue State', s._exportFullEvaluationQueueState),
        _dialogBtn('Export Queue To Clipboard', s._exportQueueToClipboard),
        _dialogBtn('Import Queue From Clipboard', s._importQueueFromClipboard),
        _dialogBtn('Backup Evaluation Queue', s._backupEvaluationQueue),
        _dialogBtn('Export All Backups', s._exportAllEvaluationBackups),
        _dialogBtn('Export Auto-Backups', s._exportAutoBackups),
        _dialogBtn('Export Snapshots', s._exportSnapshots),
        _dialogBtn('Export All Snapshots', s._exportAllEvaluationSnapshots),
        _dialogBtn('Undo', s._undoAction),
        _dialogBtn('Redo', s._redoAction),
        _dialogBtn('Close', () => Navigator.pop(context)),
        _dialogBtn('Clear Evaluation Queue', s._clearEvaluationQueue),
        _dialogBtn('Reset Debug Panel Settings', s._resetDebugPanelPreferences),
      ],
    );
  }

