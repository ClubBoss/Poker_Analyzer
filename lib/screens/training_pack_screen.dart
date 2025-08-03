import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../helpers/date_utils.dart';
import '../helpers/action_utils.dart';
import 'package:provider/provider.dart';
import '../utils/responsive.dart';

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/training_pack.dart';
import '../models/game_type.dart';
import '../models/saved_hand.dart';
import '../models/session_task_result.dart';
import 'poker_analyzer_screen.dart';
import 'create_pack_screen.dart';
import '../widgets/difficulty_chip.dart';
import '../widgets/info_tooltip.dart';
import '../services/training_pack_storage_service.dart';
import '../widgets/color_picker_dialog.dart';
import '../services/action_sync_service.dart';
import '../services/all_in_players_service.dart';
import '../services/pot_sync_service.dart';
import '../services/pot_history_service.dart';
import '../services/board_manager_service.dart';
import '../services/board_sync_service.dart';
import '../services/board_editing_service.dart';
import '../services/player_editing_service.dart';
import '../services/transition_lock_service.dart';
import '../services/board_reveal_service.dart';
import '../services/current_hand_context_service.dart';
import '../services/player_manager_service.dart';
import '../services/player_profile_service.dart';
import '../services/playback_manager_service.dart';
import '../services/stack_manager_service.dart';
import '../services/folded_players_service.dart';
import '../services/saved_hand_import_export_service.dart';
import '../services/training_import_export_service.dart';
import '../services/training_spot_file_service.dart';
import '../services/training_spot_storage_service.dart';
import '../services/training_history_export_service.dart';
import '../services/training_history_import_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/training_stats_service.dart';
import '../services/error_logger_service.dart';
import '../models/training_spot.dart';
import '../models/evaluation_result.dart';
import '../services/evaluation_executor_service.dart';
import '../services/service_registry.dart';
import '../services/training_session_controller.dart';
import '../services/goals_service.dart';
import '../widgets/replay_spot_widget.dart';
import '../widgets/eval_result_view.dart';
import '../models/result_entry.dart';
import '../widgets/common/training_spot_list.dart';
import 'markdown_preview_screen.dart';
import 'package:markdown/markdown.dart' as md;
import 'training_spot_detail_screen.dart';
import 'spot_editor_screen.dart';
import 'dart:async';
import '../services/cloud_training_history_service.dart';
import '../helpers/color_utils.dart';
import '../theme/app_colors.dart';
import '../widgets/sync_status_widget.dart';
import '../services/training_pack_cloud_sync_service.dart';
import '../services/pinned_learning_service.dart';


class _SessionSummary {
  final DateTime date;
  final int total;
  final int correct;

  _SessionSummary({
    required this.date,
    required this.total,
    required this.correct,
  });

  double get accuracy => total == 0 ? 0 : correct * 100 / total;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'total': total,
        'correct': correct,
      };

  factory _SessionSummary.fromJson(Map<String, dynamic> json) => _SessionSummary(
        date: DateTime.parse(json['date'] as String),
        total: json['total'] as int? ?? 0,
        correct: json['correct'] as int? ?? 0,
      );
}

class TrainingPackScreen extends StatefulWidget {
  final TrainingPack pack;
  final List<SavedHand>? hands;
  final bool mistakeReviewMode;
  final ValueChanged<bool>? onComplete;
  final bool persistResults;
  final int? initialPosition;

  const TrainingPackScreen({
    super.key,
    required this.pack,
    this.hands,
    this.mistakeReviewMode = false,
    this.onComplete,
    this.persistResults = true,
    this.initialPosition,
  });

  @override
  State<TrainingPackScreen> createState() => _TrainingPackScreenState();
}

