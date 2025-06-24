import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/saved_hand_manager_service.dart';
import '../services/evaluation_executor_service.dart';
import '../widgets/saved_hand_list_view.dart';
import 'hand_history_review_screen.dart';

/// Displays a list of streets sorted by mistake count.
///
/// Information is pulled from [EvaluationExecutorService.summarizeHands]. Each
/// tile shows how many errors were made on that street. Selecting a street opens
/// a filtered [SavedHandListView] showing only the mistaken hands for the chosen
/// street.
class StreetMistakeOverviewScreen extends StatelessWidget {
  const StreetMistakeOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final summary = EvaluationExecutorService().summarizeHands(hands);
    final entries = summary.streetBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ошибки по улицам'),
        centerTitle: true,
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text(
                'Ошибок нет',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final e in entries)
                  ListTile(
                    title:
                        Text(e.key, style: const TextStyle(color: Colors.white)),
                    trailing: Text(e.value.toString(),
                        style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _StreetMistakeHandsScreen(street: e.key),
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}

class _StreetMistakeHandsScreen extends StatelessWidget {
  final String street;
  const _StreetMistakeHandsScreen({required this.street});

  @override
  Widget build(BuildContext context) {
    final allHands = context.watch<SavedHandManagerService>().hands;
    final filtered = [
      for (final h in allHands)
        if (_streetName(h.boardStreet) == street) h
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(street),
        centerTitle: true,
      ),
      body: SavedHandListView(
        hands: filtered,
        accuracy: 'errors',
        title: 'Ошибки: $street',
        onTap: (hand) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HandHistoryReviewScreen(hand: hand),
            ),
          );
        },
      ),
    );
  }
}

String _streetName(int index) {
  const names = ['Preflop', 'Flop', 'Turn', 'River'];
  return names[index.clamp(0, names.length - 1)];
}
