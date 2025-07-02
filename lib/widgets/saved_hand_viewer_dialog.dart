import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/saved_hand.dart';
import '../models/training_spot.dart';
import '../models/action_entry.dart';
import '../widgets/replay_spot_widget.dart';
import '../widgets/action_history_widget.dart';
import '../services/saved_hand_manager_service.dart';
import '../screens/saved_hand_editor_screen.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../helpers/training_pack_storage.dart';
import 'package:uuid/uuid.dart';

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

  HeroPosition _posFromString(String s) {
    final p = s.toUpperCase();
    if (p.startsWith('SB')) return HeroPosition.sb;
    if (p.startsWith('BB')) return HeroPosition.bb;
    if (p.startsWith('BTN')) return HeroPosition.btn;
    if (p.startsWith('CO')) return HeroPosition.co;
    if (p.startsWith('MP') || p.startsWith('HJ')) return HeroPosition.mp;
    if (p.startsWith('UTG')) return HeroPosition.utg;
    return HeroPosition.unknown;
  }

  TrainingPackSpot _spotFromHand(SavedHand h) {
    final heroCards = h.playerCards[h.heroIndex]
        .map((c) => '${c.rank}${c.suit}')
        .join(' ');
    final actions = <ActionEntry>[for (final a in h.actions) if (a.street == 0) a];
    for (final a in actions) {
      if (a.playerIndex == h.heroIndex) {
        a.ev = h.evLoss ?? 0;
        break;
      }
    }
    final stacks = <String, double>{
      for (int i = 0; i < h.numberOfPlayers; i++) '$i': (h.stackSizes[i] ?? 0).toDouble()
    };
    return TrainingPackSpot(
      id: const Uuid().v4(),
      hand: HandData(
        heroCards: heroCards,
        position: _posFromString(h.heroPosition),
        heroIndex: h.heroIndex,
        playerCount: h.numberOfPlayers,
        stacks: stacks,
        actions: {0: actions},
      ),
      tags: List<String>.from(h.tags),
    );
  }

  Future<void> _addToPack(BuildContext context) async {
    final templates = await TrainingPackStorage.load();
    if (templates.isEmpty) return;
    final tpl = await showDialog<TrainingPackTemplate>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Add to Pack'),
        children: [
          for (final t in templates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, t),
              child: Text(t.name),
            ),
        ],
      ),
    );
    if (tpl == null) return;
    final spot = _spotFromHand(hand);
    tpl.spots.add(spot);
    await TrainingPackStorage.save(templates);
    ScaffoldMessenger.of(parentContext)
        .showSnackBar(SnackBar(content: Text('Spot added to ${tpl.name}')));
  }

  @override
  Widget build(BuildContext context) {
    final spot = TrainingSpot.fromSavedHand(hand);
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(hand.name.isEmpty ? 'Hand' : hand.name)),
          IconButton(
              onPressed: () => _addToPack(context),
              icon: const Icon(Icons.add)),
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
