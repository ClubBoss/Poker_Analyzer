import 'dart:async';
import 'package:flutter/material.dart';
import '../helpers/action_formatting_helper.dart';
import 'chip_stack_widget.dart';

/// Animated chips sliding from a player's avatar toward the pot.
class BetSlideChips extends StatefulWidget {
  final Offset start;
  final Offset end;
  final int amount;
  final Color color;
  final double scale;
  final Duration holdDuration;
  final VoidCallback? onCompleted;

  const BetSlideChips({
    Key? key,
    required this.start,
    required this.end,
    required this.amount,
    required this.color,
    this.scale = 1.0,
    this.holdDuration = const Duration(seconds: 2),
    this.onCompleted,
  }) : super(key: key);

  @override
  State<BetSlideChips> createState() => _BetSlideChipsState();
}

class _BetSlideChipsState extends State<BetSlideChips>
    with TickerProviderStateMixin {
  late final AnimationController _moveController;
  late final AnimationController _fadeController;
  late final Animation<Offset> _position;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _position = Tween<Offset>(
      begin: widget.start,
      end: widget.end,
    ).animate(CurvedAnimation(parent: _moveController, curve: Curves.easeOut));
    _moveController.forward();
    _timer = Timer(widget.holdDuration, () {
      if (mounted) _fadeController.forward();
    });
    _fadeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _moveController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stack = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChipStackWidget(
          amount: widget.amount,
          color: widget.color,
          scale: 0.8 * widget.scale,
        ),
        SizedBox(height: 2 * widget.scale),
        Text(
          '${ActionFormattingHelper.formatAmount(widget.amount)} BB',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12 * widget.scale,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
          ),
        ),
      ],
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_moveController, _fadeController]),
      builder: (context, child) {
        final pos = _position.value;
        return Positioned(
          left: pos.dx - 12 * widget.scale,
          top: pos.dy - 12 * widget.scale,
          child: Opacity(opacity: 1 - _fadeController.value, child: child),
        );
      },
      child: stack,
    );
  }
}
