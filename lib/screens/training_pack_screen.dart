import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_file/open_file.dart';
import 'package:fl_chart/fl_chart.dart';

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../models/training_pack.dart';
import '../models/saved_hand.dart';
import 'poker_analyzer_screen.dart';
import 'create_pack_screen.dart';

class _ResultEntry {
  final String name;
  final String expected;
  final String userAction;
  final bool correct;

  _ResultEntry(this.name, this.expected, this.userAction, this.correct);
}

class TrainingPackScreen extends StatefulWidget {
  final TrainingPack pack;

  const TrainingPackScreen({super.key, required this.pack});

  @override
  State<TrainingPackScreen> createState() => _TrainingPackScreenState();
}

class _TrainingPackScreenState extends State<TrainingPackScreen> {
  final GlobalKey _analyzerKey = GlobalKey();
  int _currentIndex = 0;

  late TrainingPack _pack;

  /// Hands that are currently used in the session. By default it contains
  /// all hands from the training pack, but when the user chooses to repeat
  /// mistakes it becomes a filtered subset.
  late List<SavedHand> _sessionHands;

  /// Whether we are currently reviewing only the mistaken hands.
  bool _isMistakeReviewMode = false;

  final List<_ResultEntry> _results = [];

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  @override
  void initState() {
    super.initState();
    _pack = widget.pack;
    _sessionHands = _pack.hands;
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIndex = prefs.getInt('training_progress_${_pack.name}') ?? 0;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('training_progress_${_pack.name}', _currentIndex);
  }

  Future<_ResultEntry> _showFeedback() async {
    final state = _analyzerKey.currentState as dynamic;
    SavedHand? played;
    if (state != null) {
      try {
        final jsonStr = state.saveHand() as String;
        played = SavedHand.fromJson(jsonDecode(jsonStr));
      } catch (_) {}
    }
    final original = _sessionHands[_currentIndex];
    String userAct = '-';
    if (played != null) {
      for (final a in played.actions) {
        if (a.playerIndex == played.heroIndex) {
          userAct = a.action;
          break;
        }
      }
    }
    final expected = original.expectedAction ?? '-';
    final matched = userAct.toLowerCase() == expected.toLowerCase();
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            )
          ],
        ),
      ),
    );
    return _ResultEntry(original.name, expected, userAct, matched);
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
              OpenFile.open(file.path);
            },
          ),
        ),
      );
    }
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

  Future<void> _completeSession() async {
    final total = _results.length;
    final correct = _results.where((r) => r.correct).length;
    final result = TrainingSessionResult(
      date: DateTime.now(),
      total: total,
      correct: correct,
    );

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

  Widget _buildSummary() {
    final total = _results.length;
    final correct = _results.where((r) => r.correct).length;
    final mistakes = _results.where((r) => !r.correct).toList();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            const Text(
              'Результаты',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Сыграно рук: $total'),
            Text('Верные действия: $correct / $total'),
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
            ElevatedButton(
              onPressed: _restartPack,
              child: const Text('Начать заново'),
            ),
            const SizedBox(height: 12),
            if (!_isMistakeReviewMode && mistakes.isNotEmpty) ...[
              ElevatedButton(
                onPressed: _repeatMistakes,
                child: const Text('Повторить ошибки'),
              ),
              const SizedBox(height: 12),
            ],
            if (!_isMistakeReviewMode)
              ElevatedButton(
                onPressed: _exportResults,
                child: const Text('Сохранить результаты'),
              ),
            const SizedBox(height: 24),
            _buildHistory(),
          ],
        ),
      ),
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
                      _formatDate(r.date),
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
                child: PokerAnalyzerScreen(
                  key: _analyzerKey,
                  initialHand: hands[_currentIndex],
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
          title: Text(_pack.name),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editPack,
            ),
          ],
        ),
        body: body,
        backgroundColor: const Color(0xFF1B1C1E),
      ),
    );
  }
}
