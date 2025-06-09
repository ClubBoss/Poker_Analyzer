import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_pack.dart';
import 'poker_analyzer_screen.dart';

class TrainingPackScreen extends StatefulWidget {
  final TrainingPack pack;

  const TrainingPackScreen({super.key, required this.pack});

  @override
  State<TrainingPackScreen> createState() => _TrainingPackScreenState();
}

class _TrainingPackScreenState extends State<TrainingPackScreen> {
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

  void _previousHand() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _saveProgress();
    }
  }

  void _nextHand() {
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
              child: PokerAnalyzerScreen(
                key: ValueKey(_currentIndex),
                initialHand: hands[_currentIndex],
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
