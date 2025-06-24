import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../helpers/date_utils.dart';
import '../helpers/action_utils.dart';
import 'package:provider/provider.dart';

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/training_pack.dart';
import '../models/saved_hand.dart';
import '../models/session_task_result.dart';
import 'poker_analyzer_screen.dart';
import 'create_pack_screen.dart';
import '../services/training_pack_storage_service.dart';
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
import '../services/cloud_sync_service.dart';
import '../models/training_spot.dart';
import '../models/evaluation_result.dart';
import '../services/evaluation_executor_service.dart';
import '../widgets/replay_spot_widget.dart';
import '../models/result_entry.dart';
import '../widgets/common/training_spot_list.dart';
import 'markdown_preview_screen.dart';
import 'package:markdown/markdown.dart' as md;
import 'dart:async';
import '../services/cloud_training_history_service.dart';


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

  const TrainingPackScreen({
    super.key,
    required this.pack,
    this.hands,
    this.mistakeReviewMode = false,
    this.onComplete,
    this.persistResults = true,
  });

  @override
  State<TrainingPackScreen> createState() => _TrainingPackScreenState();
}

class _TrainingPackScreenState extends State<TrainingPackScreen> {
  final GlobalKey _analyzerKey = GlobalKey();
  final GlobalKey<TrainingSpotListState> _spotListKey =
      GlobalKey<TrainingSpotListState>();
  int _currentIndex = 0;

  static const List<String> _availableTags = ['BVB', 'ICM', 'Trap', 'KO'];

  late TrainingPack _pack;

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

  final TrainingImportExportService _importExportService =
      const TrainingImportExportService();
  final TrainingSpotFileService _spotFileService =
      const TrainingSpotFileService();
  late TrainingSpotStorageService _spotStorageService;
  List<TrainingSpot> _spots = [];

  @override
  void initState() {
    super.initState();
    _spotStorageService = TrainingSpotStorageService(
      cloud: context.read<CloudSyncService>(),
    );
    _pack = widget.pack;
    _sessionHands = widget.hands ?? _pack.hands;
    _isMistakeReviewMode = widget.mistakeReviewMode;
    _loadProgress();
    _loadSpots();
    _loadSavedResults();
  }

