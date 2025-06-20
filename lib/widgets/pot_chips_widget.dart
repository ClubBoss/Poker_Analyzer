import 'package:flutter/material.dart';
import 'chip_stack_widget.dart';

/// Displays a stack of chips that scales with the pot size.
///
/// Used in the center of the table below the pot amount text.
class PotChipsWidget extends StatefulWidget {
  /// Current pot value.
  final int amount;

  /// Base scale for sizing.
  final double scale;

  const PotChipsWidget({
    Key? key,
    required this.amount,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  State<PotChipsWidget> createState() => _PotChipsWidgetState();
}

class _PotChipsWidgetState extends State<PotChipsWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(covariant PotChipsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amount > oldWidget.amount) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _scaled() {
    // Grow chip stack slightly with pot size.
    final extra = (widget.amount / 2000).clamp(0.0, 0.5);
    return (1.0 + extra) * widget.scale;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.amount <= 0) return const SizedBox.shrink();
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      ),
      child: ChipStackWidget(
        amount: widget.amount,
        scale: _scaled(),
        color: Colors.orangeAccent,
      ),
    );
  }
}