class _TrainingPackScreenState extends State<TrainingPackScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _analyzerKey = GlobalKey();
  final GlobalKey<TrainingSpotListState> _spotListKey =
      GlobalKey<TrainingSpotListState>();
  int _currentIndex = 0;

  static const List<String> _availableTags = ['BVB', 'ICM', 'Trap', 'KO'];
  static const _stackRanges = ['10-15', '15-20', '20-25', '25+'];
  static const _prefsStackKey = 'training_stack_range';

  String? _stackFilter;
  late List<SavedHand> _allHands;
  late List<TrainingSpot> _allSpots;

  late TrainingPack _pack;
  bool _pinned = false;

  /// Hands that are currently used in the session. By default it contains
  /// all hands from the training pack, but when the user chooses to repeat
  /// mistakes it becomes a filtered subset.
  late List<SavedHand> _sessionHands;

  /// Whether we are currently reviewing only the mistaken hands.
  bool _isMistakeReviewMode = false;

  final List<ResultEntry> _results = [];
  List<ResultEntry> _previousResults = [];
  List<_SessionSummary> _history = [];
  String? _sessionComment;

  late TabController _tabs;

  final TrainingImportExportService _importExportService =
      const TrainingImportExportService();
  final TrainingSpotFileService _spotFileService =
      const TrainingSpotFileService();
  late TrainingSpotStorageService _spotStorageService;
  List<TrainingSpot> _spots = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _spotStorageService = TrainingSpotStorageService(
      cloud: context.read<CloudSyncService>(),
    );
    _pack = widget.pack;
    _pinned =
        PinnedLearningService.instance.isPinned('pack', _pack.id);
    PinnedLearningService.instance.addListener(_updatePinned);
    unawaited(
      PinnedLearningService.instance.recordOpen('pack', _pack.id),
    );
    _allHands = widget.hands ?? _pack.hands;
    _sessionHands = List.from(_allHands);
    _allSpots = List.from(_pack.spots);
    _spots = List.from(_allSpots);
    _isMistakeReviewMode = widget.mistakeReviewMode;
    _loadProgress();
    _loadSpots();
    _loadSavedResults();
    _loadStackFilter();
  }

  void _updatePinned() {
    final pinned =
        PinnedLearningService.instance.isPinned('pack', _pack.id);
    if (pinned != _pinned) setState(() => _pinned = pinned);
  }

  Future<void> _togglePinned() async {
    await PinnedLearningService.instance.toggle('pack', _pack.id);
    final pinned =
        PinnedLearningService.instance.isPinned('pack', _pack.id);
    setState(() => _pinned = pinned);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pinned ? 'Pinned' : 'Unpinned')),
    );
  }

  Future<void> _loadProgress() async {
    if (_isMistakeReviewMode) {
      setState(() {
        _currentIndex = 0;
      });
      return;
    }
    final initial = widget.initialPosition;
    if (initial != null) {
      setState(() {
        _currentIndex = initial;
      });
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIndex = prefs.getInt('training_progress_${_pack.name}') ?? 0;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('training_progress_${_pack.name}', _currentIndex);
    await PinnedLearningService.instance
        .setLastPosition('pack', _pack.id, _currentIndex);
  }

  Future<void> _loadSpots() async {
    final loaded = await _spotStorageService.load();
    if (mounted && loaded.isNotEmpty) {
      setState(() {
        _allSpots = loaded;
        _applyStackFilter();
      });
    }
  }

  Future<void> _saveSpots() async {
    await _spotStorageService.save(_spots);
  }

  bool _matchStack(int stack) {
    final r = _stackFilter;
    if (r == null) return true;
    if (r.endsWith('+')) {
      final min = int.tryParse(r.substring(0, r.length - 1)) ?? 0;
      return stack >= min;
    }
    final parts = r.split('-');
    if (parts.length == 2) {
      final min = int.tryParse(parts[0]) ?? 0;
      final max = int.tryParse(parts[1]) ?? 0;
      return stack >= min && stack <= max;
    }
    return true;
  }

  void _applyStackFilter() {
    final hands = [
      for (final h in _allHands)
        if (_matchStack(h.stackSizes[h.heroIndex] ?? 0)) h
    ];
    final spots = [
      for (final s in _allSpots)
        if (_matchStack(s.stacks[s.heroIndex])) s
    ];
    _sessionHands = hands;
    _spots = spots;
    _currentIndex = _currentIndex.clamp(0, _sessionHands.isEmpty ? 0 : _sessionHands.length - 1);
  }

  Future<void> _loadStackFilter() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _stackFilter = prefs.getString(_prefsStackKey);
      _applyStackFilter();
    });
  }

  Future<void> _setStackFilter(String? value) async {
    setState(() {
      _stackFilter = value;
      _applyStackFilter();
    });
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_prefsStackKey);
    } else {
      await prefs.setString(_prefsStackKey, value);
    }
  }

  Future<void> _loadSavedResults() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'results_${_pack.name}';
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return;
    try {
      final data = jsonDecode(jsonStr);
      if (data is Map) {
        final last = data['last'];
        if (last is List) {
          _previousResults = [
            for (final item in last)
              if (item is Map)
                ResultEntry.fromJson(Map<String, dynamic>.from(item))
          ];
        }
        final history = data['history'];
        if (history is List) {
          _history = [
            for (final item in history)
              if (item is Map<String, dynamic>)
                _SessionSummary.fromJson(Map<String, dynamic>.from(item))
          ];
        }
      } else if (data is List) {
        _previousResults = [
          for (final item in data)
            if (item is Map)
              ResultEntry.fromJson(Map<String, dynamic>.from(item))
        ];
      }
    } catch (e, st) {
      ErrorLoggerService.instance
          .logError('Failed to load training results', e, st);
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveCurrentResults() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'results_${_pack.name}';
    final list = [for (final r in _results) r.toJson()];
    final correct = _results.where((r) => r.correct).length;
    _history.insert(
        0,
        _SessionSummary(
          date: DateTime.now(),
          total: _results.length,
          correct: correct,
        ));
    if (_history.length > 5) {
      _history = _history.sublist(0, 5);
    }
    final data = {
      'last': list,
      'history': [for (final h in _history) h.toJson()],
    };
    final jsonData = jsonEncode(data);
    await prefs.setString(key, jsonData);
    unawaited(context.read<CloudSyncService>().syncUp());
    _previousResults = List.from(_results);
  }

  Future<void> _promptForComment() async {
    final controller = TextEditingController(text: _sessionComment);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Комментарий к сессии'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Введите заметку'),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        _sessionComment = result;
      });
    }
  }

  void _showQuickFeedback(EvaluationResult evaluation) {
    final message = evaluation.correct
        ? 'Верно! Ожидалось: ${evaluation.expectedAction}'
        : 'Неверно. Правильный ответ: ${evaluation.expectedAction}';
    final color = evaluation.correct ? Colors.green : Colors.red;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<ResultEntry> _showFeedback() async {
    final state = _analyzerKey.currentState as dynamic;
    SavedHand? played;
    if (state != null) {
      try {
        final jsonStr = await state.saveHand() as String;
        played = SavedHandImportExportService.decode(jsonStr);
      } catch (e, st) {
        ErrorLoggerService.instance
            .logError('Failed to capture played hand', e, st);
      }
    }
    final original = _sessionHands[_currentIndex];
    String userAct = '-';
    if (played != null) {
      for (final a in played.actions) {
        if (a.isHero(played.heroIndex)) {
          userAct = a.action;
          break;
        }
      }
    }
    final evaluation = await context
        .read<TrainingSessionController>()
        .evaluateSpot(context, TrainingSpot.fromSavedHand(original), userAct);
    _showQuickFeedback(evaluation);
    final expected = evaluation.expectedAction;
    final matched = evaluation.correct;
    int rating = original.rating;
    final Set<String> tags = {...original.tags};
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              original.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text('Ожидалось: $expected',
                style: const TextStyle(color: Colors.white70)),
            Text('Вы выбрали: $userAct',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
              Text(
                matched ? 'Верно!' : 'Неверно.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: matched ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              EvalResultView(
                spot: TrainingSpot.fromSavedHand(original),
                action: userAct,
              ),
              if (original.feedbackText != null) ...[
              const SizedBox(height: 8),
              Text(
                original.feedbackText!,
                style: const TextStyle(color: Colors.white),
              ),
            ],
            if (evaluation.hint != null) ...[
              const SizedBox(height: 8),
              Text(
                evaluation.hint!,
                style: const TextStyle(color: Colors.white),
              ),
            ],
            const SizedBox(height: 16),
            StatefulBuilder(builder: (context, setStateDialog) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Оцените спот',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 1; i <= 5; i++)
                        IconButton(
                          icon: Icon(
                            i <= rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () => setStateDialog(() => rating = i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: [
                      for (final tag in _availableTags)
                        FilterChip(
                          label: Text(tag),
                          selected: tags.contains(tag),
                          onSelected: (selected) => setStateDialog(() {
                            if (selected) {
                              tags.add(tag);
                            } else {
                              tags.remove(tag);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (original.actions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.grey[900],
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (_) => ReplaySpotWidget(
                              spot: TrainingSpot.fromSavedHand(original),
                              expectedAction: original.expectedAction,
                              gtoAction: original.gtoAction,
                              evLoss: original.evLoss,
                              feedbackText: original.feedbackText,
                            ),
                          );
                        },
                        child: const Text('Replay Hand'),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      final updated = original.copyWith(
                        rating: rating,
                        tags: tags.toList(),
                      );
                      final index = _sessionHands.indexOf(original);
                      if (index != -1) {
                        _sessionHands[index] = updated;
                      }
                      final packIndex = _pack.hands.indexOf(original);
                      if (packIndex != -1) {
                        _pack.hands[packIndex] = updated;
                      }
                      Navigator.pop(ctx);
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
    return ResultEntry(
      name: original.name,
      userAction: userAct,
      evaluation: evaluation,
    );
  }

  Future<void> _editPack() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePackScreen()),
    );
  }

  Future<void> _changeColor() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString('pack_last_color');
    final initColor = last != null ? colorFromHex(last) : colorFromHex(_pack.colorTag);
    final color = await showColorPickerDialog(context, initialColor: initColor);
    if (color == null) return;
    final hex = colorToHex(color);
    await prefs.setString('pack_last_color', hex);
    await context.read<TrainingPackStorageService>().setColorTag(_pack, hex);
    setState(() => _pack = TrainingPack(
          name: _pack.name,
          description: _pack.description,
          category: _pack.category,
          gameType: _pack.gameType,
          colorTag: hex,
          isBuiltIn: _pack.isBuiltIn,
          tags: _pack.tags,
          hands: _pack.hands,
          spots: _pack.spots,
          difficulty: _pack.difficulty,
          history: _pack.history,
        ));
  }

  Future<void> _clearProgress() async {
    await context.read<TrainingPackStorageService>().clearProgress(_pack);
    final history = List<TrainingSessionResult>.from(_pack.history);
    if (history.isNotEmpty) history.removeLast();
    setState(() {
      _pack = TrainingPack(
        name: _pack.name,
        description: _pack.description,
        category: _pack.category,
        gameType: _pack.gameType,
        colorTag: _pack.colorTag,
        isBuiltIn: _pack.isBuiltIn,
        tags: _pack.tags,
        hands: _pack.hands,
        spots: _pack.spots,
        difficulty: _pack.difficulty,
        history: history,
      );
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Прогресс сброшен')),
      );
    }
  }

  Future<void> _duplicatePack() async {
    final service = context.read<TrainingPackStorageService>();
    final copy = await service.duplicatePack(_pack);
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => TrainingPackScreen(pack: copy)),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Копия «${copy.name}» создана')),
    );
  }

  Future<void> _exportPack() async {
    final file = await context.read<TrainingPackStorageService>().exportPack(_pack);
    if (!mounted || file == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Файл сохранён: ${file.path}')),
    );
  }

  Future<void> _sharePack() async {
    final file = await context.read<TrainingPackStorageService>().exportPackTemp(_pack);
    if (!mounted || file == null) return;
    await Share.shareXFiles([XFile(file.path)], text: 'Check out my Poker Analyzer pack!');
    if (await file.exists()) await file.delete();
  }

  Future<void> _addSpot() async {
    final spot = await Navigator.push<TrainingSpot>(
      context,
      MaterialPageRoute(builder: (_) => const SpotEditorScreen()),
    );
    if (spot == null) return;
    final newSpots = List<TrainingSpot>.from(_pack.spots)..add(spot);
    final updated = TrainingPack(
      name: _pack.name,
      description: _pack.description,
      category: _pack.category,
      gameType: _pack.gameType,
      colorTag: _pack.colorTag,
      isBuiltIn: _pack.isBuiltIn,
      tags: _pack.tags,
      hands: _pack.hands,
      spots: newSpots,
      difficulty: _pack.difficulty,
      history: _pack.history,
    );
    await context.read<TrainingPackStorageService>().updatePack(_pack, updated);
    setState(() => _pack = updated);
  }

  void _previousHand() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      if (!_isMistakeReviewMode) {
        _saveProgress();
      }
    }
  }

  Future<void> _nextHand() async {
    final result = await _showFeedback();
    context.read<GoalsService>().recordHandCompleted(context);
    if (_results.length > _currentIndex) {
      _results[_currentIndex] = result;
    } else {
      _results.add(result);
    }
    if (!_pack.isBuiltIn) {
      final updated = await context
          .read<TrainingPackStorageService>()
          .recordAttempt(_pack, result.correct);
      if (updated != null) _pack = updated;
    }
    setState(() {
      _currentIndex++;
    });
    if (!_isMistakeReviewMode) {
      _saveProgress();
    }
    if (_currentIndex >= _sessionHands.length && !_isMistakeReviewMode) {
      await _completeSession();
    }
  }

  void _restartPack() {
    setState(() {
      _currentIndex = 0;
      _results.clear();
      _allHands = _pack.hands;
      _isMistakeReviewMode = false;
      _applyStackFilter();
    });
    _saveProgress();
  }

  Future<void> _exportResults() async {
    if (_results.isEmpty) return;
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'training_results_${_pack.name}_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${dir.path}/$fileName');
    final data = [
      for (final r in _results)
        {
          'hand': r.name,
          'expected': r.expected,
          'userAction': r.userAction,
          'correct': r.correct,
        }
    ];
    await file.writeAsString(jsonEncode(data));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Результаты сохранены: $fileName'),
          action: SnackBarAction(
            label: 'Открыть',
            onPressed: () {
              OpenFilex.open(file.path);
            },
          ),
        ),
      );
    }
  }

  Future<void> _exportMarkdown() async {
    if (_results.isEmpty) return;
    final total = _results.length;
    final correct = _results.where((r) => r.correct).length;
    final mistakes = _results.where((r) => !r.correct).toList()
      ..sort((a, b) {
        final diffA = a.evaluation.expectedEquity - a.evaluation.userEquity;
        final diffB = b.evaluation.expectedEquity - b.evaluation.userEquity;
        return diffB.compareTo(diffA);
      });
    final accuracy = total > 0 ? (correct * 100 / total).toStringAsFixed(1) : '0';
    final date = DateTime.now();
    final percent = total > 0 ? (correct * 100 / total).toStringAsFixed(2) : '0';

    final buffer = StringBuffer()
      ..writeln('# Training Session')
      ..writeln()
      ..writeln('- **Date:** ${formatDateTime(date)}')
      ..writeln('- **Total hands:** $total')
      ..writeln('- **Correct answers:** $correct')
      ..writeln('- **Accuracy:** $percent%')
      ..writeln();

    if (mistakes.isNotEmpty) {
      buffer.writeln('## Mistakes');
      for (final m in mistakes) {
        final mark = m.correct ? '✔' : '✘';
        final hint = m.evaluation.hint;
        final line =
            '- $mark ${m.name}: expected `${m.expected}`, got `${m.userAction}`';
        buffer.writeln(line);
        if (hint != null && hint.isNotEmpty) {
          buffer.writeln('  Hint: $hint');
        }
        final userEq = m.evaluation.userEquity;
        final expectedEq = m.evaluation.expectedEquity;
        if (userEq != 0 && expectedEq != 0) {
          buffer.writeln(
              '  Equity: ${(userEq * 100).toStringAsFixed(0)}% → ${(expectedEq * 100).toStringAsFixed(0)}%');
          final userPct = (userEq * 100).toStringAsFixed(0);
          final expectedPct = (expectedEq * 100).toStringAsFixed(0);
          buffer.writeln('<div style="margin:4px 0;">');
          buffer.writeln(
              '<div style="display:flex;align-items:center;">'
              '<div style="background-color:#f44336;height:8px;width:$userPct%;"></div>'
              '<span style="margin-left:4px;font-size:12px;color:#f44336;">$userPct%</span>'
              '<span style="margin-left:4px;font-size:12px;">Ваше equity</span>'
              '</div>');
          buffer.writeln(
              '<div style="display:flex;align-items:center;margin-top:2px;">'
              '<div style="background-color:#4caf50;height:8px;width:$expectedPct%;"></div>'
              '<span style="margin-left:4px;font-size:12px;color:#4caf50;">$expectedPct%</span>'
              '<span style="margin-left:4px;font-size:12px;">Оптимальное</span>'
              '</div>');
          buffer.writeln('</div>');
        }
      }
    }

    final fileName =
        'training_${_pack.name}_${date.millisecondsSinceEpoch}.md';
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Markdown',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['md'],
    );
    if (savePath == null) return;
    final file = File(savePath);
    await file.writeAsString(buffer.toString());
    if (mounted) {
      final name = savePath.split(Platform.pathSeparator).last;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сохранён: $name')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MarkdownPreviewScreen(path: file.path),
        ),
      );
    }
  }

  Future<void> _exportHtml() async {
    if (_results.isEmpty) return;
    final total = _results.length;
    final correct = _results.where((r) => r.correct).length;
    final mistakes = _results.where((r) => !r.correct).toList()
      ..sort((a, b) {
        final diffA = a.evaluation.expectedEquity - a.evaluation.userEquity;
        final diffB = b.evaluation.expectedEquity - b.evaluation.userEquity;
        return diffB.compareTo(diffA);
      });
    final date = DateTime.now();
    final percent = total > 0 ? (correct * 100 / total).toStringAsFixed(2) : '0';

    final buffer = StringBuffer()
      ..writeln('# Training Session')
      ..writeln()
      ..writeln('- **Date:** ${formatDateTime(date)}')
      ..writeln('- **Total hands:** $total')
      ..writeln('- **Correct answers:** $correct')
      ..writeln('- **Accuracy:** $percent%')
      ..writeln();

    if (mistakes.isNotEmpty) {
      buffer.writeln('## Mistakes');
      for (final m in mistakes) {
        final mark = m.correct ? '✔' : '✘';
        final hint = m.evaluation.hint;
        final line =
            '- $mark ${m.name}: expected `${m.expected}`, got `${m.userAction}`';
        buffer.writeln(line);
        if (hint != null && hint.isNotEmpty) {
          buffer.writeln('  Hint: $hint');
        }
        final userEq = m.evaluation.userEquity;
        final expectedEq = m.evaluation.expectedEquity;
        if (userEq != 0 && expectedEq != 0) {
          buffer.writeln(
              '  Equity: ${(userEq * 100).toStringAsFixed(0)}% → ${(expectedEq * 100).toStringAsFixed(0)}%');
          final userPct = (userEq * 100).toStringAsFixed(0);
          final expectedPct = (expectedEq * 100).toStringAsFixed(0);
          buffer.writeln('<div style="margin:4px 0;">');
          buffer.writeln(
              '<div style="display:flex;align-items:center;">'
              '<div style="background-color:#f44336;height:8px;width:$userPct%;"></div>'
              '<span style="margin-left:4px;font-size:12px;color:#f44336;">$userPct%</span>'
              '<span style="margin-left:4px;font-size:12px;">Ваше equity</span>'
              '</div>');
          buffer.writeln(
              '<div style="display:flex;align-items:center;margin-top:2px;">'
              '<div style="background-color:#4caf50;height:8px;width:$expectedPct%;"></div>'
              '<span style="margin-left:4px;font-size:12px;color:#4caf50;">$expectedPct%</span>'
              '<span style="margin-left:4px;font-size:12px;">Оптимальное</span>'
              '</div>');
          buffer.writeln('</div>');
        }
      }
    }

    final markdown = buffer.toString();
    final htmlContent = _wrapHtml(md.markdownToHtml(markdown));
    final dir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final fileName =
        'training_pack_${DateTime.now().millisecondsSinceEpoch}.html';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(htmlContent);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сохранён: $fileName')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MarkdownPreviewScreen(path: file.path),
        ),
      );
    }
  }

  Future<void> _exportPdf() async {
    if (_results.isEmpty) return;

    final total = _results.length;
    final correct = _results.where((r) => r.correct).length;
    final mistakes = _results.where((r) => !r.correct).toList()
      ..sort((a, b) {
        final diffA = a.evaluation.expectedEquity - a.evaluation.userEquity;
        final diffB = b.evaluation.expectedEquity - b.evaluation.userEquity;
        return diffB.compareTo(diffA);
      });
    final date = DateTime.now();
    final percent =
        total > 0 ? (correct * 100 / total).toStringAsFixed(2) : '0';

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    pw.Widget buildBar(double value, PdfColor color, String label) {
      const barWidth = 200.0;
      final width = barWidth * value.clamp(0.0, 1.0);
      return pw.Row(
        children: [
          pw.Container(width: width, height: 8, color: color),
          pw.SizedBox(width: 4),
          pw.Text('${(value * 100).toStringAsFixed(0)}%',
              style: pw.TextStyle(font: regularFont, color: color, fontSize: 10)),
          pw.SizedBox(width: 4),
          pw.Text(label,
              style: pw.TextStyle(font: regularFont, fontSize: 10)),
        ],
      );
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Text('Training Session',
                style: pw.TextStyle(font: boldFont, fontSize: 24)),
            pw.SizedBox(height: 16),
            pw.Text('Date: ${formatDateTime(date)}',
                style: pw.TextStyle(font: regularFont)),
            pw.Text('Total hands: $total',
                style: pw.TextStyle(font: regularFont)),
            pw.Text('Correct answers: $correct',
                style: pw.TextStyle(font: regularFont)),
            pw.Text('Accuracy: $percent%',
                style: pw.TextStyle(font: regularFont)),
            pw.SizedBox(height: 16),
            if (mistakes.isNotEmpty)
              pw.Text('Mistakes',
                  style: pw.TextStyle(font: boldFont, fontSize: 18)),
            if (mistakes.isNotEmpty) pw.SizedBox(height: 8),
            for (final m in mistakes)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${m.name}: expected ${m.expected}, got ${m.userAction}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                  if (m.evaluation.hint != null &&
                      m.evaluation.hint!.isNotEmpty)
                    pw.Text('Hint: ${m.evaluation.hint}',
                        style:
                            pw.TextStyle(font: regularFont, fontSize: 10)),
                  if (m.evaluation.userEquity != 0 &&
                      m.evaluation.expectedEquity != 0)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Equity: ${(m.evaluation.userEquity * 100).toStringAsFixed(0)}% → ${(m.evaluation.expectedEquity * 100).toStringAsFixed(0)}%',
                          style: pw.TextStyle(
                              font: regularFont, fontSize: 10),
                        ),
                        pw.SizedBox(height: 2),
                        buildBar(m.evaluation.userEquity, PdfColors.red,
                            'Ваше equity'),
                        buildBar(m.evaluation.expectedEquity, PdfColors.green,
                            'Оптимальное'),
                      ],
                    ),
                  pw.SizedBox(height: 12),
                ],
              ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final dir =
        await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final fileName =
        'training_pack_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сохранён: $fileName')),
      );
    }
  }

  String _wrapHtml(String body) {
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
body { font-family: sans-serif; padding: 16px; }
</style>
</head>
<body>$body</body>
</html>
''';
  }

  Future<void> _importPack() async {
    final before = {
      for (final p in context.read<TrainingPackStorageService>().packs) p.id
    };
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    final msg = await context.read<TrainingPackStorageService>().importPack(bytes);
    if (!mounted) return;
    final packs = context.read<TrainingPackStorageService>().packs;
    TrainingPack? imported;
    for (final p in packs) {
      if (!before.contains(p.id)) {
        imported = p;
        break;
      }
    }
    if (msg == null && imported != null) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TrainingPackScreen(pack: imported)),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg ?? 'Пак импортирован')),
    );
  }

  Future<void> _importSpotsCsv() async {
    final spots = await _spotFileService.importSpotsCsv(context);
    if (spots.isNotEmpty && mounted) {
      setState(() {
        _allSpots = spots;
        _applyStackFilter();
      });
      await _saveSpots();
    }
  }
  Future<void> _exportSpotsMarkdown() async {
    await _spotFileService.exportSpotsMarkdown(context, _spots);
  }

  Future<void> _exportSpotsPdf() async {
    if (_spots.isEmpty) return;

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            pw.Text('Training Spots', style: pw.TextStyle(font: boldFont, fontSize: 24)),
            pw.SizedBox(height: 16),
            for (int i = 0; i < _spots.length; i++)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Spot ${i + 1}', style: pw.TextStyle(font: boldFont, fontSize: 18)),
                  pw.Bullet(
                    text: 'Hero index: ${_spots[i].heroIndex}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                  pw.Bullet(
                    text: 'Stacks: ${_spots[i].stacks.join(', ')}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                  pw.Bullet(
                    text: 'Actions: ${_spots[i].actions.map((a) => "${a.playerIndex}:${a.action}${a.amount != null ? ' ${a.amount}' : ''}").join(', ')}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                  if (_spots[i].strategyAdvice != null && _spots[i].strategyAdvice!.isNotEmpty)
                    pw.Bullet(
                      text: 'Advice: ${_spots[i].strategyAdvice!.join(', ')}',
                      style: pw.TextStyle(font: regularFont),
                    ),
                  pw.SizedBox(height: 8),
                ],
              ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();

    final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final fileName = 'spots_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await file.writeAsBytes(bytes);
    await Printing.sharePdf(bytes: bytes, filename: fileName);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Файл сохранён: $fileName'),
          action: SnackBarAction(
            label: 'Открыть',
            onPressed: () {
              OpenFilex.open(file.path);
            },
          ),
        ),
      );
    }
  }

  Future<void> _exportHistoryJson() async {
    try {
      final service = TrainingHistoryExportService(
          storage: context.read<TrainingSpotStorageService>());
      final file = await service.exportToJson();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сохранён: ${file.path}')),
      );
    } catch (e, st) {
      ErrorLoggerService.instance
          .logError('History export failed', e, st);
      if (mounted) {
        ErrorLoggerService.instance
            .reportToUser(context, 'Ошибка экспорта');
      }
    }
  }

  Future<void> _importHistoryJson() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final file = File(path);
    final service = TrainingHistoryImportService(
        storage: context.read<TrainingSpotStorageService>());
    final count = await service.importFromJson(file);
    if (!mounted) return;
    if (count > 0) {
      await _loadSpots();
      if (_spots.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrainingSpotDetailScreen(spot: _spots.last),
          ),
        );
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported $count spots')),
    );
  }

  void _showSavedResults() {
    if (_previousResults.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Предыдущая сессия',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final r in _previousResults)
              Text(
                '${r.name}: ожидалось ${r.expected}, ваше действие ${r.userAction}',
                style: const TextStyle(color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }

  void _showHistory() {
    if (_history.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'История',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final h in _history.take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        formatDateTime(h.date),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Text(
                      '${h.correct}/${h.total}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${h.accuracy.toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _repeatMistakes() {
    final mistakes = _results.where((r) => !r.correct).toList();
    if (mistakes.isEmpty) return;

    final List<SavedHand> mistakeHands = [];
    for (final m in mistakes) {
      try {
        mistakeHands.add(
          _pack.hands.firstWhere((h) => h.name == m.name),
        );
      } catch (e, st) {
        ErrorLoggerService.instance
            .logError('Failed to find hand ${m.name}', e, st);
      }
    }

    setState(() {
      _allHands = mistakeHands;
      _results
        ..clear()
        ..addAll(mistakes);
      _currentIndex = 0;
      _isMistakeReviewMode = true;
      _applyStackFilter();
    });
  }

  void _openAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingAnalysisScreen(
          results: List.from(_results),
          pack: _pack,
        ),
      ),
    );
  }

  Future<void> _completeSession() async {
    final total = _results.length;
    final correct = _results.where((r) => r.correct).length;
    final success = total > 0 && correct == total;
    final tasks = [
      for (final r in _results)
        SessionTaskResult(
          question: r.name,
          selectedAnswer: r.userAction,
          correctAnswer: r.expected,
          correct: r.correct,
        )
    ];
    final result = TrainingSessionResult(
      date: DateTime.now(),
      total: total,
      correct: correct,
      tasks: tasks,
    );

    if (widget.persistResults) {
      widget.pack.history.add(result);

      final prefs = await SharedPreferences.getInstance();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/training_packs.json');
      List<TrainingPack> packs = [];
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          final data = jsonDecode(content);
          if (data is List) {
            packs = [
              for (final item in data)
                if (item is Map<String, dynamic>)
                  TrainingPack.fromJson(Map<String, dynamic>.from(item))
            ];
          }
        } catch (e, st) {
          ErrorLoggerService.instance
              .logError('Failed to read training packs', e, st);
        }
      }

      final idx = packs.indexWhere((p) => p.name == widget.pack.name);
      if (idx != -1) {
        packs[idx] = widget.pack;
      } else {
        packs.add(widget.pack);
      }

      await file.writeAsString(jsonEncode([for (final p in packs) p.toJson()]));
    }

    await _saveCurrentResults();
    await _promptForComment();
    unawaited(context.read<CloudSyncService>().syncUp());

    widget.onComplete?.call(success);
  }

  Widget _buildSummary() {
    final total = _results.length;
    final correct = _results.where((r) => r.correct).length;
    final mistakes = _results.where((r) => !r.correct).toList();
    final accuracy = total > 0 ? (correct * 100 / total).toStringAsFixed(1) : '0';
    final evs = <double>[];
    final icms = <double>[];
    for (final r in _results) {
      final ev = r.evaluation.ev;
      if (ev != null) evs.add(ev);
      final icm = r.evaluation.icmEv;
      if (icm != null) icms.add(icm);
    }
    if (evs.isEmpty && icms.isEmpty) {
      evs.addAll([for (final h in _sessionHands) if (h.heroEv != null) h.heroEv!]);
      icms.addAll([for (final h in _sessionHands) if (h.heroIcmEv != null) h.heroIcmEv!]);
    }
    final avgPair = context.read<TrainingStatsService>().sessionEvIcmAvg(_sessionHands);
    final evAvg = evs.isNotEmpty ? evs.reduce((a, b) => a + b) / evs.length : avgPair.key;
    final icmAvg = icms.isNotEmpty ? icms.reduce((a, b) => a + b) / icms.length : avgPair.value;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Результаты',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (mistakes.isNotEmpty) ...[
              const Text('Ошибки:'),
              const SizedBox(height: 8),
              for (final m in mistakes)
                Text('${m.name}: ожидалось ${m.expected}, ваше действие ${m.userAction}'),
            ] else ...[
              const Text('Ошибок нет!'),
            ],
            const SizedBox(height: 24),
            PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 0,
                sections: [
                  PieChartSectionData(
                    value: correct.toDouble(),
                    color: Colors.green,
                    radius: 80,
                    title: total > 0
                        ? '${(correct * 100 / total).toStringAsFixed(0)}%'
                        : '0%',
                    titleStyle: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: (total - correct).toDouble(),
                    color: Colors.red,
                    radius: 80,
                    title: total > 0
                        ? '${((total - correct) * 100 / total).toStringAsFixed(0)}%'
                        : '0%',
                    titleStyle: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (evs.length + icms.length >= 2) ...[
              const SizedBox(height: 16),
              _EvIcmLineChart(evs: evs, icms: icms),
              const SizedBox(height: 24),
            ] else
              const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _openAnalysis,
              child: const Text('Детальный анализ'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _restartPack,
              child: const Text('Начать заново'),
            ),
            const SizedBox(height: 12),
            Text('Сыграно рук: $total'),
            Text('Верные действия: $correct'),
            Text('Ошибок: ${total - correct}'),
            Text('Точность: $accuracy%'),
            Text('EV avg: ${evAvg.toStringAsFixed(1)}'),
            Text('ICM avg: ${icmAvg.toStringAsFixed(3)}'),
            Builder(
              builder: (context) {
                final stats = context.watch<TrainingStatsService>();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Текущий стрик: ${stats.currentStreak} дней'),
                    Text('Лучший стрик: ${stats.bestStreak} дней'),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            if (_sessionComment != null && _sessionComment!.isNotEmpty) ...[
              const Text('Комментарий: \$_sessionComment',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
            ],
            ElevatedButton(
              onPressed: _promptForComment,
              child: Text(
                _sessionComment == null || _sessionComment!.isEmpty
                    ? 'Добавить комментарий'
                    : 'Изменить комментарий',
              ),
            ),
            const SizedBox(height: 12),
            if (!_isMistakeReviewMode && mistakes.isNotEmpty) ...[
              ElevatedButton(
                onPressed: _repeatMistakes,
                child: const Text('Повторить ошибки'),
              ),
              const SizedBox(height: 12),
            ],
            if (!_isMistakeReviewMode && _previousResults.isNotEmpty) ...[
              ElevatedButton(
                onPressed: _showSavedResults,
                child: const Text('Предыдущая сессия'),
              ),
              const SizedBox(height: 12),
            ],
            if (!_isMistakeReviewMode && _history.isNotEmpty) ...[
              ElevatedButton(
                onPressed: _showHistory,
                child: const Text('История'),
              ),
              const SizedBox(height: 12),
            ],
            if (!_isMistakeReviewMode) ...[
              ElevatedButton(
                onPressed: _exportResults,
                child: const Text('Сохранить результаты'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _pack.isBuiltIn ? null : _sharePack,
                child: const Text('Share Pack'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _exportMarkdown,
                child: const Text('Export to Markdown'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _exportHtml,
                child: const Text('Export to HTML'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _exportPdf,
                child: const Text('Экспорт в PDF'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _exportHistoryJson,
                child: const Text('Export JSON'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _importHistoryJson,
                child: const Text('Import JSON'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _importSpotsCsv,
                child: const Text('Импорт из CSV'),
              ),
              const SizedBox(height: 12),
              _buildImportedSpotsList(),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _spots.isEmpty ? null : _exportSpotsMarkdown,
                child: const Text('Экспортировать в Markdown'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _spots.isEmpty ? null : _exportSpotsPdf,
                child: const Text('Экспорт в PDF'),
              ),
            ],
            const SizedBox(height: 24),
            _buildHistory(),
          ],
        ),
      ),
      );
  }

  Widget _buildInfoCard() {
    final subtitleCount = _pack.spots.isNotEmpty
        ? '${_pack.spots.length} spots'
        : '${_pack.hands.length} hands';
    final leading = _pack.isBuiltIn
        ? const Text('📦')
        : InfoTooltip(
            message: _pack.colorTag.isEmpty
                ? 'No color tag'
                : 'Color tag ${_pack.colorTag} (tap to edit)',
            child: _pack.colorTag.isEmpty
                ? const Icon(Icons.circle_outlined, color: Colors.white24)
                : Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colorFromHex(_pack.colorTag),
                      shape: BoxShape.circle,
                    ),
                  ),
          );
    final pct = _pack.pctComplete;
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.all(16),
      child: ListTile(
        leading: leading,
        trailing: DropdownButton<String>(
          value: _stackFilter ?? 'any',
          dropdownColor: AppColors.cardBackground,
          style: const TextStyle(color: Colors.white),
          onChanged: (v) => _setStackFilter(v == 'any' ? null : v),
          items: [
            const DropdownMenuItem(value: 'any', child: Text('Any Stack')),
            for (final r in _stackRanges)
              DropdownMenuItem(value: r, child: Text('$r BB')),
          ],
        ),
        title: Row(
          children: [
            Expanded(child: Text(_pack.name)),
            const SizedBox(width: 4),
            DifficultyChip(_pack.difficulty),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InfoTooltip(
                  message: _pack.gameType == GameType.tournament
                      ? 'Blind levels, ICM pressure.'
                      : '100 BB deep, no blind escalation.',
                  child: Text(_pack.gameType.label),
                ),
                const Text(' • '),
                Text(subtitleCount),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white12,
              color: pct >= 1
                  ? Colors.green
                  : pct >= .5
                      ? Colors.amber
                      : Colors.red,
              minHeight: 6,
            ),
            const SizedBox(height: 4),
            ValueListenableBuilder<DateTime?>(
              valueListenable:
                  context.read<TrainingPackCloudSyncService>().lastSync,
              builder: (context, value, child) {
                final t = value == null
                    ? '-'
                    : formatDateTime(value.toLocal());
                return Text('Синхр.: $t',
                    style: const TextStyle(fontSize: 12, color: Colors.white70));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportedSpotsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: () =>
                _spotListKey.currentState?.clearFilters(),
            child: const Text('Очистить фильтры'),
          ),
        ),
        const SizedBox(height: 12),
        TrainingSpotList(
          key: _spotListKey,
          spots: _spots,
          onEdit: (index) async {
            final spot = _spots[index];
            final baseIndex = _allSpots.indexOf(spot);
            final updated = await Navigator.push<TrainingSpot>(
              context,
              MaterialPageRoute(builder: (_) => SpotEditorScreen(initial: spot)),
            );
            if (updated == null) return;
            if (baseIndex != -1) _allSpots[baseIndex] = updated;
            setState(() {
              _applyStackFilter();
            });
            await _saveSpots();
            final newPack = TrainingPack(
              name: _pack.name,
              description: _pack.description,
              category: _pack.category,
              gameType: _pack.gameType,
              colorTag: _pack.colorTag,
              isBuiltIn: _pack.isBuiltIn,
              tags: _pack.tags,
              hands: _pack.hands,
              spots: _spots,
              difficulty: _pack.difficulty,
              history: _pack.history,
            );
            await context
                .read<TrainingPackStorageService>()
                .updatePack(_pack, newPack);
            setState(() => _pack = newPack);
          },
          onRemove: (index) async {
            final spot = _spots.removeAt(index);
            _allSpots.remove(spot);
            setState(() {
              _applyStackFilter();
            });
            await _saveSpots();
            final newPack = TrainingPack(
              name: _pack.name,
              description: _pack.description,
              category: _pack.category,
              gameType: _pack.gameType,
              colorTag: _pack.colorTag,
              isBuiltIn: _pack.isBuiltIn,
              tags: _pack.tags,
              hands: _pack.hands,
              spots: _spots,
              difficulty: _pack.difficulty,
              history: _pack.history,
            );
            await context
                .read<TrainingPackStorageService>()
                .updatePack(_pack, newPack);
            setState(() => _pack = newPack);
          },
          onChanged: _saveSpots,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              final item = _spots.removeAt(oldIndex);
              _spots.insert(newIndex, item);
              final baseItem = _allSpots.removeAt(_allSpots.indexOf(item));
              final target = newIndex >= _spots.length
                  ? null
                  : _spots[newIndex];
              final baseIndex =
                  target == null ? _allSpots.length : _allSpots.indexOf(target);
              _allSpots.insert(baseIndex, baseItem);
            });
            _saveSpots();
          },
        ),
      ],
    );
  }

  Widget _buildHistory() {
    final entries = List<TrainingSessionResult>.from(widget.pack.history)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.bar_chart, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'История тренировок',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          const Text('История пуста', style: TextStyle(color: Colors.white54))
        else
          for (final r in entries)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2B2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      formatDateTime(r.date),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Text(
                    '${r.correct}/${r.total}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    r.total > 0
                        ? '${(r.correct * 100 / r.total).toStringAsFixed(0)}%'
                        : '0%',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildStats() {
    final data = [..._pack.history]..sort((a, b) => a.date.compareTo(b.date));
    if (data.isEmpty) {
      return const Center(child: Text('No stats'));
    }
    final spots = <FlSpot>[];
    double sum = 0;
    for (var i = 0; i < data.length; i++) {
      final acc = data[i].total == 0
          ? 0.0
          : data[i].correct * 100 / data[i].total;
      sum += acc;
      spots.add(FlSpot(i.toDouble(), acc));
    }
    final avg = sum / data.length;
    final step = (data.length / 6).ceil();
    final line = LineChartBarData(
      spots: spots,
      isCurved: true,
      color: Colors.greenAccent,
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.greenAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${avg.toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) =>
                      const FlLine(color: Colors.white24, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) return const SizedBox.shrink();
                        if (i % step != 0 && i != data.length - 1) {
                          return const SizedBox.shrink();
                        }
                        final d = data[i].date;
                        final label =
                            '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
                        return Text(
                          label,
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    left: BorderSide(color: Colors.white24),
                    bottom: BorderSide(color: Colors.white24),
                  ),
                ),
                lineBarsData: [line],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hands = _sessionHands;
    final bool completed = _currentIndex >= hands.length;

    Widget content;
    if (hands.isEmpty) {
      content = const Center(child: Text('Нет раздач'));
    } else if (completed) {
      content = _buildSummary();
    } else {
      content = Column(
        children: [
          LinearProgressIndicator(
            value: _currentIndex / hands.length,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3B3E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _pack.category,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                InfoTooltip(
                  message: _pack.gameType == GameType.tournament
                      ? 'Blind levels, ICM pressure.'
                      : '100 BB deep, no blind escalation.',
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3B3E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _pack.gameType.label,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                DifficultyChip(_pack.difficulty),
                if (_pack.spots.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3B3E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Spots: ${_pack.spots.length}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: MultiProvider(
                  providers: [
                    ChangeNotifierProvider(create: (_) => PlayerProfileService()),
                    ChangeNotifierProvider(create: (_) => PlayerManagerService(context.read<PlayerProfileService>())),
                    Provider<ServiceRegistry>(
                      create: (_) => ServiceRegistry()
                        ..register<EvaluationExecutor>(
                            EvaluationExecutorService()),
                    ),
                    Provider(
                      create: (context) => TrainingSessionController(
                        registry: context.read<ServiceRegistry>(),
                      ),
                    ),
                  ],
                  child: Builder(
                    builder: (context) => ChangeNotifierProvider(
                      create: (_) {
                        final history = PotHistoryService();
                        final potSync = PotSyncService(historyService: history);
                        final stackService = StackManagerService(
                          Map<int, int>.from(
                              context.read<PlayerManagerService>().initialStacks),
                          potSync: potSync,
                        );
                        return PlaybackManagerService(
                          stackService: stackService,
                          potSync: potSync,
                          actionSync: context.read<ActionSyncService>(),
                        );
                      },
                      child: Builder(
                        builder: (context) => Provider(
                          create: (_) => BoardSyncService(
                            playerManager: context.read<PlayerManagerService>(),
                            actionSync: context.read<ActionSyncService>(),
                          ),
                          child: Builder(
                            builder: (context) {
                              final lockService = TransitionLockService();
                              final reveal = BoardRevealService(
                                lockService: lockService,
                                boardSync: context.read<BoardSyncService>(),
                              );
                              return MultiProvider(
                                providers: [
                                  Provider<BoardRevealService>.value(value: reveal),
                                  ChangeNotifierProvider(
                                    create: (_) => BoardManagerService(
                                      playerManager: context.read<PlayerManagerService>(),
                                      actionSync: context.read<ActionSyncService>(),
                                      playbackManager: context.read<PlaybackManagerService>(),
                                      lockService: lockService,
                                      boardSync: context.read<BoardSyncService>(),
                                      boardReveal: reveal,
                                    ),
                                  ),
                                  Provider(
                                    create: (_) => BoardEditingService(
                                      boardManager: context.read<BoardManagerService>(),
                                      boardSync: context.read<BoardSyncService>(),
                                      playerManager: context.read<PlayerManagerService>(),
                                      profile: context.read<PlayerProfileService>(),
                                    ),
                                  ),
                                  Provider(
                                    create: (_) => PlayerEditingService(
                                      playerManager: context.read<PlayerManagerService>(),
                                      stackService: context.read<PlaybackManagerService>().stackService,
                                      playbackManager: context.read<PlaybackManagerService>(),
                                      profile: context.read<PlayerProfileService>(),
                                    ),
                                  ),
                                ],
                                child: Builder(
                                  builder: (context) => PokerAnalyzerScreen(
                                    key: _analyzerKey,
                                    initialHand: hands[_currentIndex],
                                    actionSync: context.read<ActionSyncService>(),
                                    foldedPlayersService:
                                        context.read<FoldedPlayersService>(),
                                    allInPlayersService:
                                        context.read<AllInPlayersService>(),
                                    handContext: CurrentHandContextService(),
                                  playbackManager:
                                      context.read<PlaybackManagerService>(),
                                  stackService: context
                                      .read<PlaybackManagerService>()
                                      .stackService,
                                  potSyncService: context
                                      .read<PlaybackManagerService>()
                                      .potSync,
                                  boardManager: context.read<BoardManagerService>(),
                                  boardSync: context.read<BoardSyncService>(),
                                  boardEditing:
                                      context.read<BoardEditingService>(),
                                  playerEditing:
                                      context.read<PlayerEditingService>(),
                                  playerManager:
                                      context.read<PlayerManagerService>(),
                                  playerProfile:
                                      context.read<PlayerProfileService>(),
                                  actionTagService: context
                                      .read<PlayerProfileService>()
                                      .actionTagService,
                                  boardReveal: context.read<BoardRevealService>(),
                                  lockService: lockService,
                                ),
                              ),
                              );
                            },
                          ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentIndex == 0 ? null : _previousHand,
                  child: const Text('⬅ Назад'),
                ),
                if (_currentIndex < hands.length)
                  ElevatedButton(
                    onPressed: _nextHand,
                    child: const Text('Следующая раздача ➡'),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _pack);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _changeColor,
                behavior: HitTestBehavior.translucent,
                child: InfoTooltip(
                  message: _pack.colorTag.isEmpty
                      ? 'No color tag'
                      : 'Color tag ${_pack.colorTag} (tap to edit)',
                  child: _pack.colorTag.isEmpty
                      ? const Icon(Icons.circle_outlined, color: Colors.white24, size: 16)
                      : Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: colorFromHex(_pack.colorTag),
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _isMistakeReviewMode
                      ? '${_pack.name} — Повторение ошибок'
                      : _pack.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [SyncStatusIcon.of(context),
            IconButton(
              icon: Icon(
                  _pinned ? Icons.push_pin : Icons.push_pin_outlined),
              onPressed: _togglePinned,
            ),
            if (_pack.pctComplete > 0 && _pack.pctComplete < 1)
              IconButton(
                icon: const Icon(Icons.play_arrow),
                tooltip: 'Resume',
                onPressed: () {
                  setState(() {
                    _currentIndex =
                        _pack.history.isNotEmpty ? _pack.history.last.total : 0;
                    _allHands = _pack.hands;
                    _applyStackFilter();
                    _isMistakeReviewMode = false;
                  });
                },
              ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editPack,
            ),
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Экспорт пакета',
              onPressed: _exportPack,
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share',
              onPressed: _pack.isBuiltIn ? null : _sharePack,
            ),
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: 'Импорт пакета',
              onPressed: _importPack,
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'reset') _clearProgress();
                if (v == 'duplicate') _duplicatePack();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'reset',
                  enabled: _pack.history.isNotEmpty,
                  child: const Text('Сбросить прогресс'),
                ),
                PopupMenuItem(
                  value: 'duplicate',
                  enabled: !_pack.isBuiltIn,
                  child: const Text('Создать копию'),
                ),
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabs,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.white70,
                  indicator: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.zero,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Play'),
                    Tab(text: 'History'),
                    Tab(text: 'Stats'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            Column(
              children: [
                _buildInfoCard(),
                Expanded(child: content),
              ],
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildHistory(),
            ),
            _buildStats(),
          ],
        ),
        backgroundColor: const Color(0xFF1B1C1E),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSpot,
        label: const Text('＋ Spot'),
      ),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_saveProgress());
    _tabs.dispose();
    PinnedLearningService.instance.removeListener(_updatePinned);
    super.dispose();
  }
}

class TrainingAnalysisScreen extends StatefulWidget {
  final List<ResultEntry> results;
  final TrainingPack pack;

  const TrainingAnalysisScreen({
    super.key,
    required this.results,
    required this.pack,
  });

  @override
  State<TrainingAnalysisScreen> createState() => _TrainingAnalysisScreenState();
}

class _TrainingAnalysisScreenState extends State<TrainingAnalysisScreen> {
  bool _onlyErrors = false;
  @override
  void dispose() {
    final history = context.read<CloudTrainingHistoryService>();
    // Ignore result as this runs during dispose
    unawaited(history.saveSession(widget.results));
    super.dispose();
  }

  Widget _buildEquityBar(double value, Color color, String label) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth * value.clamp(0.0, 1.0);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: width,
              height: 8,
              color: color,
            ),
            const SizedBox(width: 4),
            Text('${(value * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      );
    });
  }

  Future<void> _exportMarkdown(BuildContext context) async {
    final mistakes = widget.results.where((r) => !r.correct).toList();
    if (mistakes.isEmpty) return;
    final buffer = StringBuffer();
    for (final r in mistakes) {
      buffer.writeln(
          '- ${r.name}: вы `${r.userAction}`, ожидалось `${r.expected}`. Пояснение: ...');
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/training_analysis.md');
      await file.writeAsString(buffer.toString());
      await Share.shareXFiles([XFile(file.path)], text: 'training_analysis.md');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл сохранён: training_analysis.md')),
        );
      }
    } catch (e, st) {
      ErrorLoggerService.instance.logError('Markdown export failed', e, st);
      if (context.mounted) {
        ErrorLoggerService.instance
            .reportToUser(context, 'Ошибка экспорта');
      }
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    final mistakes = widget.results.where((r) => !r.correct).toList();
    if (mistakes.isEmpty) return;

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Text('Ошибки сессии',
              style: pw.TextStyle(font: boldFont, fontSize: 24)),
          pw.SizedBox(height: 16),
          for (final m in mistakes)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(m.name,
                    style: pw.TextStyle(font: boldFont, fontSize: 16)),
                pw.Text('Вы: ${m.userAction}',
                    style: pw.TextStyle(font: regularFont)),
                pw.Text('Ожидалось: ${m.expected}',
                    style: pw.TextStyle(font: regularFont)),
                pw.Text('Результат: ошибка',
                    style: pw.TextStyle(font: regularFont)),
                pw.SizedBox(height: 12),
              ],
            ),
        ],
      ),
    );

    try {
      final bytes = await pdf.save();
      final dir =
          await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/session_mistakes.pdf');
      await file.writeAsBytes(bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл сохранён: session_mistakes.pdf')),
        );
      }
    } catch (e, st) {
      ErrorLoggerService.instance.logError('PDF export failed', e, st);
      if (context.mounted) {
        ErrorLoggerService.instance
            .reportToUser(context, 'Ошибка экспорта');
      }
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    final dir =
        await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/session_mistakes.pdf');
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл не найден')),
        );
      }
      return;
    }

    await Share.shareXFiles([XFile(file.path)], text: 'session_mistakes.pdf');
  }

  Future<void> _sharePack() async {
    final file = await context
        .read<TrainingPackStorageService>()
        .exportPackTemp(widget.pack);
    if (!mounted || file == null) return;
    await Share.shareXFiles([XFile(file.path)], text: 'Check out my Poker Analyzer pack!');
    if (await file.exists()) await file.delete();
  }

  @override
  Widget build(BuildContext context) {
    final results = _onlyErrors
        ? widget.results.where((r) => !r.correct).toList()
        : widget.results;
    final mistakes = results.where((r) => !r.correct).toList();
    final Map<String, int> actionCounts = {};
    for (final m in mistakes) {
      actionCounts[m.userAction] = (actionCounts[m.userAction] ?? 0) + 1;
    }
    final dataMap = {
      for (final e in actionCounts.entries) e.key: e.value.toDouble()
    };
    final total = dataMap.values.fold<double>(0, (p, e) => p + e);
    final baseColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Анализ тренировки'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context),
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: 'Экспорт',
            onPressed: () => _exportMarkdown(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Поделиться',
            onPressed: widget.pack.isBuiltIn ? null : _sharePack,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: results.isEmpty
          ? const Center(
              child: Text(
                'Нет данных',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Только ошибки',
                          style: TextStyle(color: Colors.white)),
                      Switch(
                        value: _onlyErrors,
                        onChanged: (v) => setState(() => _onlyErrors = v),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                Expanded(
                  bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(8),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Назад'),
        ),
      ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length + (mistakes.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= results.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                              children: [
                                PieChart(
                                  PieChartData(
                                    sectionsSpace: 0,
                                    sections: [
                                      for (var i = 0; i < dataMap.length; i++)
                                        PieChartSectionData(
                                          value: dataMap.values.elementAt(i),
                                          color:
                                              baseColors[i % baseColors.length],
                                          title:
                                              '${(dataMap.values.elementAt(i) * 100 / total).toStringAsFixed(0)}%',
                                          titleStyle:
                                              const TextStyle(color: Colors.white),
                                        ),
                                    ],
                                  ),
                                ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _exportPdf(context),
                          child: const Text('PDF Export'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _sharePdf(context),
                          child: const Text('Поделиться'),
                        ),
                      ],
                    ),
                  );
                }
                final m = results[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2B2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        m.correct ? Icons.check : Icons.close,
                        color: m.correct ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Вы: ${m.userAction}',
                              style: const TextStyle(color: Colors.red),
                            ),
                            Text(
                              'Ожидалось: ${m.expected}',
                              style: const TextStyle(color: Colors.green),
                            ),
                            if (m.evaluation.hint != null &&
                                m.evaluation.hint!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  m.evaluation.hint!,
                                  style:
                                      const TextStyle(color: Colors.white70),
                                ),
                              ),
                            _buildEquityBar(m.evaluation.userEquity, Colors.red,
                                'Ваше equity'),
                            _buildEquityBar(m.evaluation.expectedEquity,
                                Colors.green, 'Оптимальное'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _EvIcmLineChart extends StatelessWidget {
  final List<double> evs;
  final List<double> icms;
  const _EvIcmLineChart({required this.evs, required this.icms});

  @override
  Widget build(BuildContext context) {
    final len = math.max(evs.length, icms.length);
    if (len < 2) return const SizedBox.shrink();
    final evSpots = <FlSpot>[];
    final icmSpots = <FlSpot>[];
    double minY = 0;
    double maxY = 0;
    for (var i = 0; i < evs.length; i++) {
      final v = evs[i];
      if (v < minY) minY = v;
      if (v > maxY) maxY = v;
      evSpots.add(FlSpot(i.toDouble(), v));
    }
    for (var i = 0; i < icms.length; i++) {
      final v = icms[i];
      if (v < minY) minY = v;
      if (v > maxY) maxY = v;
      icmSpots.add(FlSpot(i.toDouble(), v));
    }
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }
    final interval = (maxY - minY) / 4;
    final step = (len / 6).ceil();
    return Container(
      height: responsiveSize(context, 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (v) =>
                const FlLine(color: Colors.white24, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= len) return const SizedBox.shrink();
                  if (i % step != 0 && i != len - 1) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '${i + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              left: BorderSide(color: Colors.white24),
              bottom: BorderSide(color: Colors.white24),
            ),
          ),
          lineBarsData: [
            if (evSpots.isNotEmpty)
              LineChartBarData(
                spots: evSpots,
                color: AppColors.evPre,
                barWidth: 2,
                isCurved: false,
                dotData: const FlDotData(show: false),
              ),
            if (icmSpots.isNotEmpty)
              LineChartBarData(
                spots: icmSpots,
                color: AppColors.icmPre,
                barWidth: 2,
                isCurved: false,
                dotData: const FlDotData(show: false),
              ),
          ],
        ),
      ),
    );
  }
}
