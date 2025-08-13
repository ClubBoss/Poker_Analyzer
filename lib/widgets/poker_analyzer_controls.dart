import 'package:flutter/material.dart';

/// Standalone widget hosting the action controls for the analyzer.
///
/// The actual control set is intentionally minimal for now; splitting the
/// layout into its own widget keeps [PokerAnalyzerActionPanel] focused purely
/// on styling and composition.
class PokerAnalyzerControls extends StatelessWidget {
  const PokerAnalyzerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Action Panel',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
