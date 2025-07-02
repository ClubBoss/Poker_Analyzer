import 'package:flutter/material.dart';
import '../helpers/training_pack_storage.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/saved_hand.dart';
import '../models/action_entry.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import 'training_screen.dart';

class StartTrainingFromPackScreen extends StatefulWidget {
  const StartTrainingFromPackScreen({super.key});

  @override
  State<StartTrainingFromPackScreen> createState() => _StartTrainingFromPackScreenState();
}

class _StartTrainingFromPackScreenState extends State<StartTrainingFromPackScreen> {
  final List<TrainingPackTemplate> _templates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    TrainingPackStorage.load().then((list) {
      if (!mounted) return;
      setState(() {
        _templates.addAll(list);
        _loading = false;
      });
    });
  }

  SavedHand _handFromSpot(TrainingPackSpot spot) {
    final parts = spot.hand.heroCards.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final cards = [for (final p in parts) CardModel(rank: p[0], suit: p.substring(1))];
    final playerCards = [for (int i = 0; i < spot.hand.playerCount; i++) <CardModel>[]];
    if (cards.length >= 2 && spot.hand.heroIndex < playerCards.length) {
      playerCards[spot.hand.heroIndex] = cards;
    }
    final board = [for (final c in spot.hand.board) CardModel(rank: c[0], suit: c.substring(1))];
    final actions = <ActionEntry>[];
    for (final list in spot.hand.actions.values) {
      for (final a in list) {
        actions.add(ActionEntry(a.street, a.playerIndex, a.action, amount: a.amount, generated: a.generated, manualEvaluation: a.manualEvaluation, customLabel: a.customLabel));
      }
    }
    final stacks = {for (int i = 0; i < spot.hand.playerCount; i++) i: spot.hand.stacks['$i']?.round() ?? 0};
    final positions = {for (int i = 0; i < spot.hand.playerCount; i++) i: i == spot.hand.heroIndex ? spot.hand.position.label : ''};
    String? gto;
    for (final a in spot.hand.actions[0] ?? []) {
      if (a.playerIndex == spot.hand.heroIndex) {
        gto = a.action.toUpperCase();
        break;
      }
    }
    int street = 0;
    if (board.length >= 5) {
      street = 3;
    } else if (board.length == 4) {
      street = 2;
    } else if (board.length >= 3) {
      street = 1;
    }
    return SavedHand(
      name: spot.title,
      heroIndex: spot.hand.heroIndex,
      heroPosition: spot.hand.position.label,
      numberOfPlayers: spot.hand.playerCount,
      playerCards: playerCards,
      boardCards: board,
      boardStreet: street,
      actions: actions,
      stackSizes: stacks,
      playerPositions: positions,
      tags: List<String>.from(spot.tags),
      gtoAction: gto,
    );
  }

  Future<void> _start(TrainingPackTemplate tpl) async {
    final hands = [for (final s in tpl.spots) _handFromSpot(s)];
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TrainingScreen.drill(hands: hands)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start Training')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _templates.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final t = _templates[index];
                return ListTile(
                  title: Text(t.name),
                  subtitle: Text('${t.spots.length} spots'),
                  onTap: () => _start(t),
                );
              },
            ),
    );
  }
}

