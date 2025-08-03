import 'package:flutter/material.dart';

/// Panel containing action controls and evaluation information.
class PokerAnalyzerActionPanel extends StatelessWidget {
  const PokerAnalyzerActionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: Text(
          'Action Panel',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
