import 'package:flutter/material.dart';

class SessionStreakOverlay extends StatefulWidget {
  final int streak;
  final VoidCallback onDismiss;

  const SessionStreakOverlay({
    super.key,
    required this.streak,
    required this.onDismiss,
  });

  @override
  State<SessionStreakOverlay> createState() => _SessionStreakOverlayState();
}

class _SessionStreakOverlayState extends State<SessionStreakOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    Future.delayed(const Duration(seconds: 3), _dismiss);
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: SafeArea(
        child: GestureDetector(
          onTap: _dismiss,
          child: FadeTransition(
            opacity: _controller,
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department, color: accent),
                      const SizedBox(width: 8),
                      Text(
                        '🔥 \u0421\u0435\u0440\u0438\u044f: ${widget.streak} \u0434\u043d\u0435\u0439',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
