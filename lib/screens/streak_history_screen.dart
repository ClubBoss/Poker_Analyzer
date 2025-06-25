import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import '../widgets/saved_hand_list_view.dart';
import 'hand_history_review_screen.dart';

class StreakHistoryScreen extends StatelessWidget {
  const StreakHistoryScreen({super.key});

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SavedHandManagerService>();
    final streaks = manager.completedErrorFreeStreaks();

    return Scaffold(
      appBar: AppBar(
        title: const Text('История стриков'),
        centerTitle: true,
      ),
      body: streaks.isEmpty
          ? const Center(child: Text('Нет завершённых серий'))
          : ListView.separated(
              itemCount: streaks.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final streak = streaks[index];
                final startDate = streak.first.date;
                return ListTile(
                  title: Text(
                    _formatDate(startDate),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Длина: ${streak.length}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _StreakDetailScreen(hands: streak),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _StreakDetailScreen extends StatelessWidget {
  final List<SavedHand> hands;
  const _StreakDetailScreen({required this.hands});

  String _format(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final mon = d.month.toString().padLeft(2, '0');
    return '$day.$mon.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Серия от ${_format(hands.first.date)}'),
        centerTitle: true,
      ),
      body: SavedHandListView(
        hands: hands,
        title: 'Серия',
        initialAccuracy: 'correct',
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
