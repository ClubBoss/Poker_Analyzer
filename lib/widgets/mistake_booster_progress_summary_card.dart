import 'package:flutter/material.dart';

import '../services/mistake_booster_progress_tracker.dart';
import '../screens/mistake_repeat_screen.dart';
import '../l10n/app_localizations.dart';

/// Card showing progress on mistake booster recovery.
class MistakeBoosterProgressSummaryCard extends StatefulWidget {
  final bool showButton;
  const MistakeBoosterProgressSummaryCard({super.key, this.showButton = true});

  @override
  State<MistakeBoosterProgressSummaryCard> createState() =>
      _MistakeBoosterProgressSummaryCardState();
}

class _MistakeBoosterProgressSummaryCardState
    extends State<MistakeBoosterProgressSummaryCard> {
  late Future<MistakeRecoverySummary> _future;

  @override
  void initState() {
    super.initState();
    _future = MistakeBoosterProgressTracker.instance.getRecoveryStatus();
  }

  void _openMistakes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MistakeRepeatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<MistakeRecoverySummary>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final data = snapshot.data!;
        if (data.reinforced == 0) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.mistakeBoosterReinforced(data.reinforced),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '✅ ${l.mistakeBoosterRecovered(data.recovered)}',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.showButton)
                TextButton(
                  onPressed: _openMistakes,
                  child: Text(l.reviewMistakes),
                ),
            ],
          ),
        );
      },
    );
  }
}
