import 'package:flutter/material.dart';
import 'confetti_overlay.dart';

/// Overlay shown when a new skill tree stage is unlocked.
class SkillTreeStageGateCelebrationOverlay extends StatefulWidget {
  final String message;
  final VoidCallback onClose;
  const SkillTreeStageGateCelebrationOverlay({
    super.key,
    required this.message,
    required this.onClose,
  });

  @override
  State<SkillTreeStageGateCelebrationOverlay> createState() =>
      _SkillTreeStageGateCelebrationOverlayState();
}

class _SkillTreeStageGateCelebrationOverlayState
    extends State<SkillTreeStageGateCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showConfettiOverlay(context);
    });
    Future.delayed(const Duration(milliseconds: 1500), widget.onClose);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
        child: Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _anim, curve: Curves.easeIn),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.message,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Displays [SkillTreeStageGateCelebrationOverlay] above the current screen.
void showSkillTreeStageGateCelebrationOverlay(
  BuildContext context,
  String message,
) {
  final overlay = Overlay.of(context);

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => SkillTreeStageGateCelebrationOverlay(
      message: message,
      onClose: () {
        entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}
