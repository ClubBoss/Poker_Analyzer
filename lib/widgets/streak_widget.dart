import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/streak_service.dart';
import '../constants/app_constants.dart';

class StreakWidget extends StatefulWidget {
  const StreakWidget({super.key});

  @override
  State<StreakWidget> createState() => _StreakWidgetState();
}

class _StreakWidgetState extends State<StreakWidget>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<StreakService>();
    return ValueListenableBuilder<int>(
      valueListenable: service.streak,
      builder: (context, value, _) {
        if (service.consumeIncreaseFlag()) {
          _controller.forward(from: 0);
        }
        final accent = Theme.of(context).colorScheme.secondary;
        return AnimatedOpacity(
          opacity: value > 0 ? 1.0 : 0.0,
          duration: AppConstants.fadeDuration,
          child: AnimatedBuilder(
            animation: _scale,
            builder: (context, child) => AnimatedScale(
              scale: _scale.value,
              duration: Duration.zero,
              child: child,
            ),
            child: Row(
              children: [
                Text('🔥', style: TextStyle(color: accent)),
                const SizedBox(width: 4),
                Text(
                  '$value',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
