import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StreakFlameWidget extends StatefulWidget {
  final int currentStreak;
  final int bestStreak;

  const StreakFlameWidget({
    super.key,
    required this.currentStreak,
    required this.bestStreak,
  });

  @override
  State<StreakFlameWidget> createState() => _StreakFlameWidgetState();
}

class _StreakFlameWidgetState extends State<StreakFlameWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant StreakFlameWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentStreak > oldWidget.currentStreak) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final flames = widget.currentStreak.clamp(0, 7);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final scale = 1 + _controller.value * 0.2;
              return Transform.scale(
                scale: scale,
                child: Row(
                  children: [
                    for (var i = 0; i < flames; i++)
                      const Text('🔥', style: TextStyle(fontSize: 20)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            '🔥 ${l?.dailyStreak ?? 'Streak'}: ${widget.currentStreak} days',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '🏆 ${l?.best ?? 'Best'}: ${widget.bestStreak} days',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
