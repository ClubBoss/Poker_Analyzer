import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';

import 'package:flutter/material.dart';

import '../services/lesson_streak_engine.dart';
import 'confetti_overlay.dart';

/// Banner displaying current lesson streak.
class StreakBannerWidget extends StatefulWidget {
  const StreakBannerWidget({super.key});

  @override
  State<StreakBannerWidget> createState() => _StreakBannerWidgetState();
}

class _StreakBannerWidgetState extends State<StreakBannerWidget>
    with SingleTickerProviderStateMixin {
  static const _disabledKey = 'lesson_streak_banner_disabled';

  int _streak = 0;
  bool _loading = true;
  bool _active = false;
  late final AnimationController _controller;
  StreamSubscription<int>? _sub;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _load();
    _sub = LessonStreakEngine.instance.streakStream.listen(_onStreak);
  }

  Future<void> _load() async {
    final prefs = await PreferencesService.getInstance();
    final disabled = prefs.getBool(_disabledKey) ?? false;
    final trackId = prefs.getString('lesson_selected_track');
    final value = await LessonStreakEngine.instance.getCurrentStreak();
    if (!mounted) return;
    setState(() {
      _streak = value;
      _active = !disabled && trackId != null;
      _loading = false;
    });
    if (_active && value > 0) _controller.forward();
  }

  void _onStreak(int value) {
    if (!mounted) return;
    final increased = value > _streak;
    setState(() => _streak = value);
    if (_active && value > 0) {
      if (increased) {
        _controller.forward(from: 0);
        if ([3, 5, 7, 14].contains(value)) {
          showConfettiOverlay(context);
        }
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _streak <= 0 || !_active) return const SizedBox.shrink();
    final label = '$_streak-дневная серия${_streak >= 7 ? '!' : ''}';
    return FadeTransition(
      opacity: _controller,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.deepOrange, Colors.orangeAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