  Future<void> _loadProgress() async {
    if (_isMistakeReviewMode) {
      setState(() {
        _currentIndex = 0;
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
  }

  Future<void> _loadSpots() async {
    final loaded = await _spotStorageService.load();
    if (mounted && loaded.isNotEmpty) {
      setState(() => _spots = loaded);
    }
  }

  Future<void> _saveSpots() async {
    await _spotStorageService.save(_spots);
  }

  Future<void> _loadSavedResults() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'results_${_pack.name}';
    String? jsonStr = prefs.getString(key);
    if (jsonStr == null) {
      final cloud = context.read<CloudSyncService>();
      jsonStr = await cloud.loadResults(_pack.name);
      if (jsonStr != null) {
        await prefs.setString(key, jsonStr);
      }
    }
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
    } catch (_) {}
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
    final cloud = context.read<CloudSyncService>();
    await cloud.saveResults(_pack.name, jsonData);
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
        final jsonStr = state.saveHand() as String;
        played =
            SavedHandImportExportService.decode(jsonStr);
      } catch (_) {}
    }
    final original = _sessionHands[_currentIndex];
    String userAct = '-';
    if (played != null) {
      for (final a in played.actions) {
        if (isHeroAction(a, played.heroIndex)) {
          userAct = a.action;
          break;
        }
      }
    }
    final evaluation = context
        .read<EvaluationExecutorService>()
        .evaluate(TrainingSpot.fromSavedHand(original), userAct);
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
                  Text('Оцените спот',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70)),
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
                            builder: (_) =>
                                ReplaySpotWidget(spot: TrainingSpot.fromSavedHand(original)),
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
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePackScreen(initialPack: _pack),
      ),
    );
    if (updated is TrainingPack) {
      setState(() {
        _pack = TrainingPack(
          name: updated.name,
          description: updated.description,
          category: updated.category,
          hands: _pack.hands,
        );
      });
    }
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
    if (_results.length > _currentIndex) {
      _results[_currentIndex] = result;
    } else {
      _results.add(result);
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
      _sessionHands = _pack.hands;
      _isMistakeReviewMode = false;
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
              '<div style="background-color:#f44336;height:8px;width:${userPct}%;"></div>'
              '<span style="margin-left:4px;font-size:12px;color:#f44336;">${userPct}%</span>'
              '<span style="margin-left:4px;font-size:12px;">Ваше equity</span>'
              '</div>');
          buffer.writeln(
              '<div style="display:flex;align-items:center;margin-top:2px;">'
              '<div style="background-color:#4caf50;height:8px;width:${expectedPct}%;"></div>'
              '<span style="margin-left:4px;font-size:12px;color:#4caf50;">${expectedPct}%</span>'
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
              '<div style="background-color:#f44336;height:8px;width:${userPct}%;"></div>'
              '<span style="margin-left:4px;font-size:12px;color:#f44336;">${userPct}%</span>'
              '<span style="margin-left:4px;font-size:12px;">Ваше equity</span>'
              '</div>');
          buffer.writeln(
              '<div style="display:flex;align-items:center;margin-top:2px;">'
              '<div style="background-color:#4caf50;height:8px;width:${expectedPct}%;"></div>'
              '<span style="margin-left:4px;font-size:12px;color:#4caf50;">${expectedPct}%</span>'
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

  Future<void> _importPackFromFile() async {
    final service =
        Provider.of<TrainingPackStorageService>(context, listen: false);
    final pack = await service.importPack();
    if (!mounted) return;
    if (pack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка загрузки пакета')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пакет "${pack.name}" загружен')),
      );
    }
  }

  Future<void> _importSpotsCsv() async {
    final spots = await _spotFileService.importSpotsCsv(context);
    if (spots.isNotEmpty && mounted) {
      setState(() => _spots = spots);
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
      } catch (_) {}
    }

    setState(() {
      _sessionHands = mistakeHands;
      _results
        ..clear()
        ..addAll(mistakes);
      _currentIndex = 0;
      _isMistakeReviewMode = true;
    });
  }

  void _openAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingAnalysisScreen(results: List.from(_results)),
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
        } catch (_) {}
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
    await context
        .read<CloudSyncService>()
        .uploadSessionResult(_results, comment: _sessionComment);

    widget.onComplete?.call(success);
  }

  Widget _buildSummary() {
    final total = _results.length;
    final correct = _results.where((r) => r.correct).length;
    final mistakes = _results.where((r) => !r.correct).toList();
    final accuracy = total > 0 ? (correct * 100 / total).toStringAsFixed(1) : '0';

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
            const SizedBox(height: 12),
            if (_sessionComment != null && _sessionComment!.isNotEmpty) ...[
              Text('Комментарий: \$_sessionComment',
                  style: const TextStyle(color: Colors.white70)),
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
          onRemove: (index) {
            setState(() {
              _spots.removeAt(index);
            });
            _saveSpots();
          },
          onChanged: _saveSpots,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              final item = _spots.removeAt(oldIndex);
              _spots.insert(newIndex, item);
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
        Row(
          children: const [
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

  @override
  Widget build(BuildContext context) {
    final hands = _sessionHands;
    final bool completed = _currentIndex >= hands.length;

    Widget body;
    if (hands.isEmpty) {
      body = const Center(child: Text('Нет раздач'));
    } else if (completed) {
      body = _buildSummary();
    } else {
      body = Column(
        children: [
          LinearProgressIndicator(
            value: _currentIndex / hands.length,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3B3E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _pack.category,
                style: const TextStyle(color: Colors.white70),
              ),
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
                    Provider.value(value: EvaluationExecutorService()),
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
          title: Text(_isMistakeReviewMode
              ? '${_pack.name} — Повторение ошибок'
              : _pack.name),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editPack,
            ),
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: 'Импорт пакета',
              onPressed: _importPackFromFile,
            ),
          ],
        ),
        body: body,
        backgroundColor: const Color(0xFF1B1C1E),
      ),
    );
  }
}

class TrainingAnalysisScreen extends StatefulWidget {
  final List<ResultEntry> results;

  const TrainingAnalysisScreen({super.key, required this.results});

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
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ошибка экспорта')));
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
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ошибка экспорта')));
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
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: 'Экспорт',
            onPressed: () => _exportMarkdown(context),
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
                                  dataMap: dataMap,
                          colorList: [
                            for (var i = 0; i < dataMap.length; i++)
                              baseColors[i % baseColors.length],
                          ],
                          legendOptions: const LegendOptions(
                            legendTextStyle: TextStyle(color: Colors.white),
                          ),
                          chartValuesOptions: const ChartValuesOptions(
                            showChartValuesInPercentage: true,
                            showChartValueBackground: false,
                            chartValueStyle: TextStyle(color: Colors.white),
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
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(8),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Назад'),
        ),
      ),
    );
  }
}
