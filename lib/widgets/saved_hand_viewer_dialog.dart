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
import '../services/adaptive_training_service.dart';
import 'package:uuid/uuid.dart';

class SavedHandViewerDialog extends StatelessWidget {
  final SavedHand hand;
  final BuildContext parentContext;
  const SavedHandViewerDialog({
    super.key,
    required this.hand,
    required this.parentContext,
  });

  Map<int, String> _posMap() => {
        for (int i = 0; i < hand.numberOfPlayers; i++)
          i: hand.playerPositions[i] ?? 'P${i + 1}',
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

  TrainingPackSpot _spotFromHand(SavedHand hand) {
    final heroCards = hand.playerCards[hand.heroIndex]
        .map((c) => '${c.rank}${c.suit}')
        .join(' ');
    final actions = <ActionEntry>[
      for (final a in hand.actions)
        if (a.street == 0) a,
    ];
    final stacks = <String, double>{
      for (int i = 0; i < hand.numberOfPlayers; i++)
        '$i': (hand.stackSizes[i] ?? 0).toDouble(),
    };
    return TrainingPackSpot(
      id: const Uuid().v4(),
      hand: HandData(
        heroCards: heroCards,
        position: _posFromString(hand.heroPosition),
        heroIndex: hand.heroIndex,
        playerCount: hand.numberOfPlayers,
        stacks: stacks,
        actions: {0: actions},
      ),
      tags: List<String>.from(hand.tags),
    );
  }

  Future<void> _addToPack(BuildContext context) async {
    final templates = await TrainingPackStorage.load();
    if (templates.isEmpty) return;
    final selected = await showDialog<TrainingPackTemplate>(
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
    if (selected == null) return;
    final spot = _spotFromHand(hand);
    selected.spots.add(spot);
    await TrainingPackStorage.save(templates);
    ScaffoldMessenger.of(
      parentContext,
    ).showSnackBar(SnackBar(content: Text('Spot added to ${selected.name}')));
  }

  Widget _evCard() {
    final ev = hand.heroEv;
    final icm = hand.heroIcmEv;
    if (ev == null && icm == null) return const SizedBox.shrink();
    final rows = <Widget>[];
    if (ev != null) {
      rows.add(
        Text(
          'EV: ${ev >= 0 ? '+' : ''}${ev.toStringAsFixed(1)} BB',
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
    if (icm != null) {
      rows.add(
        Text(
          'ICM EV: ${icm >= 0 ? '+' : ''}${icm.toStringAsFixed(3)}',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }

  Widget _recCard(BuildContext context) {
    final list = context.watch<AdaptiveTrainingService>().recommended.take(3);
    if (list.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Рекомендуемые паки:',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 4),
          for (final p in list)
            Text(p.name, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
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
            icon: const Text('➕'),
            tooltip: 'Add to Pack',
          ),
          IconButton(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.edit),
          ),
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
            ActionHistoryWidget(
              actions: _actions(),
              playerPositions: _posMap(),
            ),
            _evCard(),
            _recCard(context),
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
