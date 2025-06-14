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
import '../helpers/debug_panel_preferences.dart';
part '../widgets/debug_panel.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/card_model.dart';
import '../models/action_entry.dart';
import '../widgets/player_zone_widget.dart';
import '../widgets/street_actions_widget.dart';
import '../widgets/board_display.dart';
import '../widgets/action_history_overlay.dart';
import '../widgets/collapsible_action_history.dart';
import '../widgets/action_history_expansion_tile.dart';
import 'package:provider/provider.dart';
import '../services/saved_hand_storage_service.dart';
import '../theme/constants.dart';
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
import '../helpers/stack_manager.dart';
import '../helpers/date_utils.dart';
import '../widgets/evaluation_request_tile.dart';
import '../helpers/debug_helpers.dart';

class PokerAnalyzerScreen extends StatefulWidget {
  final SavedHand? initialHand;

  const PokerAnalyzerScreen({super.key, this.initialHand});

  @override
  State<PokerAnalyzerScreen> createState() => _PokerAnalyzerScreenState();
}

class _PokerAnalyzerScreenState extends State<PokerAnalyzerScreen>
    with TickerProviderStateMixin {
  late SavedHandStorageService _savedHandService;
  List<SavedHand> get savedHands => _savedHandService.hands;
  int heroIndex = 0;
  String _heroPosition = 'BTN';
  int numberOfPlayers = 6;
  final List<List<CardModel>> playerCards = List.generate(10, (_) => []);
  final List<CardModel> boardCards = [];
  final List<PlayerModel> players =
      List.generate(10, (i) => PlayerModel(name: 'Player ${i + 1}'));
  int? opponentIndex;
  int currentStreet = 0;
  final List<ActionEntry> actions = [];
  int _playbackIndex = 0;
  bool _isPlaying = false;
  Timer? _playbackTimer;
  final List<int> _pots = List.filled(4, 0);
  final PotCalculator _potCalculator = PotCalculator();
  final Map<int, int> _initialStacks = {
    0: 120,
    1: 80,
    2: 100,
    3: 90,
    4: 110,
    5: 70,
    6: 130,
    7: 95,
    8: 105,
    9: 100,
  };
  final Map<int, int> stackSizes = {};
  late StackManager _stackManager;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  Set<String> get allTags =>
      savedHands.expand((hand) => hand.tags).toSet();
  Set<String> tagFilters = {};
  final List<bool> _showActionHints = List.filled(10, true);
  final Set<int> _firstActionTaken = {};
  int? activePlayerIndex;
  int? lastActionPlayerIndex;
  Timer? _activeTimer;
  final Map<int, String?> _actionTags = {};
  Map<int, String> playerPositions = {};
  Map<int, PlayerType> playerTypes = {};

  bool debugLayout = false;
  bool _isDebugPanelOpen = false;
  final Set<int> _expandedHistoryStreets = {};
  final Map<int, Set<int>> _animatedPlayersPerStreet = {};

  ActionEntry? _centerChipAction;
  bool _showCenterChip = false;
  Timer? _centerChipTimer;
  late AnimationController _centerChipController;
  bool _showAllRevealedCards = false;
  bool isPerspectiveSwitched = false;

  /// Stores effective stacks loaded from a saved hand's export data.
  Map<String, int>? _savedEffectiveStacks;

  /// Validation notes loaded from a saved hand's export data.
  Map<String, String>? _validationNotes;

  String? _expectedAction;
  String? _feedbackText;

  /// Queue of pending action evaluation tasks.
  final List<ActionEvaluationRequest> _pendingEvaluations = [];

  /// Completed action evaluations.
  final List<ActionEvaluationRequest> _completedEvaluations = [];

  /// Evaluations that failed during processing.
  final List<ActionEvaluationRequest> _failedEvaluations = [];

  /// Timer for automatic periodic backups of the evaluation queue.
  Timer? _autoBackupTimer;

  /// Prevents overlapping automatic backups.
  bool _autoBackupRunning = false;

  /// Indicates if evaluation processing is currently running.
  bool _processingEvaluations = false;

  /// True when a pause of the evaluation processing loop has been requested.
  bool _pauseProcessingRequested = false;

  /// True when a cancellation of the evaluation processing loop has been requested.
  bool _cancelProcessingRequested = false;

  /// Whether the evaluation queue was restored from disk on startup.
  bool _evaluationQueueResumed = false;

  /// Allows updating the debug panel while it's open.
  StateSetter? _debugPanelSetState;

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
  final DebugPanelPreferences _prefs = DebugPanelPreferences();
  bool _snapshotRetentionEnabled = true;

  int _evaluationProcessingDelay = 500;

  Set<String> _queueFilters = {'pending'};
  /// Active advanced debug filters for evaluation queue display.
  Set<String> _advancedFilters = {};

  /// Whether to sort evaluation lists by SPR when displayed in the debug panel.
  bool _sortBySpr = false;

  /// Current search query for filtering evaluation queues in the debug panel.
  String _searchQuery = '';

  static const _pendingOrderKey = 'pending_queue_order';
  static const _failedOrderKey = 'failed_queue_order';
  static const _completedOrderKey = 'completed_queue_order';
  static const _queueResumedKey = 'evaluation_queue_resumed';

  Future<void> _loadSnapshotRetentionPreference() async {
    final value = await _prefs.getSnapshotRetentionEnabled();
    if (mounted) {
      setState(() {
        _snapshotRetentionEnabled = value;
      });
    } else {
      _snapshotRetentionEnabled = value;
    }
    if (_snapshotRetentionEnabled) {
      await _cleanupOldEvaluationSnapshots();
    }
  }

  Future<void> _setSnapshotRetentionEnabled(bool value) async {
    await _prefs.setSnapshotRetentionEnabled(value);
    if (mounted) {
      setState(() => _snapshotRetentionEnabled = value);
    } else {
      _snapshotRetentionEnabled = value;
    }
    if (value) {
      await _cleanupOldEvaluationSnapshots();
    }
    _debugPanelSetState?.call(() {});
  }

  Future<void> _loadProcessingDelayPreference() async {
    final value = await _prefs.getProcessingDelay();
    if (mounted) {
      setState(() {
        _evaluationProcessingDelay = value;
      });
    } else {
      _evaluationProcessingDelay = value;
    }
  }

  Future<void> _setProcessingDelay(int value) async {
    await _prefs.setProcessingDelay(value);
    if (mounted) {
      setState(() => _evaluationProcessingDelay = value);
    } else {
      _evaluationProcessingDelay = value;
    }
    _debugPanelSetState?.call(() {});
  }

  Future<void> _loadQueueFilterPreference() async {
    final loaded = await _prefs.getQueueFilters();
    if (mounted) {
      setState(() {
        _queueFilters = loaded;
      });
    } else {
      _queueFilters = loaded;
    }
  }

  Future<void> _setQueueFilters(Set<String> value) async {
    await _prefs.setQueueFilters(value);
    if (mounted) {
      setState(() => _queueFilters = value);
    } else {
      _queueFilters = value;
    }
    _debugPanelSetState?.call(() {});
  }

  void _toggleQueueFilter(String filter) {
    final updated = Set<String>.from(_queueFilters);
    if (updated.contains(filter)) {
      updated.remove(filter);
    } else {
      updated.add(filter);
    }
    _setQueueFilters(updated);
  }

  Future<void> _loadAdvancedFilterPreference() async {
    final loaded = await _prefs.getAdvancedFilters();
    if (mounted) {
      setState(() => _advancedFilters = loaded);
    } else {
      _advancedFilters = loaded;
    }
  }

  Future<void> _setAdvancedFilters(Set<String> value) async {
    await _prefs.setAdvancedFilters(value);
    if (mounted) {
      setState(() => _advancedFilters = value);
    } else {
      _advancedFilters = value;
    }
    _debugPanelSetState?.call(() {});
  }

  void _toggleAdvancedFilter(String filter) {
    final updated = Set<String>.from(_advancedFilters);
    if (updated.contains(filter)) {
      updated.remove(filter);
    } else {
      updated.add(filter);
    }
    _setAdvancedFilters(updated);
  }

  Future<void> _loadSearchQueryPreference() async {
    final value = await _prefs.getSearchQuery();
    if (mounted) {
      setState(() => _searchQuery = value);
    } else {
      _searchQuery = value;
    }
  }

  Future<void> _loadSortBySprPreference() async {
    final value = await _prefs.getSortBySpr();
    if (mounted) {
      setState(() => _sortBySpr = value);
    } else {
      _sortBySpr = value;
    }
  }

  void _setSortBySpr(bool value) {
    _prefs.setSortBySpr(value);
    if (mounted) {
      setState(() => _sortBySpr = value);
    } else {
      _sortBySpr = value;
    }
    _debugPanelSetState?.call(() {});
  }

  void _setSearchQuery(String value) {
    _prefs.setSearchQuery(value);
    if (mounted) {
      setState(() => _searchQuery = value);
    } else {
      _searchQuery = value;
    }
    _debugPanelSetState?.call(() {});
  }

  Future<void> _resetDebugPanelPreferences() async {
    await _prefs.clearAll();
    await _loadSnapshotRetentionPreference();
    await _loadProcessingDelayPreference();
    await _loadQueueFilterPreference();
    await _loadAdvancedFilterPreference();
    await _loadSortBySprPreference();
    await _loadSearchQueryPreference();
    _debugPanelSetState?.call(() {});
  }

  List<ActionEvaluationRequest> _applyAdvancedFilters(
      List<ActionEvaluationRequest> list) {
    final filters = _advancedFilters;
    final sort = _sortBySpr;
    final search = _searchQuery.trim().toLowerCase();
    if (filters.isEmpty && !sort && search.isEmpty) return list;

    final checkFeedback = filters.contains('feedback');
    final checkOpponent = filters.contains('opponent');
    final checkFailed = filters.contains('failed');
    final checkHighSpr = filters.contains('highspr');
    final searchActive = search.isNotEmpty;

    final shouldFilter =
        checkFeedback ||
            checkOpponent ||
            checkFailed ||
            checkHighSpr ||
            searchActive;

    if (!shouldFilter && !sort) {
      return list;
    }

    bool matches(ActionEvaluationRequest r) {
      final md = r.metadata;

      if (checkFeedback) {
        final text = md?['feedbackText'] as String?;
        if (text == null || text.isEmpty) return false;
      }

      if (checkOpponent && ((md?['opponentCards'] as List?)?.isEmpty ?? true)) {
        return false;
      }

      if (checkFailed && md?['status'] != 'failed') return false;

      if (checkHighSpr) {
        final spr = (md?['spr'] as num?)?.toDouble();
        if (spr == null || spr < 3) return false;
      }

      if (searchActive) {
        final feedback = (md?['feedbackText'] as String?) ?? '';
        final id = r.id;
        if (!id.toLowerCase().contains(search) &&
            !feedback.toLowerCase().contains(search)) {
          return false;
        }
      }

      return true;
    }

    final filtered = <ActionEvaluationRequest>[];
    var modified = false;
    for (final r in list) {
      if (matches(r)) {
        filtered.add(r);
      } else {
        modified = true;
      }
    }

    var result = modified ? filtered : list;

    if (sort) {
      final sorted = List<ActionEvaluationRequest>.from(result);
      sorted.sort((a, b) {
        final sa = (a.metadata?['spr'] as num?)?.toDouble() ?? -double.infinity;
        final sb = (b.metadata?['spr'] as num?)?.toDouble() ?? -double.infinity;
        return sb.compareTo(sa);
      });
      result = sorted;
    }

    return result;
  }

  Future<void> _loadQueueResumedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_queueResumedKey) ?? false;
    if (mounted) {
      setState(() => _evaluationQueueResumed = value);
    } else {
      _evaluationQueueResumed = value;
    }
  }

  Future<void> _setEvaluationQueueResumed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_queueResumedKey, value);
    if (mounted) {
      setState(() => _evaluationQueueResumed = value);
    } else {
      _evaluationQueueResumed = value;
    }
    _debugPanelSetState?.call(() {});
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
    final filtered = _applyAdvancedFilters(queue);
    return debugQueueSection(label, filtered,
        _advancedFilters.isEmpty && !_sortBySpr && _searchQuery.isEmpty
            ? (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex -= 1;
                setState(() {
                  final item = queue.removeAt(oldIndex);
                  queue.insert(newIndex, item);
                });
                _persistEvaluationQueue();
                _debugPanelSetState?.call(() {});
              }
            : (_, __) {});
  }


  List<String> _positionsForPlayers(int count) {
    return getPositionList(count);
  }

  void setPosition(int playerIndex, String position) {
    setState(() {
      playerPositions[playerIndex] = position;
    });
  }

  void _updatePositions() {
    final order = _positionsForPlayers(numberOfPlayers);
    final heroPosIndex = order.indexOf(_heroPosition);
    final buttonIndex =
        (heroIndex - heroPosIndex + numberOfPlayers) % numberOfPlayers;
    playerPositions = {};
    for (int i = 0; i < numberOfPlayers; i++) {
      final posIndex = (i - buttonIndex + numberOfPlayers) % numberOfPlayers;
      if (posIndex < order.length) {
        playerPositions[i] = order[posIndex];
      }
    }
  }

  String _positionLabelForIndex(int index) {
    final pos = playerPositions[index];
    if (pos == null) return '';
    if (pos.startsWith('UTG')) return 'UTG';
    if (pos == 'HJ' || pos == 'MP') return 'MP';
    return pos;
  }


  double _verticalBiasFromAngle(double angle) {
    return 90 + 20 * sin(angle);
  }

  double _tableScale() {
    final extraPlayers = max(0, numberOfPlayers - 6);
    return (1.0 - extraPlayers * 0.05).clamp(0.75, 1.0);
  }

  double _centerYOffset(double scale) {
    double base;
    if (numberOfPlayers > 6) {
      base = 200.0 + (numberOfPlayers - 6) * 10.0;
    } else {
      base = 140.0 - (6 - numberOfPlayers) * 10.0;
    }
    return base * scale;
  }

  double _radiusModifier() {
    return (1 + (6 - numberOfPlayers) * 0.05).clamp(0.8, 1.2);
  }

  int _viewIndex() {
    if (isPerspectiveSwitched && opponentIndex != null) {
      return opponentIndex!;
    }
    return heroIndex;
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
    final double scale = _tableScale();
    final screen = MediaQuery.of(context).size;
    final tableWidth = screen.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screen.width / 2 + 10;
    final centerY = screen.height / 2 - _centerYOffset(scale);
    final radiusMod = _radiusModifier();
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;
    final i =
        (entry.playerIndex - _viewIndex() + numberOfPlayers) % numberOfPlayers;
    final angle = 2 * pi * i / numberOfPlayers + pi / 2;
    final dx = radiusX * cos(angle);
    final dy = radiusY * sin(angle);
    final bias = _verticalBiasFromAngle(angle) * scale;
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

  String _formatAmount(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'fold':
        return Colors.red[700]!;
      case 'call':
        return Colors.blue[700]!;
      case 'raise':
        return Colors.green[600]!;
      case 'bet':
        return Colors.amber[700]!;
      case 'all-in':
        return Colors.purpleAccent;
      case 'check':
        return Colors.grey[700]!;
      default:
        return Colors.black;
    }
  }

  Color _actionTextColor(String action) {
    switch (action) {
      case 'bet':
        return Colors.black;
      default:
        return Colors.white;
    }
  }

  IconData? _actionIcon(String action) {
    switch (action) {
      case 'fold':
        return Icons.close;
      case 'call':
        return Icons.call;
      case 'raise':
        return Icons.arrow_upward;
      case 'bet':
        return Icons.trending_up;
      case 'all-in':
        return Icons.flash_on;
      case 'check':
        return Icons.remove;
      default:
        return null;
    }
  }

  String _actionLabel(ActionEntry entry) {
    return entry.amount != null
        ? '${entry.action} ${entry.amount}'
        : entry.action;
  }

  String _formatLastAction(ActionEntry entry) {
    final a = entry.action;
    final cap = a.isNotEmpty ? a[0].toUpperCase() + a.substring(1) : a;
    return entry.amount != null ? '$cap ${entry.amount}' : cap;
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
    final stackController =
        TextEditingController(text: (_initialStacks[index] ?? 0).toString());
    PlayerType type = playerTypes[index] ?? PlayerType.unknown;
    bool isHeroSelected = index == heroIndex;
    CardModel? card1 =
        playerCards[index].isNotEmpty ? playerCards[index][0] : null;
    CardModel? card2 =
        playerCards[index].length > 1 ? playerCards[index][1] : null;
    final disableCards = index != heroIndex;

    const ranks = ['A', 'K', 'Q', 'J', 'T', '9', '8', '7', '6', '5', '4', '3', '2'];
    const suits = ['♠', '♥', '♦', '♣'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('Edit Player', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: stackController,
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
                    value: type.name,
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
                    onChanged: (v) => setState(() =>
                        type = PlayerType.values.firstWhere(
                          (e) => e.name == v,
                          orElse: () => PlayerType.unknown,
                        )),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: isHeroSelected,
                    title: const Text('Hero', style: TextStyle(color: Colors.white)),
                    onChanged: (v) => setState(() => isHeroSelected = v),
                    activeColor: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          DropdownButton<String>(
                            value: card1?.rank,
                            hint: const Text('Rank', style: TextStyle(color: Colors.white54)),
                            dropdownColor: Colors.grey[900],
                            items: ranks
                                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                .toList(),
                            onChanged: disableCards
                                ? null
                                : (v) => setState(() => card1 = v != null && card1 != null
                                    ? CardModel(rank: v, suit: card1!.suit)
                                    : (v != null ? CardModel(rank: v, suit: suits.first) : null)),
                          ),
                          DropdownButton<String>(
                            value: card1?.suit,
                            hint: const Text('Suit', style: TextStyle(color: Colors.white54)),
                            dropdownColor: Colors.grey[900],
                            items: suits
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: disableCards
                                ? null
                                : (v) => setState(() => card1 = v != null && card1 != null
                                    ? CardModel(rank: card1!.rank, suit: v)
                                    : (v != null ? CardModel(rank: ranks.first, suit: v) : null)),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          DropdownButton<String>(
                            value: card2?.rank,
                            hint: const Text('Rank', style: TextStyle(color: Colors.white54)),
                            dropdownColor: Colors.grey[900],
                            items: ranks
                                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                .toList(),
                            onChanged: disableCards
                                ? null
                                : (v) => setState(() => card2 = v != null && card2 != null
                                    ? CardModel(rank: v, suit: card2!.suit)
                                    : (v != null ? CardModel(rank: v, suit: suits.first) : null)),
                          ),
                          DropdownButton<String>(
                            value: card2?.suit,
                            hint: const Text('Suit', style: TextStyle(color: Colors.white54)),
                            dropdownColor: Colors.grey[900],
                            items: suits
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: disableCards
                                ? null
                                : (v) => setState(() => card2 = v != null && card2 != null
                                    ? CardModel(rank: card2!.rank, suit: v)
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
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('OK'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true) {
      final int newStack =
          int.tryParse(stackController.text) ?? _initialStacks[index] ?? 0;
      setState(() {
        _initialStacks[index] = newStack;
        playerTypes[index] = type;
        if (isHeroSelected) {
          heroIndex = index;
        } else if (heroIndex == index) {
          heroIndex = 0;
        }
        if (!disableCards) {
          final cards = <CardModel>[];
          if (card1 != null) cards.add(card1!);
          if (card2 != null) cards.add(card2!);
          playerCards[index] = cards;
        }
        _stackManager = StackManager(Map<int, int>.from(_initialStacks));
        _updatePlaybackState();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _centerChipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _stackManager = StackManager(Map<int, int>.from(_initialStacks));
    stackSizes.addAll(_stackManager.currentStacks);
    playerPositions = Map.fromIterables(
      List.generate(numberOfPlayers, (i) => i),
      getPositionList(numberOfPlayers),
    );
    playerTypes = Map.fromIterables(
      List.generate(numberOfPlayers, (i) => i),
      List.filled(numberOfPlayers, PlayerType.unknown),
    );
    _updatePositions();
    _updatePlaybackState();
    if (widget.initialHand != null) {
      _applySavedHand(widget.initialHand!);
    }
    Future(() => _cleanupOldEvaluationBackups());
    Future(() => _loadSnapshotRetentionPreference());
    Future(() => _loadProcessingDelayPreference());
    Future(() => _loadQueueFilterPreference());
    Future(() => _loadAdvancedFilterPreference());
    Future(() => _loadSearchQueryPreference());
    Future(() => _loadSortBySprPreference());
    Future(() => _loadQueueResumedPreference());
    Future.microtask(_loadSavedEvaluationQueue);
    Future(() => _cleanupOldAutoBackups());
    _startAutoBackupTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _savedHandService = context.read<SavedHandStorageService>();
  }

  void selectCard(int index, CardModel card) {
    setState(() {
      for (final cards in playerCards) {
        cards.removeWhere((c) => c == card);
      }
      boardCards.removeWhere((c) => c == card);
      _removeFromRevealedCards(card);
      if (playerCards[index].length < 2) {
        playerCards[index].add(card);
      }
    });
  }

  Future<void> _onPlayerCardTap(int index, int cardIndex) async {
    final selectedCard = await showCardSelector(context);
    if (selectedCard == null) return;
    setState(() {
      for (final cards in playerCards) {
        cards.removeWhere((c) => c == selectedCard);
      }
      boardCards.removeWhere((c) => c == selectedCard);
      _removeFromRevealedCards(selectedCard);
      if (playerCards[index].length > cardIndex) {
        playerCards[index][cardIndex] = selectedCard;
      } else if (playerCards[index].length == cardIndex) {
        playerCards[index].add(selectedCard);
      }
    });
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
    setState(() {
      for (final cards in playerCards) {
        cards.removeWhere((c) => c == selected);
      }
      boardCards.removeWhere((c) => c == selected);
      _removeFromRevealedCards(selected);
      final list = players[playerIndex].revealedCards;
      list[cardIndex] = selected;
    });
  }

  void selectBoardCard(int index, CardModel card) {
    setState(() {
      for (final cards in playerCards) {
        cards.removeWhere((c) => c == card);
      }
      boardCards.removeWhere((c) => c == card);
      _removeFromRevealedCards(card);
      if (index < boardCards.length) {
        boardCards[index] = card;
      } else if (index == boardCards.length) {
        boardCards.add(card);
      }
    });
  }

  void _removeFromRevealedCards(CardModel card) {
    for (final player in players) {
      for (int i = 0; i < player.revealedCards.length; i++) {
        if (player.revealedCards[i] == card) {
          player.revealedCards[i] = null;
        }
      }
    }
  }


  bool _streetHasBet({List<ActionEntry>? fromActions}) {
    final list = fromActions ?? actions;
    return list
        .where((a) => a.street == currentStreet)
        .any((a) => a.action == 'bet' || a.action == 'raise');
  }

  void _updatePots({List<ActionEntry>? fromActions}) {
    final list = fromActions ?? actions;
    final investments = StreetInvestments();
    for (final a in list) {
      investments.addAction(a);
    }
    final pots = _potCalculator.calculatePots(list, investments);
    for (int i = 0; i < _pots.length; i++) {
      _pots[i] = pots[i];
    }
  }

  int _calculateEffectiveStack({List<ActionEntry>? fromActions}) {
    final list = fromActions ?? actions;
    int? minStack;
    for (final entry in stackSizes.entries) {
      final index = entry.key;
      final folded = list.any((a) =>
          a.playerIndex == index && a.action == 'fold' && a.street <= currentStreet);
      if (folded) continue;
      final stack = entry.value;
      if (minStack == null || stack < minStack) {
        minStack = stack;
      }
    }
    return minStack ?? 0;
  }

  /// Calculates the effective stack size at the end of [street].
  ///
  /// For each active player their initial stack is reduced by the total
  /// amount invested up to and including the given [street]. Folded players
  /// (before or on this street) are ignored. The smallest remaining stack
  /// among all active players is returned.
  int _calculateEffectiveStackForStreet(int street) {
    final visibleActions = actions.take(_playbackIndex).toList();
    int? minStack;
    for (int index = 0; index < numberOfPlayers; index++) {
      final folded = visibleActions.any((a) =>
          a.playerIndex == index && a.action == 'fold' && a.street <= street);
      if (folded) continue;

      final initial = _initialStacks[index] ?? 0;
      int invested = 0;
      for (int s = 0; s <= street; s++) {
        invested += _stackManager.getInvestmentForStreet(index, s);
      }
      final remaining = initial - invested;

      if (minStack == null || remaining < minStack) {
        minStack = remaining;
      }
    }
    return minStack ?? 0;
  }

  /// Calculates the effective stack size for every street and returns a map
  /// with human-readable street names as keys.
  ///
  /// This helper does not update any UI and can be used for exporting data or
  /// further analytics.
  Map<String, int> calculateEffectiveStacksPerStreet() {
    const streetNames = ['Preflop', 'Flop', 'Turn', 'River'];
    final Map<String, int> stacks = {};
    for (int street = 0; street < streetNames.length; street++) {
      stacks[streetNames[street]] = _calculateEffectiveStackForStreet(street);
    }
    return stacks;
  }


  void _updatePlaybackState() {
    final subset = actions.take(_playbackIndex).toList();
    if (_playbackIndex == 0) {
      _animatedPlayersPerStreet.clear();
    }
    _stackManager.applyActions(subset);
    stackSizes
      ..clear()
      ..addAll(_stackManager.currentStacks);
    _updatePots(fromActions: subset);
    lastActionPlayerIndex =
        subset.isNotEmpty ? subset.last.playerIndex : null;
  }

  void _updateVisibleActions() {
    _updatePlaybackState();
  }

  void _clearEvaluationQueue() {
    setState(() {
      _pendingEvaluations.clear();
      _completedEvaluations.clear();
      _failedEvaluations.clear();
    });
    _persistEvaluationQueue();
    unawaited(_setEvaluationQueueResumed(false));
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
    _persistEvaluationQueue();
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
    _persistEvaluationQueue();
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
    _persistEvaluationQueue();
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
    _persistEvaluationQueue();
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
        _persistEvaluationQueue();
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
        _persistEvaluationQueue();
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
      _persistEvaluationQueue();
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
      _processEvaluationQueue();
    }
  }

  void _cancelEvaluationProcessing() {
    setState(() {
      _cancelProcessingRequested = true;
      _pauseProcessingRequested = false;
      _pendingEvaluations.clear();
      _processingEvaluations = false;
    });
    _persistEvaluationQueue();
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
      _processEvaluationQueue();
    }
  }

  void _retryFailedEvaluations() {
    setState(() {
      if (_failedEvaluations.isNotEmpty) {
        for (final r in _failedEvaluations) {
          r.attempts = 0;
        }
        _pendingEvaluations.insertAll(0, _failedEvaluations);
        _failedEvaluations.clear();
      }
    });
    _persistEvaluationQueue();
    _debugPanelSetState?.call(() {});
  }

  void _playStepForward() {
    if (_playbackIndex < actions.length) {
      setState(() {
        _playbackIndex++;
      });
      _updatePlaybackState();
    } else {
      _pausePlayback();
    }
  }

  void _pausePlayback() {
    _playbackTimer?.cancel();
    _isPlaying = false;
  }

  void _startPlayback() {
    _pausePlayback();
    setState(() {
      _isPlaying = true;
      if (_playbackIndex == actions.length) {
        _playbackIndex = 0;
      }
    });
    _updatePlaybackState();
    _playbackTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _playStepForward());
  }

  void _stepForward() {
    _pausePlayback();
    _playStepForward();
  }

  void _stepBackward() {
    _pausePlayback();
    if (_playbackIndex > 0) {
      setState(() {
        _playbackIndex--;
      });
      _updatePlaybackState();
    }
  }

  void _addAutoFolds(ActionEntry entry) {
    final street = entry.street;
    final ordered =
        List.generate(numberOfPlayers, (i) => (i + heroIndex) % numberOfPlayers);
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
      inserted = true;
    }
    if (inserted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пропущенные игроки сброшены в пас.')),
      );
    }
  }

  void _addAction(ActionEntry entry) {
    actions.add(entry);
    lastActionPlayerIndex = entry.playerIndex;
    _actionTags[entry.playerIndex] =
        '${entry.action}${entry.amount != null ? ' ${entry.amount}' : ''}';
    setPlayerLastAction(
      players[entry.playerIndex].name,
      _formatLastAction(entry),
      _actionColor(entry.action),
      entry.amount,
    );
    _triggerCenterChip(entry);
    _playUnifiedChipAnimation(entry);
    _updatePlaybackState();
  }

  void onActionSelected(ActionEntry entry) {
    setState(() {
      _addAutoFolds(entry);
      _addAction(entry);
    });
  }

  void _updateAction(int index, ActionEntry entry) {
    actions[index] = entry;
    if (index == actions.length - 1) {
      lastActionPlayerIndex = entry.playerIndex;
    }
    _actionTags[entry.playerIndex] =
        '${entry.action}${entry.amount != null ? ' ${entry.amount}' : ''}';
    setPlayerLastAction(
      players[entry.playerIndex].name,
      _formatLastAction(entry),
      _actionColor(entry.action),
      entry.amount,
    );
    _triggerCenterChip(entry);
    _playUnifiedChipAnimation(entry);
    _updatePlaybackState();
  }

  void _editAction(int index, ActionEntry entry) {
    setState(() {
      _updateAction(index, entry);
    });
  }


  void _deleteAction(int index) {
    setState(() {
      final removed = actions.removeAt(index);
      lastActionPlayerIndex = actions.isNotEmpty ? actions.last.playerIndex : null;
      if (_playbackIndex > actions.length) {
        _playbackIndex = actions.length;
      }
      // Update action tag for player whose action was removed
      try {
        final last = actions.lastWhere((a) => a.playerIndex == removed.playerIndex);
        _actionTags[removed.playerIndex] =
            '${last.action}${last.amount != null ? ' ${last.amount}' : ''}';
      } catch (_) {
        _actionTags.remove(removed.playerIndex);
      }
      _updatePlaybackState();
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
      _deleteAction(actionIndex);
    }
  }

  Future<void> _removePlayer(int index) async {
    if (numberOfPlayers <= 2) return;

    int updatedHeroIndex = heroIndex;

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
              for (int i = 0; i < numberOfPlayers; i++)
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
      heroIndex = updatedHeroIndex;
      // Remove actions for this player and adjust indices
      actions.removeWhere((a) => a.playerIndex == index);
      for (int i = 0; i < actions.length; i++) {
        final a = actions[i];
        if (a.playerIndex > index) {
          actions[i] = ActionEntry(
            a.street,
            a.playerIndex - 1,
            a.action,
            amount: a.amount,
            generated: a.generated,
          );
        }
      }
      // Shift player-specific data
      for (int i = index; i < numberOfPlayers - 1; i++) {
        playerCards[i] = playerCards[i + 1];
        players[i] = players[i + 1];
        _initialStacks[i] = _initialStacks[i + 1] ?? 0;
        _actionTags[i] = _actionTags[i + 1];
        playerPositions[i] = playerPositions[i + 1] ?? '';
        playerTypes[i] = playerTypes[i + 1] ?? PlayerType.unknown;
        _showActionHints[i] = _showActionHints[i + 1];
      }
      playerCards[numberOfPlayers - 1] = [];
      players[numberOfPlayers - 1] = PlayerModel(name: 'Player ${numberOfPlayers}');
      _initialStacks.remove(numberOfPlayers - 1);
      _actionTags.remove(numberOfPlayers - 1);
      playerPositions.remove(numberOfPlayers - 1);
      playerTypes.remove(numberOfPlayers - 1);
      _showActionHints[numberOfPlayers - 1] = true;

      if (heroIndex == index) {
        heroIndex = 0;
      } else if (heroIndex > index) {
        heroIndex--;
      }
      if (opponentIndex != null) {
        if (opponentIndex == index) {
          opponentIndex = null;
        } else if (opponentIndex! > index) {
          opponentIndex = opponentIndex! - 1;
        }
      }

      numberOfPlayers--;
      _updatePositions();
      if (_playbackIndex > actions.length) {
        _playbackIndex = actions.length;
      }
      _stackManager = StackManager(Map<int, int>.from(_initialStacks));
      _updatePlaybackState();
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
        for (final list in playerCards) {
          list.clear();
        }
        boardCards.clear();
        for (final p in players) {
          p.revealedCards.fillRange(0, p.revealedCards.length, null);
        }
        opponentIndex = null;
        actions.clear();
        currentStreet = 0;
        _actionTags.clear();
        _firstActionTaken.clear();
        _animatedPlayersPerStreet.clear();
        lastActionPlayerIndex = null;
        _playbackIndex = 0;
        _stackManager = StackManager(Map<int, int>.from(_initialStacks));
        _updatePlaybackState();
        playerTypes.clear();
        for (int i = 0; i < _showActionHints.length; i++) {
          _showActionHints[i] = true;
        }
        _commentController.clear();
        _tagsController.clear();
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
    if (_pendingEvaluations.isEmpty) return;
    try {
      final dir = await _getBackupDirectory(_exportsFolder);
      final fileName = 'evaluation_queue_${_timestamp()}.json';
      final file = File('${dir.path}/$fileName');
      final data = [for (final e in _pendingEvaluations) e.toJson()];
      await _writeJsonFile(file, data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Файл сохранён: $fileName'),
          action: SnackBarAction(
            label: 'Открыть',
            onPressed: () => OpenFile.open(file.path),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось экспортировать очередь')),
      );
    }
  }

  Future<void> _exportFullEvaluationQueueState() async {
    try {
      final exportDir = await _getBackupDirectory(_exportsFolder);
      final fileName = 'queue_export_${_timestamp()}.json';
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Full Queue State',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        initialDirectory: exportDir.path,
      );
      if (savePath == null) return;

      final file = File(savePath);
      await _writeJsonFile(file, _currentQueueState());

      if (!mounted) return;
      final name = savePath.split(Platform.pathSeparator).last;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Queue exported: $name')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export queue')),
        );
      }
    }
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
      _persistEvaluationQueue();
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
      _persistEvaluationQueue();
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
    if (_pendingEvaluations.isEmpty) return;
    try {
      final backupDir = await _getBackupDirectory(_backupsFolder);
      final fileName = 'evaluation_backup_${_timestamp()}.json';
      final file = File('${backupDir.path}/$fileName');
      await _writeJsonFile(file, _currentQueueState());

      // Run cleanup in the background to avoid blocking UI.
      Future(() => _cleanupOldEvaluationBackups());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup created: $fileName')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось создать бэкап')),
      );
    }
  }

  Future<void> _quickBackupEvaluationQueue() async {
    try {
      final backupDir = await _getBackupDirectory(_backupsFolder);
      final fileName = 'quick_backup_${_timestamp()}.json';
      final file = File('${backupDir.path}/$fileName');
      await _writeJsonFile(file, _currentQueueState());
      Future(() => _cleanupOldEvaluationBackups());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quick backup saved: $fileName')),
      );
      _debugPanelSetState?.call(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create quick backup')),
        );
      }
    }
  }

  Future<void> _importQuickBackups() async {
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
        final name = path.split(Platform.pathSeparator).last;
        if (!name.startsWith('quick_backup_')) {
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
      _persistEvaluationQueue();
      unawaited(_setEvaluationQueueResumed(false));

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
          const SnackBar(content: Text('Failed to import quick backups')),
        );
      }
    }
  }

  Future<void> _exportEvaluationQueueSnapshot({bool showNotification = true}) async {
    try {
      final snapDir = await _getBackupDirectory(_snapshotsFolder);
      final fileName = 'snapshot_${_timestamp()}.json';
      final file = File('${snapDir.path}/$fileName');
      await _writeJsonFile(file, _currentQueueState());
      if (_snapshotRetentionEnabled) {
        await _cleanupOldEvaluationSnapshots();
      }
      if (showNotification && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Snapshot saved: ${file.path}')),
        );
      }
    } catch (e) {
      if (showNotification && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export snapshot')),
        );
      } else {
        debugPrint('Failed to export snapshot: $e');
      }
    }
  }

  /// Schedule snapshot export without awaiting the result.
  void _scheduleSnapshotExport() {
    unawaited(_exportEvaluationQueueSnapshot(showNotification: false));
  }

  /// Persist the current evaluation queue to disk.
  Future<void> _persistEvaluationQueue() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/evaluation_current_queue.json');
      await _writeJsonFile(file, _currentQueueState());

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _pendingOrderKey,
          [for (final e in _pendingEvaluations) _queueEntryId(e)]);
      await prefs.setStringList(
          _failedOrderKey,
          [for (final e in _failedEvaluations) _queueEntryId(e)]);
      await prefs.setStringList(
          _completedOrderKey,
          [for (final e in _completedEvaluations) _queueEntryId(e)]);
    } catch (_) {}
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
            _evaluationQueueResumed = resumed;
          });
          _debugPanelSetState?.call(() {});
        } else {
          resumed =
              pending.isNotEmpty || failed.isNotEmpty || completed.isNotEmpty;
          _evaluationQueueResumed = resumed;
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
        _persistEvaluationQueue();
        _debugPanelSetState?.call(() {});
      }
      await _setEvaluationQueueResumed(resumed);
    } catch (_) {
      await _setEvaluationQueueResumed(false);
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
    if (_processingEvaluations || _pendingEvaluations.isEmpty) return;
    setState(() {
      _processingEvaluations = true;
    });
    _debugPanelSetState?.call(() {});
    while (_pendingEvaluations.isNotEmpty) {
      if (_pauseProcessingRequested || _cancelProcessingRequested) {
        break;
      }
      final req = _pendingEvaluations.first;
      await Future.delayed(Duration(milliseconds: _evaluationProcessingDelay));
      if (!mounted) {
        _processingEvaluations = false;
        _persistEvaluationQueue();
        return;
      }
      if (_cancelProcessingRequested) {
        break;
      }
      if (_pendingEvaluations.isEmpty) break;
      var success = false;
      while (!success && req.attempts < 3) {
        try {
          await _executeEvaluation(req);
          success = true;
        } catch (e, st) {
          debugPrint('Evaluation error: $e');
          debugPrintStack(stackTrace: st);
          req.attempts++;
          if (req.attempts < 3) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
        }
      }
      if (mounted) {
        setState(() {
          _pendingEvaluations.removeAt(0);
          (success ? _completedEvaluations : _failedEvaluations).add(req);
        });
      } else {
        _pendingEvaluations.removeAt(0);
        (success ? _completedEvaluations : _failedEvaluations).add(req);
      }
      if (success) {
        _scheduleSnapshotExport();
      }
      _persistEvaluationQueue();
      // Update debug panel if it's currently visible.
      _debugPanelSetState?.call(() {});
      if (_pauseProcessingRequested || _cancelProcessingRequested) {
        break;
      }
    }
    if (mounted) {
      setState(() {
        _processingEvaluations = false;
        _pauseProcessingRequested = false;
        _cancelProcessingRequested = false;
      });
      _persistEvaluationQueue();
      _debugPanelSetState?.call(() {});
    } else {
      _processingEvaluations = false;
      _pauseProcessingRequested = false;
      _cancelProcessingRequested = false;
      _persistEvaluationQueue();
    }
  }

  Future<void> _processNextEvaluation() async {
    if (_processingEvaluations || _pendingEvaluations.isEmpty) return;
    setState(() {
      _processingEvaluations = true;
    });
    _debugPanelSetState?.call(() {});
    final req = _pendingEvaluations.first;
    await Future.delayed(Duration(milliseconds: _evaluationProcessingDelay));
    if (!mounted) {
      _processingEvaluations = false;
      _persistEvaluationQueue();
      return;
    }
    if (_cancelProcessingRequested) {
      setState(() {
        _processingEvaluations = false;
      });
      _persistEvaluationQueue();
      _debugPanelSetState?.call(() {});
      return;
    }
    var success = true;
    try {
      setState(() {
        _pendingEvaluations.removeAt(0);
        _completedEvaluations.add(req);
        _processingEvaluations = false;
      });
    } catch (e) {
      success = false;
      setState(() {
        _pendingEvaluations.removeAt(0);
        _failedEvaluations.add(req);
        _processingEvaluations = false;
      });
    }
    _persistEvaluationQueue();
    if (success) {
      _scheduleSnapshotExport();
    }
    _debugPanelSetState?.call(() {});
  }

  Future<void> _cleanupOldEvaluationBackups() async {
    await _cleanupOldFiles(_backupsFolder, _backupRetentionLimit);
  }

  Future<void> _cleanupOldEvaluationSnapshots() async {
    await _cleanupOldFiles(_snapshotsFolder, _snapshotRetentionLimit);
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
      _persistEvaluationQueue();
      unawaited(_setEvaluationQueueResumed(false));
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
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      final decoded = await _readJsonFile(File(path));
      if (decoded is! List) throw const FormatException();
      final items = _decodeEvaluationList(decoded);
      if (!mounted) return;
      setState(() {
        _pendingEvaluations
          ..clear()
          ..addAll(items);
        _failedEvaluations.clear();
      });
      _debugPanelSetState?.call(() {});
      _persistEvaluationQueue();
      unawaited(_setEvaluationQueueResumed(false));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${items.length} evaluations')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to import queue')),
        );
      }
    }
  }

  Future<void> _restoreEvaluationQueue() async {
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

      final files = await backupDir
          .list()
          .where((e) => e is File && e.path.endsWith('.json'))
          .cast<File>()
          .toList();
      if (files.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No backup files found')),
          );
        }
        return;
      }

      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      final selected = await showDialog<File>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Select Backup'),
          children: [
            for (final f in files)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, f),
                child: Text(f.uri.pathSegments.last),
              ),
          ],
        ),
      );

      if (selected == null) return;

      final decoded = await _readJsonFile(selected);
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
      _persistEvaluationQueue();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Restored ${pending.length} pending, ${failed.length} failed, ${completed.length} completed evaluations')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to restore queue')),
        );
      }
    }
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
      _persistEvaluationQueue();
      unawaited(_setEvaluationQueueResumed(false));

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
      _persistEvaluationQueue();
      unawaited(_setEvaluationQueueResumed(false));

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
    try {
      final backupDir = await _getBackupDirectory(_backupsFolder);
      if (!await backupDir.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No quick backup files found')),
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
        final name = path.split(Platform.pathSeparator).last;
        if (!name.startsWith('quick_backup_')) {
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
      _persistEvaluationQueue();
      unawaited(_setEvaluationQueueResumed(false));

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
          const SnackBar(content: Text('Failed to import quick backups')),
        );
      }
    }
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
      _persistEvaluationQueue();
      unawaited(_setEvaluationQueueResumed(false));

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
      _persistEvaluationQueue();
      unawaited(_setEvaluationQueueResumed(false));
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
      _persistEvaluationQueue();
      unawaited(_setEvaluationQueueResumed(false));

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
    setState(() => _isDebugPanelOpen = true);
    await showDialog<void>(
      context: context,
      builder: (context) => DebugPanel(parent: this),
    );
    setState(() => _isDebugPanelOpen = false);
    _debugPanelSetState = null;
  }


  SavedHand _currentSavedHand({String? name}) {
    final stacks = calculateEffectiveStacksPerStreet();
    Map<String, String>? notes;
    if (_savedEffectiveStacks != null) {
      const names = ['Preflop', 'Flop', 'Turn', 'River'];
      notes = {};
      for (int s = 0; s < names.length; s++) {
        final live = _calculateEffectiveStackForStreet(s);
        final exported = _savedEffectiveStacks![names[s]];
        if (exported != live) {
          notes![names[s]] = 'live $live vs saved ${exported ?? 'N/A'}';
        }
      }
      if (notes.isEmpty) notes = null;
    }
    final collapsed = [
      for (int i = 0; i < 4; i++)
        if (!_expandedHistoryStreets.contains(i)) i
    ];
    return SavedHand(
      name: name ?? _defaultHandName(),
      heroIndex: heroIndex,
      heroPosition: _heroPosition,
      numberOfPlayers: numberOfPlayers,
      playerCards: [
        for (int i = 0; i < numberOfPlayers; i++)
          List<CardModel>.from(playerCards[i])
      ],
      boardCards: List<CardModel>.from(boardCards),
      revealedCards: [
        for (int i = 0; i < numberOfPlayers; i++)
          [for (final c in players[i].revealedCards) if (c != null) c]
      ],
      opponentIndex: opponentIndex,
      actions: List<ActionEntry>.from(actions),
      stackSizes: Map<int, int>.from(_initialStacks),
      remainingStacks: {
        for (int i = 0; i < numberOfPlayers; i++)
          i: _stackManager.getStackForPlayer(i)
      },
      playerPositions: Map<int, String>.from(playerPositions),
      playerTypes: Map<int, PlayerType>.from(playerTypes),
      comment: _commentController.text.isNotEmpty ? _commentController.text : null,
      tags: _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      isFavorite: false,
      date: DateTime.now(),
      expectedAction: _expectedAction,
      feedbackText: _feedbackText,
      effectiveStacksPerStreet: stacks,
      validationNotes: notes,
      collapsedHistoryStreets: collapsed.isEmpty ? null : collapsed,
      firstActionTaken:
          _firstActionTaken.isEmpty ? null : _firstActionTaken.toList(),
      actionTags:
          _actionTags.isEmpty ? null : Map<int, String?>.from(_actionTags),
      pendingEvaluations:
          _pendingEvaluations.isEmpty ? null : List<ActionEvaluationRequest>.from(_pendingEvaluations),
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
      heroIndex = hand.heroIndex;
      _heroPosition = hand.heroPosition;
      numberOfPlayers = hand.numberOfPlayers;
      for (int i = 0; i < playerCards.length; i++) {
        playerCards[i]
          ..clear()
          ..addAll(i < hand.playerCards.length ? hand.playerCards[i] : []);
      }
      boardCards
        ..clear()
        ..addAll(hand.boardCards);
      for (int i = 0; i < players.length; i++) {
        final list = players[i].revealedCards;
        list.fillRange(0, list.length, null);
        if (i < hand.revealedCards.length) {
          final from = hand.revealedCards[i];
          for (int j = 0; j < list.length && j < from.length; j++) {
            list[j] = from[j];
          }
        }
      }
      opponentIndex = hand.opponentIndex;
      actions
        ..clear()
        ..addAll(hand.actions);
      _initialStacks
        ..clear()
        ..addAll(hand.stackSizes);
      _stackManager = StackManager(
        Map<int, int>.from(_initialStacks),
        remainingStacks: hand.remainingStacks,
      );
      stackSizes
        ..clear()
        ..addAll(_stackManager.currentStacks);
      playerPositions
        ..clear()
        ..addAll(hand.playerPositions);
      playerTypes
        ..clear()
        ..addAll(hand.playerTypes ??
            {for (final k in hand.playerPositions.keys) k: PlayerType.unknown});
      _commentController.text = hand.comment ?? '';
      _tagsController.text = hand.tags.join(', ');
      _savedEffectiveStacks = hand.effectiveStacksPerStreet;
      _validationNotes = hand.validationNotes;
      _expectedAction = hand.expectedAction;
      _feedbackText = hand.feedbackText;
      _firstActionTaken
        ..clear()
        ..addAll(hand.firstActionTaken ?? []);
      _actionTags
        ..clear()
        ..addAll(hand.actionTags ?? {});
      _pendingEvaluations
        ..clear()
        ..addAll(hand.pendingEvaluations ?? []);
      _expandedHistoryStreets
        ..clear()
        ..addAll([
          for (int i = 0; i < 4; i++)
            if (hand.collapsedHistoryStreets == null ||
                !hand.collapsedHistoryStreets!.contains(i))
              i
        ]);
      currentStreet = 0;
      _playbackIndex = hand.actions.length;
      _animatedPlayersPerStreet.clear();
      _updatePlaybackState();
      _updatePositions();
    });
    _persistEvaluationQueue();
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

    final expected = data['expectedAction'] as String?;
    final feedback = data['feedbackText'] as String?;

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

      actions
        ..clear()
        ..addAll(newActions);

      playerPositions
        ..clear()
        ..addAll(newPositions);

      currentStreet = 0;
      _playbackIndex = 0;
      _updatePlaybackState();
      _updatePositions();
      _expectedAction = expected;
      _feedbackText = feedback;
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
    await _savedHandService.add(hand);
  }

  void loadLastSavedHand() {
    if (savedHands.isEmpty) return;
    final hand = savedHands.last;
    _applySavedHand(hand);
  }

  Future<void> loadHandByName() async {
    if (savedHands.isEmpty) return;
    String filter = '';
    Set<String> localFilters = {...tagFilters};
    final selected = await showDialog<SavedHand>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final query = filter.toLowerCase();
          final filtered = [
            for (final hand in savedHands)
              if ((query.isEmpty ||
                      hand.tags.any((t) => t.toLowerCase().contains(query)) ||
                      hand.name.toLowerCase().contains(query) ||
                      (hand.comment?.toLowerCase().contains(query) ?? false)) &&
                  (localFilters.isEmpty ||
                      localFilters.every((tag) => hand.tags.contains(tag))))
                hand
          ];
          return AlertDialog(
            title: const Text('Выберите раздачу'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration:
                        const InputDecoration(hintText: 'Поиск'),
                    onChanged: (value) => setStateDialog(() => filter = value),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          builder: (context) => StatefulBuilder(
                            builder: (context, setStateSheet) {
                              final tags = allTags.toList()..sort();
                              if (tags.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(AppConstants.padding16),
                                  child: Text('Нет тегов'),
                                );
                              }
                              return ListView(
                                shrinkWrap: true,
                                children: [
                                  for (final tag in tags)
                                    CheckboxListTile(
                                      title: Text(tag),
                                      value: localFilters.contains(tag),
                                      onChanged: (checked) {
                                        setStateSheet(() {
                                          if (checked == true) {
                                            localFilters.add(tag);
                                          } else {
                                            localFilters.remove(tag);
                                          }
                                          tagFilters = Set.from(localFilters);
                                        });
                                        setStateDialog(() {});
                                      },
                                    ),
                                ],
                              );
                            },
                          ),
                        );
                        setState(() {
                          tagFilters = Set.from(localFilters);
                        });
                        setStateDialog(() {});
                      },
                      child: const Text('Фильтр по тегам'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final hand = filtered[index];
                        final savedIndex = savedHands.indexOf(hand);
                        final title =
                            hand.name.isNotEmpty ? hand.name : 'Без названия';
                        return ListTile(
                          dense: true,
                          title: Text(
                            title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: () {
                            final items = <Widget>[];
                            if (hand.tags.isNotEmpty) {
                              items.add(Text(
                                hand.tags.join(', '),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ));
                            }
                            if (hand.comment?.isNotEmpty ?? false) {
                              items.add(Text(
                                hand.comment!,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ));
                            }
                            return items.isEmpty
                                ? null
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: items,
                                  );
                          }(),
                          onTap: () => Navigator.pop(context, hand),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final nameController =
                              TextEditingController(text: hand.name);
                          final tagsController =
                              TextEditingController(text: hand.tags.join(', '));
                          final commentController =
                              TextEditingController(text: hand.comment ?? '');

                          await showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom,
                                left: 16,
                                right: 16,
                                top: 16,
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      controller: nameController,
                                      decoration: const InputDecoration(
                                          labelText: 'Название'),
                                    ),
                                    const SizedBox(height: 8),
                                    Autocomplete<String>(
                                      optionsBuilder: (TextEditingValue value) {
                                        final input = value.text.toLowerCase();
                                        if (input.isEmpty) {
                                          return const Iterable<String>.empty();
                                        }
                                        return allTags.where((tag) =>
                                            tag.toLowerCase().contains(input));
                                      },
                                      displayStringForOption: (opt) => opt,
                                      onSelected: (selection) {
                                        final tags = tagsController.text
                                            .split(',')
                                            .map((t) => t.trim())
                                            .where((t) => t.isNotEmpty)
                                            .toSet();
                                        if (tags.add(selection)) {
                                          tagsController.text = tags.join(', ');
                                          tagsController.selection =
                                              TextSelection.fromPosition(
                                                  TextPosition(
                                                      offset: tagsController
                                                          .text.length));
                                        }
                                      },
                                      fieldViewBuilder: (context,
                                          textEditingController,
                                          focusNode,
                                          onFieldSubmitted) {
                                        textEditingController.text =
                                            tagsController.text;
                                        textEditingController.selection =
                                            tagsController.selection;
                                        textEditingController.addListener(() {
                                          if (tagsController.text !=
                                              textEditingController.text) {
                                            tagsController.value =
                                                textEditingController.value;
                                          }
                                        });
                                        tagsController.addListener(() {
                                          if (textEditingController.text !=
                                              tagsController.text) {
                                            textEditingController.value =
                                                tagsController.value;
                                          }
                                        });
                                        return TextField(
                                          controller: textEditingController,
                                          focusNode: focusNode,
                                          decoration: const InputDecoration(
                                              labelText: 'Теги'),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: commentController,
                                      decoration: const InputDecoration(
                                          labelText: 'Комментарий'),
                                      keyboardType: TextInputType.multiline,
                                      maxLines: null,
                                    ),
                                    const SizedBox(height: 16),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Отмена'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );

                          final newName = nameController.text.trim();
                          final newTags = tagsController.text
                              .split(',')
                              .map((t) => t.trim())
                              .where((t) => t.isNotEmpty)
                              .toList();
                          final newComment = commentController.text.trim();

                          final old = savedHands[savedIndex];
                          final oldName = old.name.trim();
                          final oldTags = old.tags
                              .map((t) => t.trim())
                              .where((t) => t.isNotEmpty)
                              .toList();
                          final oldComment = old.comment?.trim() ?? '';

                          final hasChanges =
                              newName != oldName ||
                                  !listEquals(newTags, oldTags) ||
                                  newComment != oldComment;

                          if (hasChanges) {
                            final updated = SavedHand(
                                name: newName,
                                heroIndex: old.heroIndex,
                                heroPosition: old.heroPosition,
                                numberOfPlayers: old.numberOfPlayers,
                                playerCards: [
                                  for (final list in old.playerCards)
                                    List<CardModel>.from(list)
                                ],
                                boardCards: List<CardModel>.from(old.boardCards),
                                actions: List<ActionEntry>.from(old.actions),
                                stackSizes: Map<int, int>.from(old.stackSizes),
                                playerPositions:
                                    Map<int, String>.from(old.playerPositions),
                                playerTypes: old.playerTypes == null
                                    ? null
                                    : Map<int, PlayerType>.from(old.playerTypes!),
                                comment:
                                    newComment.isNotEmpty ? newComment : null,
                                tags: newTags,
                                isFavorite: old.isFavorite,
                                date: old.date,
                              );
                            await _savedHandService.update(savedIndex, updated);
                            setStateDialog(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Раздача обновлена')),
                            );
                          }

                          nameController.dispose();
                          tagsController.dispose();
                          commentController.dispose();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Удалить раздачу?'),
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
                            await _savedHandService.removeAt(savedIndex);
                            setStateDialog(() {});
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    if (selected != null) {
      _applySavedHand(selected);
    }
  }

  Future<void> exportLastSavedHand() async {
    if (savedHands.isEmpty) return;
    final jsonStr = jsonEncode(savedHands.last.toJson());
    await Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Раздача скопирована.')),
    );
  }

  Future<void> exportAllHands() async {
    if (savedHands.isEmpty) return;
    final jsonStr =
        jsonEncode([for (final hand in savedHands) hand.toJson()]);
    await Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('${savedHands.length} hands exported to clipboard')),
    );
  }

  Future<void> importHandFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data == null || data.text == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный формат данных.')),
      );
      return;
    }
    try {
      loadHand(data.text!);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный формат данных.')),
      );
    }
  }

  Future<void> importAllHandsFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data == null || data.text == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid data format')),
      );
      return;
    }

    try {
      final parsed = jsonDecode(data.text!);
      if (parsed is! List) throw const FormatException();

      int count = 0;
      for (final item in parsed) {
        if (item is Map<String, dynamic>) {
          try {
            await _savedHandService.add(SavedHand.fromJson(item));
            count++;
          } catch (_) {
            // skip invalid hand objects
          }
        }
      }

      if (count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $count hands')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid data format')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid data format')),
      );
    }
  }



  @override
  void dispose() {
    _activeTimer?.cancel();
    _playbackTimer?.cancel();
    _centerChipTimer?.cancel();
    _autoBackupTimer?.cancel();
    _processingEvaluations = false;
    _pauseProcessingRequested = false;
    _centerChipController.dispose();
    _commentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Widget _buildBetChipsOverlay(double scale) {
    final screenSize = MediaQuery.of(context).size;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 - _centerYOffset(scale);
    final radiusMod = _radiusModifier();
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    final List<Widget> chips = [];
    for (int i = 0; i < numberOfPlayers; i++) {
      final index = (i + _viewIndex()) % numberOfPlayers;
      final playerActions = actions
          .where((a) => a.playerIndex == index && a.street == currentStreet)
          .toList();
      if (playerActions.isEmpty) continue;
      final lastAction = playerActions.last;
      if (['bet', 'raise', 'call'].contains(lastAction.action) &&
          lastAction.amount != null) {
        final angle = 2 * pi * i / numberOfPlayers + pi / 2;
        final dx = radiusX * cos(angle);
        final dy = radiusY * sin(angle);
        final bias = _verticalBiasFromAngle(angle) * scale;
        chips.add(Positioned(
          left: centerX + dx - 10 * scale,
          top: centerY + dy + bias - 80 * scale,
          child: ChipWidget(
            amount: lastAction.amount!,
            scale: 0.8 * scale,
          ),
        ));
      }
    }
    return Stack(children: chips);
  }





  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final visibleActions = actions.take(_playbackIndex).toList();
    final savedActions = _currentSavedHand().actions;
    final double scale = _tableScale();
    final viewIndex = _viewIndex();
    final double infoScale = numberOfPlayers > 8 ? 0.85 : 1.0;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 - _centerYOffset(scale);
    final radiusMod = _radiusModifier();
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    final effectiveStack = _calculateEffectiveStack(fromActions: visibleActions);
    final currentStreetEffectiveStack = _calculateEffectiveStackForStreet(currentStreet);
    final pot = _pots[currentStreet];
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
            DropdownButton<int>(
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
                  setState(() {
                    numberOfPlayers = value;
                    playerPositions = Map.fromIterables(
                      List.generate(numberOfPlayers, (i) => i),
                      getPositionList(numberOfPlayers),
                    );
                    for (int i = 0; i < numberOfPlayers; i++) {
                    playerTypes.putIfAbsent(i, () => PlayerType.unknown);
                  }
                  playerTypes.removeWhere((key, _) => key >= numberOfPlayers);
                  _updatePositions();
                });
              }
            },
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
                    onCardSelected: selectBoardCard,
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
                    pots: _pots,
                    animatedPlayersPerStreet: _animatedPlayersPerStreet,
                    centerChipAction: _centerChipAction,
                    showCenterChip: _showCenterChip,
                    centerChipController: _centerChipController,
                    actionColor: _actionColor,
                  ),
                  _ActionHistorySection(
                    actions: actions,
                    playbackIndex: _playbackIndex,
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
                    potText: _formatAmount(_pots[currentStreet]),
                    stackText: _formatAmount(effectiveStack),
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
            pots: _pots,
            stackSizes: stackSizes,
            playerPositions: playerPositions,
            onEdit: _editAction,
            onDelete: _deleteAction,
            visibleCount: _playbackIndex,
            evaluateActionQuality: _evaluateActionQuality,
          ),
        ),
      ),
    ),
    ActionHistoryExpansionTile(
      actions: visibleActions,
      playerPositions: playerPositions,
      pots: _pots,
      stackSizes: stackSizes,
      onEdit: _editAction,
      onDelete: _deleteAction,
      visibleCount: _playbackIndex,
      evaluateActionQuality: _evaluateActionQuality,
    ),
    StreetActionsWidget(
      currentStreet: currentStreet,
      onStreetChanged: (index) {
        setState(() {
          currentStreet = index;
          _actionTags.clear();
          _animatedPlayersPerStreet
              .putIfAbsent(index, () => <int>{});
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
              playbackIndex: _playbackIndex,
              onTap: (index) {
                setState(() {
                  _playbackIndex = index;
                  _updateVisibleActions(); // Перестраиваем экран
                });
              },
              playerPositions: playerPositions,
              scale: scale,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: _stepBackward,
                  ),
                  IconButton(
                    icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white),
                    onPressed: _isPlaying ? _pausePlayback : _startPlayback,
                  ),
                IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: _stepForward,
                  ),
                  IconButton(
                    icon: const Icon(Icons.save, color: Colors.white),
                    onPressed: () => saveCurrentHand(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.folder_open, color: Colors.white),
                    onPressed: loadLastSavedHand,
                  ),
                  IconButton(
                    icon: const Icon(Icons.list, color: Colors.white),
                    onPressed: () => loadHandByName(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload, color: Colors.white),
                    onPressed: exportLastSavedHand,
                  ),
                  IconButton(
                    icon: const Icon(Icons.file_upload, color: Colors.white),
                    onPressed: exportAllHands,
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: importHandFromClipboard,
                  ),
                  IconButton(
                    icon: const Icon(Icons.file_download, color: Colors.white),
                    onPressed: importAllHandsFromClipboard,
                  ),
                  Expanded(
                    child: Slider(
                      value: _playbackIndex.toDouble(),
                      min: 0,
                      max: actions.isNotEmpty
                          ? actions.length.toDouble()
                          : 1,
                      onChanged: (v) {
                        _pausePlayback();
                        setState(() {
                          _playbackIndex = v.round();
                        });
                        _updatePlaybackState();
                      },
                    ),
                  ),
                ],
              ),
            ),
            CollapsibleActionHistory(
              actions: visibleActions,
              playerPositions: playerPositions,
              heroIndex: heroIndex,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: _commentController,
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
                        controller: _tagsController,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: StreetActionsList(
                        street: currentStreet,
                        actions: actions,
                        pots: _pots,
                        stackSizes: stackSizes,
                        playerPositions: playerPositions,
                        onEdit: _editAction,
                        onDelete: _deleteAction,
                        visibleCount: _playbackIndex,
                        evaluateActionQuality: _evaluateActionQuality,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {},
                      child: const Text('🔍 Проанализировать'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _resetHand,
                      child: const Text('Сбросить раздачу'),
                    ),
                  ],
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
    final centerY = screenSize.height / 2 - _centerYOffset(scale);
    final radiusMod = _radiusModifier();
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    final visibleActions = actions.take(_playbackIndex).toList();

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
    final bias = _verticalBiasFromAngle(angle) * scale;

    final String position = playerPositions[index] ?? '';
    final int stack = stackSizes[index] ?? 0;
    final String tag = _actionTags[index] ?? '';
    final bool isActive = activePlayerIndex == index;
    final bool isFolded = visibleActions.any((a) =>
        a.playerIndex == index &&
        a.action == 'fold' &&
        a.street <= currentStreet);

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
        _stackManager.getInvestmentForStreet(index, currentStreet);

    final Color? actionColor =
        (lastAction?.action == 'bet' || lastAction?.action == 'raise')
            ? Colors.green
            : lastAction?.action == 'call'
                ? Colors.blue
                : null;
    final double maxRadius = 36 * scale;
    final double radius = (_pots[currentStreet] > 0)
        ? min(
            maxRadius,
            (invested / _pots[currentStreet]) * maxRadius,
          )
        : 0.0;

    final widgets = <Widget>[
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
            remainingStack: _stackManager.getStackForPlayer(index),
            streetInvestment: invested,
            currentBet: currentBet,
            lastAction: lastAction?.action,
            showLastIndicator: lastStreetAction?.playerIndex == index,
            isActive: isActive,
            isFolded: isFolded,
            isHero: index == heroIndex,
            isOpponent: index == opponentIndex,
            playerTypeIcon: '',
            playerTypeLabel:
                numberOfPlayers > 9 ? null : _playerTypeLabel(playerTypes[index]),
            positionLabel:
                numberOfPlayers <= 9 ? _positionLabelForIndex(index) : null,
            blindLabel: (playerPositions[index] == 'SB' ||
                    playerPositions[index] == 'BB')
                ? playerPositions[index]
                : null,
            onCardTap: (cardIndex) => _onPlayerCardTap(index, cardIndex),
            onTap: () => setState(() => activePlayerIndex = index),
            onDoubleTap: () => setState(() {
              heroIndex = index;
              _updatePositions();
            }),
            onLongPress: () => _editPlayerInfo(index),
            onEdit: () => _editPlayerInfo(index),
            onStackTap: (value) => setState(() {
              _initialStacks[index] = value;
              _stackManager = StackManager(Map<int, int>.from(_initialStacks));
              _updatePlaybackState();
            }),
            onRemove: numberOfPlayers > 2 ? () {
              _removePlayer(index);
            } : null,
            onTimeExpired: () => _onPlayerTimeExpired(index),
          ),
        ),
      ),
      Positioned(
        left: centerX + dx - 8 * scale,
        top: centerY + dy + bias - 70 * scale,
        child: _playerTypeIcon(playerTypes[index]),
      ),
      if (lastAmountAction != null)
        Positioned(
          left: centerX + dx - 24 * scale,
          top: centerY + dy + bias - 80 * scale,
          child: ChipAmountWidget(
            amount: lastAmountAction!.amount!.toDouble(),
            color: _actionColor(lastAmountAction!.action),
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
      if (_pots[currentStreet] > 0 &&
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
    final centerY = screenSize.height / 2 - _centerYOffset(scale);
    final radiusMod = _radiusModifier();
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    final visibleActions = actions.take(_playbackIndex).toList();

    final index = (i + _viewIndex()) % numberOfPlayers;
    final angle = 2 * pi * i / numberOfPlayers + pi / 2;
    final dx = radiusX * cos(angle);
    final dy = radiusY * sin(angle);
    final bias = _verticalBiasFromAngle(angle) * scale;

    ActionEntry? lastAction;
    for (final a in visibleActions.reversed) {
      if (a.playerIndex == index && a.street == currentStreet) {
        lastAction = a;
        break;
      }
    }

    final invested =
        _stackManager.getInvestmentForStreet(index, currentStreet);

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

    final fraction = _pots[currentStreet] > 0
        ? invested / _pots[currentStreet]
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

  double _centerYOffset() {
    double base;
    if (numberOfPlayers > 6) {
      base = 200.0 + (numberOfPlayers - 6) * 10.0;
    } else {
      base = 140.0 - (6 - numberOfPlayers) * 10.0;
    }
    return base * scale;
  }

  double _radiusModifier() {
    return (1 + (6 - numberOfPlayers) * 0.05).clamp(0.8, 1.2);
  }

  double _verticalBiasFromAngle(double angle) {
    return 90 + 20 * sin(angle);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 - _centerYOffset();
    final radiusMod = _radiusModifier();
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
        final bias = _verticalBiasFromAngle(angle) * scale;
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
    final centerY = screenSize.height / 2 - state._centerYOffset(scale);
    final radiusMod = state._radiusModifier();
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
        final bias = state._verticalBiasFromAngle(angle) * scale;

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
    final centerY = screenSize.height / 2 - state._centerYOffset(scale);
    final radiusMod = state._radiusModifier();
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
        final bias = state._verticalBiasFromAngle(angle) * scale;

        final playerActions = state.actions
            .where((a) =>
                a.playerIndex == index && a.street == state.currentStreet)
            .toList();
        final lastAction =
            playerActions.isNotEmpty ? playerActions.last : null;
        final color = state._actionColor(lastAction?.action ?? 'bet');
        final start =
            Offset(centerX + dx, centerY + dy + bias + 92 * scale);
        final end = Offset.lerp(start, Offset(centerX, centerY), 0.2)!;
        final streetSet = state._animatedPlayersPerStreet
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
  final List<ActionEntry> visibleActions;
  final void Function(int, CardModel) onCardSelected;

  const _BoardCardsSection({
    required this.scale,
    required this.currentStreet,
    required this.boardCards,
    required this.onCardSelected,
    required this.visibleActions,
  });

  @override
  Widget build(BuildContext context) {
    return BoardDisplay(
      scale: scale,
      currentStreet: currentStreet,
      boardCards: boardCards,
      onCardSelected: onCardSelected,
      visibleActions: visibleActions,
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
