import 'package:flutter/material.dart';

/// Simple placeholder panel used by the action and board panels.
///
/// It keeps the demo UI light while avoiding repetition of the same
/// container structure in multiple widgets.
class PanelPlaceholder extends StatelessWidget {
  final Color color;
  final String label;
  const PanelPlaceholder({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

