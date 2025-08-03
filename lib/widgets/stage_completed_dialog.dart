import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'confetti_overlay.dart';

/// Full-screen modal celebrating stage completion.
class StageCompletedDialog extends StatefulWidget {
  final String stageTitle;
  const StageCompletedDialog({super.key, required this.stageTitle});

  @override
  State<StageCompletedDialog> createState() => _StageCompletedDialogState();
}

class _StageCompletedDialogState extends State<StageCompletedDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
          ..forward();
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
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
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
                Text(
                  widget.stageTitle,
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Стадия завершена! Продолжай обучение',
                  style: TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Продолжить'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

