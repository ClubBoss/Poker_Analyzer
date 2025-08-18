import 'dart:async';

import 'package:flutter/material.dart';

import '../services/daily_streak_tracker_service.dart';

/// Small badge displaying current daily training streak.
class DailyStreakBadgeWidget extends StatefulWidget {
  const DailyStreakBadgeWidget({super.key});

  @override
  State<DailyStreakBadgeWidget> createState() => _DailyStreakBadgeWidgetState();
}

class _DailyStreakBadgeWidgetState extends State<DailyStreakBadgeWidget> {
  int _streak = 0;
  StreamSubscription<int>? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = DailyStreakTrackerService.instance.streakStream.listen((value) {
      if (mounted) {
        setState(() => _streak = value);
      }
    });
  }

  Future<void> _load() async {
    final value = await DailyStreakTrackerService.instance.getCurrentStreak();
    if (mounted) {
      setState(() => _streak = value);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_streak <= 0) return const SizedBox.shrink();
    final label = '$_streak дней 🔥';
    return Tooltip(
      message: 'Серийная тренировка: $_streak дней подряд',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department,
              size: 16,
              color: Colors.deepOrange,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
