import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/lesson_streak_engine.dart';

class LessonStreakSummaryCard extends StatefulWidget {
  const LessonStreakSummaryCard({super.key});

  @override
  State<LessonStreakSummaryCard> createState() =>
      _LessonStreakSummaryCardState();
}

class _LessonStreakSummaryCardState extends State<LessonStreakSummaryCard> {
  static const _prefsKey = 'lesson_streak_summary_shown';
  static const _milestones = [3, 5, 7, 10, 14, 21, 30, 50, 100];

  bool _visible = false;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await LessonStreakEngine.instance.getCurrentStreak();
    final shown = prefs.getStringList(_prefsKey) ?? [];
    if (_milestones.contains(current) && !shown.contains('$current')) {
      shown.add('$current');
      await prefs.setStringList(_prefsKey, shown);
      if (!mounted) return;
      setState(() {
        _visible = true;
        _streak = current;
      });
    }
  }

  void _dismiss() {
    setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepOrange, Colors.orangeAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _dismiss,
            ),
          ),
          Text(
            "🔥 You're on a $_streak-day learning streak!",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep it up!',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
