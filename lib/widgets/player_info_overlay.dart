import 'package:flutter/material.dart';
import 'package:poker_analyzer/theme/app_colors.dart';

/// Small tooltip overlay showing a player's stack, position and strategy advice.
class PlayerInfoOverlay extends StatefulWidget {
  final Offset position;
  final int stack;
  final String positionName;
  final double? equity;
  final String? advice;
  final VoidCallback? onCompleted;

  const PlayerInfoOverlay({
    Key? key,
    required this.position,
    required this.stack,
    required this.positionName,
    this.equity,
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
    if (action.isEmpty) return AppColors.textPrimaryDark;
    final type = action.split(' ').first.toUpperCase();
    switch (type) {
      case 'PUSH':
        return AppColors.success;
      case 'FOLD':
        return AppColors.error;
      case 'CALL':
        return AppColors.info;
      case 'RAISE':
        return AppColors.warning;
      default:
        return AppColors.textPrimaryDark;
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
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      const TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
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
          color: AppColors.transparent,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.overlay,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: AppColors.shadow, blurRadius: 4),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stack: ${widget.stack}',
                  style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Pos: ${widget.positionName}',
                  style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.equity != null)
                  Text(
                    'EQ: ${widget.equity!.round()}%',
                    style: const TextStyle(
                      color: AppColors.neutral,
                      fontSize: 10,
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
  double? equity,
  String? advice,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => PlayerInfoOverlay(
      position: position,
      stack: stack,
      positionName: positionName,
      equity: equity,
      advice: advice,
      onCompleted: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}
