import 'package:flutter/material.dart';

/// Small tooltip overlay showing a player's stack, position and strategy advice.
class PlayerInfoOverlay extends StatefulWidget {
  final Offset position;
  final int stack;
  final String positionName;
  final String? advice;
  final VoidCallback? onCompleted;

  const PlayerInfoOverlay({
    Key? key,
    required this.position,
    required this.stack,
    required this.positionName,
    this.advice,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<PlayerInfoOverlay> createState() => _PlayerInfoOverlayState();
}

class _PlayerInfoOverlayState extends State<PlayerInfoOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  Color _actionColor(String action) {
    if (action.isEmpty) return Colors.white;
    final type = action.split(' ').first.toUpperCase();
    switch (type) {
      case 'PUSH':
        return Colors.green;
      case 'FOLD':
        return Colors.red;
      case 'CALL':
        return Colors.blue;
      case 'RAISE':
        return Colors.yellow;
      default:
        return Colors.white;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 20,
      ),
      const TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 20,
      ),
    ]).animate(_controller);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted?.call();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final advice = widget.advice;
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: FadeTransition(
        opacity: _opacity,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stack: ${widget.stack}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Pos: ${widget.positionName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (advice != null)
                  Text(
                    advice.toUpperCase(),
                    style: TextStyle(
                      color: _actionColor(advice),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Displays a [PlayerInfoOverlay] above the current overlay.
void showPlayerInfoOverlay({
  required BuildContext context,
  required Offset position,
  required int stack,
  required String positionName,
  String? advice,
}) {
  final overlay = Overlay.of(context);
  if (overlay == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => PlayerInfoOverlay(
      position: position,
      stack: stack,
      positionName: positionName,
      advice: advice,
      onCompleted: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}
