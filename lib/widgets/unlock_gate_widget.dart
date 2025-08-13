import 'package:flutter/material.dart';

/// Widget that displays a lock overlay when [unlocked] is false.
class UnlockGateWidget extends StatelessWidget {
  final bool unlocked;
  final Widget lockedChild;
  final Widget unlockedChild;

  const UnlockGateWidget({
    super.key,
    required this.unlocked,
    required this.lockedChild,
    required this.unlockedChild,
  });

  @override
  Widget build(BuildContext context) {
    if (unlocked) return unlockedChild;

    final child = ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
      child: IgnorePointer(child: lockedChild),
    );

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Tooltip(
            message: 'Complete previous stage to unlock',
            child: Container(
              color: Colors.black45,
              alignment: Alignment.center,
              child: const Icon(Icons.lock, color: Colors.white, size: 40),
            ),
          ),
        ),
      ],
    );
  }
}
