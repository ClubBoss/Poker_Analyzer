import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../chip_stack_widget.dart';
import 'action_tag_label.dart';

class PlayerZoneActionPanel extends StatelessWidget {
  final Widget child;
  final int? betStackAmount;
  final bool isHero;
  final bool isLeftSide;
  final Animation<Offset> betFoldOffset;
  final Animation<double> betFoldOpacity;
  final Animation<double> betStackOpacity;
  final GlobalKey betStackKey;
  final String? lastActionText;
  final Animation<double> actionTagOpacity;
  final Color lastActionColor;
  final Animation<double> heroLabelOpacity;
  final Animation<double> heroLabelScale;
  final double scale;

  const PlayerZoneActionPanel({
    super.key,
    required this.child,
    required this.betStackAmount,
    required this.isHero,
    required this.isLeftSide,
    required this.betFoldOffset,
    required this.betFoldOpacity,
    required this.betStackOpacity,
    required this.betStackKey,
    required this.lastActionText,
    required this.actionTagOpacity,
    required this.lastActionColor,
    required this.heroLabelOpacity,
    required this.heroLabelScale,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (betStackAmount != null && !isHero)
          Positioned(
            top: 12 * scale,
            right: isLeftSide ? null : -32 * scale,
            left: isLeftSide ? -32 * scale : null,
            child: SlideTransition(
              position: betFoldOffset,
              child: FadeTransition(
                opacity: betFoldOpacity,
                child: FadeTransition(
                  key: betStackKey,
                  opacity: betStackOpacity,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: ChipStackWidget(
                      key: ValueKey(betStackAmount),
                      amount: betStackAmount!,
                      scale: scale,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (lastActionText != null)
          Positioned(
            top: -20 * scale,
            child: FadeTransition(
              opacity: actionTagOpacity,
              child: ActionTagLabel(
                text: lastActionText!,
                color: lastActionColor,
                scale: scale,
              ),
            ),
          ),
        if (isHero)
          Positioned(
            top: -8 * scale,
            left: -8 * scale,
            child: FadeTransition(
              opacity: heroLabelOpacity,
              child: ScaleTransition(
                scale: heroLabelScale,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 6 * scale, vertical: 2 * scale),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.6),
                        blurRadius: 6 * scale,
                      ),
                    ],
                  ),
                  child: Text(
                    'Hero',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class BetAmountOverlay extends StatefulWidget {
  final Offset position;
  final int amount;
  final Color color;
  final double scale;
  final VoidCallback? onCompleted;

  const BetAmountOverlay({
    Key? key,
    required this.position,
    required this.amount,
    required this.color,
    this.scale = 1.0,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<BetAmountOverlay> createState() => _BetAmountOverlayState();
}

class ActionLabelOverlay extends StatefulWidget {
  final Offset position;
  final String text;
  final Color color;
  final double scale;
  final VoidCallback? onCompleted;

  const ActionLabelOverlay({
    Key? key,
    required this.position,
    required this.text,
    required this.color,
    this.scale = 1.0,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<ActionLabelOverlay> createState() => _ActionLabelOverlayState();
}

class _ActionLabelOverlayState extends State<ActionLabelOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      const TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
        tween:
            Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_controller);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.8, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween:
            Tween(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
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
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * widget.scale,
              vertical: 4 * widget.scale,
            ),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8 * widget.scale),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 4)
              ],
            ),
            child: Text(
              widget.text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14 * widget.scale,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BetAmountOverlayState extends State<BetAmountOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 25,
      ),
      const TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 25,
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
    final double radius = 16 * widget.scale;
    return Positioned(
      left: widget.position.dx - radius,
      top: widget.position.dy - radius,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          width: radius * 2,
          height: radius * 2,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 4),
            ],
          ),
          child: Text(
            '${widget.amount}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14 * widget.scale,
            ),
          ),
        ),
      ),
    );
  }
}

class RefundMessageOverlay extends StatefulWidget {
  final Offset position;
  final int amount;
  final double scale;
  final VoidCallback? onCompleted;

  const RefundMessageOverlay({
    Key? key,
    required this.position,
    required this.amount,
    this.scale = 1.0,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<RefundMessageOverlay> createState() => _RefundMessageOverlayState();
}

class _RefundMessageOverlayState extends State<RefundMessageOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 25,
      ),
      const TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 25,
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
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8 * widget.scale,
            vertical: 4 * widget.scale,
          ),
          decoration: BoxDecoration(
            color: Colors.lightGreenAccent.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8 * widget.scale),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
          ),
          child: Text(
            '+${widget.amount} returned',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14 * widget.scale,
            ),
          ),
        ),
      ),
    );
  }
}
