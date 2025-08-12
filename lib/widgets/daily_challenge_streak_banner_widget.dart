import 'package:flutter/material.dart';

import '../services/daily_challenge_streak_service.dart';

/// Banner displaying current daily challenge streak.
class DailyChallengeStreakBannerWidget extends StatefulWidget {
  const DailyChallengeStreakBannerWidget({super.key});

  @override
  State<DailyChallengeStreakBannerWidget> createState() => _DailyChallengeStreakBannerWidgetState();
}

class _DailyChallengeStreakBannerWidgetState extends State<DailyChallengeStreakBannerWidget>
    with SingleTickerProviderStateMixin {
  int _streak = 0;
  bool _loading = true;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _load();
  }

  Future<void> _load() async {
    final value =
        await DailyChallengeStreakService.instance.getCurrentStreak();
    if (!mounted) return;
    setState(() {
      _streak = value;
      _loading = false;
    });
    if (value > 0) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _streak <= 0) return const SizedBox.shrink();
    return FadeTransition(
      opacity: _controller,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.deepOrangeAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '🔥 Стрик: $_streak дней подряд!',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
