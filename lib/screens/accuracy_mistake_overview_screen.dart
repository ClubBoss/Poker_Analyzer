import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/saved_hand_manager_service.dart';
import '../services/evaluation_executor_service.dart';
import '../helpers/poker_street_helper.dart';
import '../widgets/sync_status_widget.dart';
import 'tag_insight_screen.dart';

/// Shows accuracy percentages grouped by tag, street and hero position.
///
/// Information is pulled from [EvaluationExecutorService.summarizeHands]. Lists
/// are sorted by ascending accuracy so the weakest groups appear first.

class AccuracyMistakeOverviewScreen extends StatelessWidget {
  const AccuracyMistakeOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final summary = context.read<EvaluationExecutorService>().summarizeHands(
          hands,
        );

    final Map<String, int> tagTotals = {};
    final Map<String, int> streetTotals = {for (final s in kStreetNames) s: 0};
    final Map<String, int> positionTotals = {};

    for (final h in hands) {
      for (final t in h.tags) {
        tagTotals[t] = (tagTotals[t] ?? 0) + 1;
      }
      final street = streetName(h.boardStreet);
      streetTotals[street] = (streetTotals[street] ?? 0) + 1;
      positionTotals[h.heroPosition] =
          (positionTotals[h.heroPosition] ?? 0) + 1;
    }

    final tagAcc = <MapEntry<String, double>>[];
    for (final e in tagTotals.entries) {
      final mistakes = summary.mistakeTagFrequencies[e.key] ?? 0;
      final total = e.value;
      if (total > 0) {
        final acc = (total - mistakes) / total * 100.0;
        tagAcc.add(MapEntry(e.key, acc));
      }
    }
    tagAcc.sort((a, b) => a.value.compareTo(b.value));

    final streetAcc = <MapEntry<String, double>>[];
    for (final e in streetTotals.entries) {
      final mistakes = summary.streetBreakdown[e.key] ?? 0;
      final total = e.value;
      if (total > 0) {
        final acc = (total - mistakes) / total * 100.0;
        streetAcc.add(MapEntry(e.key, acc));
      }
    }
    streetAcc.sort((a, b) => a.value.compareTo(b.value));

    final posAcc = <MapEntry<String, double>>[];
    for (final e in positionTotals.entries) {
      final mistakes = summary.positionMistakeFrequencies[e.key] ?? 0;
      final total = e.value;
      if (total > 0) {
        final acc = (total - mistakes) / total * 100.0;
        posAcc.add(MapEntry(e.key, acc));
      }
    }
    posAcc.sort((a, b) => a.value.compareTo(b.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Точность по группам'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (tagAcc.isNotEmpty) ...[
            const Text('По тегам', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            for (final e in tagAcc)
              ListTile(
                title: Text(e.key, style: const TextStyle(color: Colors.white)),
                trailing: Text(
                  '${e.value.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TagInsightScreen(tag: e.key),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
          ],
          if (streetAcc.isNotEmpty) ...[
            const Text('По улицам', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            for (final e in streetAcc)
              ListTile(
                title: Text(e.key, style: const TextStyle(color: Colors.white)),
                trailing: Text(
                  '${e.value.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            const SizedBox(height: 16),
          ],
          if (posAcc.isNotEmpty) ...[
            const Text('По позициям', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            for (final e in posAcc)
              ListTile(
                title: Text(e.key, style: const TextStyle(color: Colors.white)),
                trailing: Text(
                  '${e.value.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
