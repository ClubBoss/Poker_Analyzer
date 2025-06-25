import 'package:flutter/material.dart';
import '../services/goals_service.dart';
import '../widgets/saved_hand_list_view.dart';
import '../screens/hand_history_review_screen.dart';
import '../models/saved_hand.dart';
import 'package:provider/provider.dart';

class DrillHistoryScreen extends StatelessWidget {
  const DrillHistoryScreen({super.key});

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final results = context.watch<GoalsService>().drillResults.reversed.take(20).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drill История'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final r = results[index];
          final perc = (r.accuracy * 100).round();
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              title: Text(
                '${_fmt(r.date)} • ${r.position} / ${r.street}',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '${r.correct}/${r.total} верно ($perc%)',
                style: TextStyle(color: accent),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _DrillSessionHandsScreen(hands: r.hands),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DrillSessionHandsScreen extends StatelessWidget {
  final List<SavedHand> hands;
  const _DrillSessionHandsScreen({required this.hands});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Руки'),
        centerTitle: true,
      ),
      body: SavedHandListView(
        hands: hands,
        title: 'Drill Hands',
        showAccuracyToggle: false,
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
