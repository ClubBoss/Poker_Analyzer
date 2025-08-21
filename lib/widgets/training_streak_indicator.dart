import 'package:flutter/material.dart';
import 'package:poker_analyzer/ui/padding_constants.dart';

import '../services/training_streak_tracker_service.dart';

/// Displays current and maximum training streak.
class TrainingStreakIndicator extends StatefulWidget {
  const TrainingStreakIndicator({super.key});

  @override
  State<TrainingStreakIndicator> createState() =>
      _TrainingStreakIndicatorState();
}

class _TrainingStreakIndicatorState extends State<TrainingStreakIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  int? _current;
  int _max = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = Tween(
      begin: 1.0,
      end: 0.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _load();
  }

  Future<void> _load() async {
    final current =
        await TrainingStreakTrackerService.instance.getCurrentStreak();
    final max = await TrainingStreakTrackerService.instance.getMaxStreak();
    if (!mounted) return;
    setState(() {
      _current = current;
      _max = max;
    });
    if (current >= 1) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    if (current == null || current < 1) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: kCardPadding,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _fade,
            child: Text('🔥', style: TextStyle(color: accent, fontSize: 20)),
          ),
          const SizedBox(width: 4),
          Text(
            '$current-day streak',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Text('🔥 Max: $_max', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
