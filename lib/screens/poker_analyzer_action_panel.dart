import 'package:flutter/material.dart';

import '../widgets/panel_placeholder.dart';

/// Panel containing action controls and evaluation information.
class PokerAnalyzerActionPanel extends StatelessWidget {
  const PokerAnalyzerActionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return PanelPlaceholder(
      color: Colors.grey.shade900,
      label: 'Action Panel',
    );
  }
}
