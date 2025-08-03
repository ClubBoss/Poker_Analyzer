import 'package:flutter/material.dart';

import '../widgets/panel_placeholder.dart';

/// Panel responsible for board editing and visualization.
class PokerAnalyzerBoardPanel extends StatelessWidget {
  const PokerAnalyzerBoardPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return PanelPlaceholder(
      color: Colors.green.shade800,
      label: 'Board Panel',
    );
  }
}
