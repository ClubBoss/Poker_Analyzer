import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import '../widgets/saved_hand_list_view.dart';
import 'hand_history_review_screen.dart';

/// Displays hands from the current error-free streak.
class ErrorFreeStreakScreen extends StatelessWidget {
  const ErrorFreeStreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<SavedHand> hands =
        context.watch<SavedHandManagerService>().currentErrorFreeStreak();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Серия без ошибок'),
        centerTitle: true,
      ),
      body: SavedHandListView(
        hands: hands,
        title: 'Серия без ошибок',
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

