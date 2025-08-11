import 'package:flutter/material.dart';
import 'confetti_overlay.dart';

/// Brief overlay celebrating completion of a skill tree node.
class SkillTreeNodeCelebrationOverlay extends StatefulWidget {
  final VoidCallback onClose;
  const SkillTreeNodeCelebrationOverlay({super.key, required this.onClose});

  @override
  State<SkillTreeNodeCelebrationOverlay> createState() =>
      _SkillTreeNodeCelebrationOverlayState();
}

class _SkillTreeNodeCelebrationOverlayState
    extends State<SkillTreeNodeCelebrationOverlay>
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
        child: const Center(
          child: Text('🎯', style: TextStyle(fontSize: 72)),
        ),
      ),
    );
  }
}

/// Shows [SkillTreeNodeCelebrationOverlay] above the current screen.
void showSkillTreeNodeCelebrationOverlay(BuildContext context) {
  final overlay = Overlay.of(context);

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => SkillTreeNodeCelebrationOverlay(onClose: () {
      entry.remove();
    }),
  );
  overlay.insert(entry);
}
