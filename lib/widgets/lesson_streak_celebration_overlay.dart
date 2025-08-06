import 'package:flutter/material.dart';
import 'confetti_overlay.dart';

/// Full screen overlay celebrating a new lesson streak record.
class LessonStreakCelebrationOverlay extends StatefulWidget {
  final int streak;
  final VoidCallback onDismiss;

  const LessonStreakCelebrationOverlay({
    super.key,
    required this.streak,
    required this.onDismiss,
  });

  @override
  State<LessonStreakCelebrationOverlay> createState() =>
      _LessonStreakCelebrationOverlayState();
}

class _LessonStreakCelebrationOverlayState
    extends State<LessonStreakCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showConfettiOverlay(context);
    });
    Future.delayed(const Duration(seconds: 4), _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = '🔥 New Record! ${widget.streak}-Day Streak!';
    return GestureDetector(
      onTap: _dismiss,
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: Center(
          child: FadeTransition(
            opacity: _controller,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _controller,
                curve: Curves.elasticOut,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 96)),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
