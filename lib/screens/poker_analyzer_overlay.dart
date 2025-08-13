import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../controllers/poker_analyzer_controller.dart';

/// Overlay and animation elements for [PokerAnalyzerScreen].
///
/// In the production application this file would contain the HUD, chip
/// animations, debug dialog and board editor.  For the purposes of the
/// refactor it serves as a lightweight facade that can be expanded in later
/// iterations.
class PokerAnalyzerOverlay extends StatelessWidget {
  const PokerAnalyzerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HudHeader(
            playerCount: context.watch<PokerAnalyzerController>().playerCount,
            handName: 'Hand',
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// Placeholder widget for a future debug dialog.
class PokerAnalyzerDebugDialog extends StatelessWidget {
  const PokerAnalyzerDebugDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const Dialog(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Debug information goes here'),
      ),
    );
  }
}

/// Very small top HUD used by [PokerAnalyzerOverlay].  The production
/// version in the original codebase contains considerably more information
/// and interactivity.  This trimmed down implementation keeps only the
/// essentials required for the refactor demo.
class _HudHeader extends StatelessWidget {
  final int playerCount;
  final String handName;
  const _HudHeader({required this.playerCount, required this.handName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black.withValues(alpha: 0.5),
      child: Row(
        children: [
          Text(
            handName,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const Spacer(),
          Text(
            '$playerCount players',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
