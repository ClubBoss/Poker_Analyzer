import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/saved_hand.dart';
import '../models/training_spot.dart';
import '../models/action_entry.dart';
import '../widgets/replay_spot_widget.dart';
import '../widgets/action_history_widget.dart';
import '../services/saved_hand_manager_service.dart';
import '../screens/saved_hand_editor_screen.dart';

class SavedHandViewerDialog extends StatelessWidget {
  final SavedHand hand;
  final BuildContext parentContext;
  const SavedHandViewerDialog({super.key, required this.hand, required this.parentContext});

  Map<int, String> _posMap() => {
        for (int i = 0; i < hand.numberOfPlayers; i++)
          i: hand.playerPositions[i] ?? 'P${i + 1}'
      };

  List<ActionEntry> _actions() => List<ActionEntry>.from(hand.actions);

  Future<void> _edit(BuildContext context) async {
    Navigator.pop(context);
    final result = await Navigator.of(parentContext).push<SavedHand>(
      MaterialPageRoute(builder: (_) => SavedHandEditorScreen(hand: hand)),
    );
    if (result != null) {
      final manager = parentContext.read<SavedHandManagerService>();
      final index = manager.hands.indexOf(hand);
      if (index >= 0) await manager.update(index, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spot = TrainingSpot.fromSavedHand(hand);
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(hand.name.isEmpty ? 'Hand' : hand.name)),
          IconButton(onPressed: () => _edit(context), icon: const Icon(Icons.edit)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

Future<void> showSavedHandViewerDialog(BuildContext context, SavedHand hand) {
  return showDialog(
    context: context,
    builder: (_) => SavedHandViewerDialog(hand: hand, parentContext: context),
  );
}
