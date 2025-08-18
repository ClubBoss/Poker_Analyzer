import 'package:flutter/material.dart';

/// Displays a lock icon and optional unlock reason over [child] when [locked].
class TrackLockOverlay extends StatelessWidget {
  final bool locked;
  final String? reason;
  final Widget child;
  final VoidCallback? onTap;

  const TrackLockOverlay({
    super.key,
    required this.locked,
    this.reason,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;

    final overlay = Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock, color: Colors.white, size: 40),
          if (reason != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                reason!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
        ],
      ),
    );

    return Stack(
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.grey,
            BlendMode.saturation,
          ),
          child: IgnorePointer(child: child),
        ),
        Positioned.fill(
          child: InkWell(onTap: onTap, child: overlay),
        ),
      ],
    );
  }
}
