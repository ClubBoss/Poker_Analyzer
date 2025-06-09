import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

import '../models/training_pack.dart';
import '../models/saved_hand.dart';
import 'poker_analyzer_screen.dart';

class TrainingPackScreen extends StatefulWidget {
  final TrainingPack pack;

  const TrainingPackScreen({super.key, required this.pack});

  @override
  State<TrainingPackScreen> createState() => _TrainingPackScreenState();
}

class _TrainingPackScreenState extends State<TrainingPackScreen> {
  final GlobalKey _analyzerKey = GlobalKey();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIndex =
          prefs.getInt('training_progress_${widget.pack.name}') ?? 0;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'training_progress_${widget.pack.name}', _currentIndex);
  }

  Future<void> _showFeedback() async {
    final state = _analyzerKey.currentState as dynamic;
    SavedHand? played;
    if (state != null) {
      try {
        final jsonStr = state.saveHand() as String;
        played = SavedHand.fromJson(jsonDecode(jsonStr));
      } catch (_) {}
    }
    final original = widget.pack.hands[_currentIndex];
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
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Обратная связь'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ваше действие: $userAct'),
            Text('Правильное действие: $expected'),
            const SizedBox(height: 8),
            Text(matched ? 'Верно!' : 'Неверно.'),
            if (original.feedbackText != null) ...[
              const SizedBox(height: 8),
              Text(original.feedbackText!),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  void _previousHand() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _saveProgress();
    }
  }

  Future<void> _nextHand() async {
    await _showFeedback();
    setState(() {
      _currentIndex++;
    });
    _saveProgress();
  }

  @override
  Widget build(BuildContext context) {
    final hands = widget.pack.hands;
    final bool completed = _currentIndex >= hands.length;

    Widget body;
    if (hands.isEmpty) {
      body = const Center(child: Text('Нет раздач'));
    } else if (completed) {
      body = const Center(child: Text('Пакет завершён'));
    } else {
      body = Column(
        children: [
          LinearProgressIndicator(
            value: _currentIndex / hands.length,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pack.name),
        centerTitle: true,
      ),
      body: body,
      backgroundColor: const Color(0xFF1B1C1E),
    );
  }
}
