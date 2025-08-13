import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../widgets/confetti_overlay.dart';

/// Fullscreen celebration shown when a skill tree track is completed.
class SkillTreeTrackCelebrationScreen extends StatefulWidget {
  final String trackId;
  final VoidCallback? onNext;
  const SkillTreeTrackCelebrationScreen({
    super.key,
    required this.trackId,
    this.onNext,
  });

  @override
  State<SkillTreeTrackCelebrationScreen> createState() =>
      _SkillTreeTrackCelebrationScreenState();
}

class _SkillTreeTrackCelebrationScreenState
    extends State<SkillTreeTrackCelebrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showConfettiOverlay(context);
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _finish() {
    if (widget.onNext != null) {
      widget.onNext!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _anim, curve: Curves.easeIn),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale:
                      CurvedAnimation(parent: _anim, curve: Curves.elasticOut),
                  child: Lottie.asset(
                    'assets/animations/congrats.json',
                    width: 160,
                    repeat: false,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Трек завершён!',
                  style: TextStyle(fontSize: 28),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.trackId,
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _finish,
                  child:
                      Text(widget.onNext == null ? 'Готово' : 'Следующий трек'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
