import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'confetti_overlay.dart';

/// Fullscreen overlay celebrating skill tree milestones.
class SkillTreeMilestoneOverlay extends StatefulWidget {
  final String message;
  final VoidCallback onClose;
  const SkillTreeMilestoneOverlay({
    super.key,
    required this.message,
    required this.onClose,
  });

  @override
  State<SkillTreeMilestoneOverlay> createState() =>
      _SkillTreeMilestoneOverlayState();
}

class _SkillTreeMilestoneOverlayState extends State<SkillTreeMilestoneOverlay>
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
    Future.delayed(const Duration(seconds: 3), widget.onClose);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _anim, curve: Curves.easeIn),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _anim, curve: Curves.elasticOut),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/animations/congrats.json',
                  width: 160,
                  repeat: false,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.message,
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows [SkillTreeMilestoneOverlay] above the current screen.
Future<void> showSkillTreeMilestoneOverlay(
    BuildContext context, String message) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => SkillTreeMilestoneOverlay(
      message: message,
      onClose: () => Navigator.pop(context),
    ),
  );
}
