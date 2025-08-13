import 'package:flutter/material.dart';

/// Overlay banner nudging user to complete an unlaunched booster.
class TheoryRecallOverlayBanner extends StatefulWidget {
  final String title;
  final VoidCallback onDismiss;
  final VoidCallback onOpen;

  const TheoryRecallOverlayBanner({
    super.key,
    required this.title,
    required this.onDismiss,
    required this.onOpen,
  });

  @override
  State<TheoryRecallOverlayBanner> createState() =>
      _TheoryRecallOverlayBannerState();
}

class _TheoryRecallOverlayBannerState extends State<TheoryRecallOverlayBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    Future.delayed(const Duration(seconds: 15), widget.onDismiss);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: SafeArea(
        child: FadeTransition(
          opacity: _anim,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Завершите начатое: ${widget.title}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: widget.onOpen,
                    style: ElevatedButton.styleFrom(backgroundColor: accent),
                    child: const Text('Открыть'),
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
