import 'package:flutter/material.dart';

/// Service that temporarily highlights a stage widget that was auto scrolled
/// into view.
class StageAutoHighlightService {
  const StageAutoHighlightService();

  /// Applies a brief glow effect around the stage widget associated with
  /// [stageIndex]. The widget is located via [stageKeys] and highlighted using
  /// an [Overlay] entry that fades in then out over roughly 2.5 seconds.
  Future<void> highlight({
    required int stageIndex,
    required Map<int, GlobalKey> stageKeys,
    required BuildContext context,
  }) async {
    final targetContext = stageKeys[stageIndex]?.currentContext;
    if (targetContext == null) return;
    final overlay = Overlay.of(context);

    final box = targetContext.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final offset = box.localToGlobal(Offset.zero);

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: offset.dx,
        top: offset.dy,
        width: size.width,
        height: size.height,
        child: const _StageHighlight(),
      ),
    );

    overlay.insert(entry);
    // Remove after animation completes.
    await Future.delayed(const Duration(milliseconds: 2500));
    entry.remove();
  }
}

/// Simple fade-in/fade-out highlight widget.
class _StageHighlight extends StatefulWidget {
  const _StageHighlight();

  @override
  State<_StageHighlight> createState() => _StageHighlightState();
}

class _StageHighlightState extends State<_StageHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 4),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orangeAccent, width: 4),
          color: Colors.orangeAccent.withOpacity(0.3),
        ),
      ),
    );
  }
}
