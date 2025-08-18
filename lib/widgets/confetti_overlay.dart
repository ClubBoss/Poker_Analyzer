import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

/// Simple confetti animation overlay that auto-removes after the given [duration].
class ConfettiOverlay extends StatefulWidget {
  final Duration duration;
  final VoidCallback onCompleted;
  final Path Function(Size size)? particlePath;

  const ConfettiOverlay({
    Key? key,
    this.duration = const Duration(seconds: 3),
    required this.onCompleted,
    this.particlePath,
  }) : super(key: key);

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: widget.duration);
    _controller.play();
    Future.delayed(widget.duration, widget.onCompleted);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: ConfettiWidget(
          confettiController: _controller,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          createParticlePath: widget.particlePath,
        ),
      ),
    );
  }
}

/// Helper to display [ConfettiOverlay] above the current screen.
void showConfettiOverlay(
  BuildContext context, {
  Path Function(Size size)? particlePath,
}) {
  final overlay = Overlay.of(context);

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => ConfettiOverlay(
      onCompleted: () => entry.remove(),
      particlePath: particlePath,
    ),
  );
  overlay.insert(entry);
}
