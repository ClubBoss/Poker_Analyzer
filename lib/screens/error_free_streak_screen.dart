import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_stats_service.dart';
import '../widgets/saved_hand_list_view.dart';
import 'streak_history_screen.dart';
import '../widgets/saved_hand_viewer_dialog.dart';
import '../widgets/sync_status_widget.dart';

/// Displays hands from the current error-free streak.
class ErrorFreeStreakScreen extends StatelessWidget {
  const ErrorFreeStreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<SavedHand> hands =
        context.watch<SavedHandStatsService>().currentErrorFreeStreak();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Серия без ошибок'),
        centerTitle: true,
        actions: [
          SyncStatusIcon.of(context),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StreakHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SavedHandListView(
        hands: hands,
        title: 'Серия без ошибок',
        initialAccuracy: 'correct',
        showAccuracyToggle: false,
        onTap: (hand) {
          showSavedHandViewerDialog(context, hand);
        },
      ),
    );
  }
}
