import 'package:flutter/material.dart';

/// Animated label showing stack changes (gain or loss).
class StackDeltaLabel extends StatefulWidget {
  final int deltaAmount;
  final bool isGain;
  final bool offsetUp;
  final Color labelColor;
  final double scale;
  final VoidCallback? onCompleted;

  const StackDeltaLabel({
    Key? key,
    required this.deltaAmount,
    required this.isGain,
    required this.offsetUp,
    required this.labelColor,
    this.scale = 1.0,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<StackDeltaLabel> createState() => _StackDeltaLabelState();
}

class _StackDeltaLabelState extends State<StackDeltaLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _offset = Tween<Offset>(
      begin: widget.offsetUp ? const Offset(0, 0.3) : const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        widget.onCompleted?.call();
      }
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefix = widget.isGain ? '+' : '-';
    return SlideTransition(
      position: _offset,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 4 * widget.scale,
            vertical: 2 * widget.scale,
          ),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(6 * widget.scale),
          ),
          child: Text(
            '$prefix${widget.deltaAmount.abs()} BB',
            style: TextStyle(
              color: widget.labelColor,
              fontSize: 10 * widget.scale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
