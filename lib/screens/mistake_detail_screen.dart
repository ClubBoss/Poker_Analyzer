import 'package:flutter/material.dart';
import '../models/saved_hand.dart';
import '../models/training_spot.dart';
import '../widgets/replay_spot_widget.dart';
import '../widgets/action_history_widget.dart';
import '../models/action_entry.dart';
import '../services/saved_hand_manager_service.dart';
import 'ev_recovery_history_screen.dart';
import 'package:provider/provider.dart';

class MistakeDetailScreen extends StatelessWidget {
  final SavedHand hand;
  const MistakeDetailScreen({super.key, required this.hand});

  Map<int, String> _posMap() => {
    for (int i = 0; i < hand.numberOfPlayers; i++)
      i: hand.playerPositions[i] ?? 'P${i + 1}',
  };

  List<ActionEntry> _actions() => List<ActionEntry>.from(hand.actions);

  @override
  Widget build(BuildContext context) {
    final spot = TrainingSpot.fromSavedHand(hand);
    return Scaffold(
      appBar: AppBar(
        title: Text(hand.name.isEmpty ? 'Раздача' : hand.name),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReplaySpotWidget(
            spot: spot,
            expectedAction: hand.expectedAction,
            gtoAction: hand.gtoAction,
            evLoss: hand.evLoss,
            feedbackText: hand.feedbackText,
          ),
          const SizedBox(height: 8),
          ActionHistoryWidget(actions: _actions(), playerPositions: _posMap()),
        ],
      ),
      floatingActionButton: hand.corrected
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final manager = context.read<SavedHandManagerService>();
                final index = manager.hands.indexOf(hand);
                if (index < 0) return;
                final updated = hand.markAsCorrected();
                await manager.update(index, updated);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '+${updated.evLossRecovered!.toStringAsFixed(1)} EV восстановлено',
                    ),
                    action: SnackBarAction(
                      label: 'История',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EVRecoveryHistoryScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Исправлено'),
            ),
    );
  }
}
