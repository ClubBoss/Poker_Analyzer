import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/goals_service.dart';
import '../screens/error_free_streak_screen.dart';

/// Displays the current "Без ошибок подряд" streak as a small banner.
/// Fades in and out when the value changes.
class StreakBanner extends StatefulWidget {
  const StreakBanner({super.key});

  @override
  State<StreakBanner> createState() => _StreakBannerState();
}

class _StreakBannerState extends State<StreakBanner>
    with SingleTickerProviderStateMixin {
  bool _motivationalShown = false;
  late final AnimationController _iconController;
  late final Animation<double> _iconScale;
  int _previousStreak = 0;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _iconController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<GoalsService>().errorFreeStreak;
    final accent = Theme.of(context).colorScheme.secondary;

    if (streak > _previousStreak && streak > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _iconController.forward(from: 0);
        }
      });
    }
    _previousStreak = streak;

    if (streak == 0) {
      _motivationalShown = false;
    } else if (streak >= 5 && !_motivationalShown) {
      _motivationalShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔥 5 раздач без ошибок! Отличная серия!'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: streak >= 1
          ? GestureDetector(
              key: ValueKey<int>(streak),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ErrorFreeStreakScreen(),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _iconScale,
                          child: Icon(Icons.flash_on, color: accent, size: 18),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$streak',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Держите темп!',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 80,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0,
                              end: (streak >= 5 ? 5 : streak) / 5,
                            ),
                            duration: const Duration(milliseconds: 300),
                            builder: (context, value, _) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: value,
                                  backgroundColor: Colors.white24,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    accent,
                                  ),
                                  minHeight: 4,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${streak >= 5 ? 5 : streak}/5',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }
}
