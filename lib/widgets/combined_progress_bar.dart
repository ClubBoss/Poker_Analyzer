import 'package:flutter/material.dart';

class CombinedProgressBar extends StatefulWidget {
  final double evPct;
  final double icmPct;
  const CombinedProgressBar(this.evPct, this.icmPct, {super.key});

  @override
  State<CombinedProgressBar> createState() => _CombinedProgressBarState();
}

class _CombinedProgressBarState extends State<CombinedProgressBar> {
  bool _highlight = false;

  @override
  void didUpdateWidget(covariant CombinedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.evPct > oldWidget.evPct || widget.icmPct > oldWidget.icmPct) {
      setState(() => _highlight = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _highlight = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final evWidth =
            constraints.maxWidth * (widget.evPct / 100).clamp(0.0, 1.0);
        final icmWidth =
            constraints.maxWidth * (widget.icmPct / 100).clamp(0.0, 1.0);
        return ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 6,
            color: _highlight ? Colors.green.withValues(alpha: 0.3) : Colors.white24,
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: evWidth,
                  color: Colors.green,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: icmWidth,
                  color: Colors.blue.withValues(alpha: .5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

