import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'confetti_overlay.dart';

/// Overlay shown when user hits a streak milestone.
class StreakMilestoneCelebrationOverlay extends StatefulWidget {
  final String message;
  final VoidCallback onClose;
  const StreakMilestoneCelebrationOverlay({
    super.key,
    required this.message,
    required this.onClose,
  });

  @override
  State<StreakMilestoneCelebrationOverlay> createState() =>
      _StreakMilestoneCelebrationOverlayState();
}

class _StreakMilestoneCelebrationOverlayState
    extends State<StreakMilestoneCelebrationOverlay>
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: widget.onClose,
                  child: const Text('Продолжай в том же духе'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Display [StreakMilestoneCelebrationOverlay] above current screen.
Future<void> showCelebrationOverlay(
  BuildContext context,
  String message,
) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => StreakMilestoneCelebrationOverlay(
      message: message,
      onClose: () => Navigator.pop(context),
    ),
  );
}
