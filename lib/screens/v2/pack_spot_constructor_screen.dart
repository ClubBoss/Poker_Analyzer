import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../../models/v2/training_pack_template.dart';
import '../../services/evaluation_executor_service.dart';
import '../../models/card_model.dart';
import '../../widgets/card_picker_widget.dart';
import '../../widgets/action_editor_list.dart';
import '../../models/action_entry.dart';
import '../../models/v2/hero_position.dart';
import '../../models/v2/hand_data.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../services/training_pack_service.dart';

class PackSpotConstructorScreen extends StatefulWidget {
  const PackSpotConstructorScreen({super.key});

  @override
  State<PackSpotConstructorScreen> createState() =>
      _PackSpotConstructorScreenState();
}

class _PackSpotConstructorScreenState extends State<PackSpotConstructorScreen> {
  final _heroStackCtrl = TextEditingController(text: '10');
  final _villainStackCtrl = TextEditingController(text: '10');
  final List<CardModel> _cards = [];
  List<ActionEntry> _actions = [];
  HeroPosition _pos = HeroPosition.sb;

  @override
  void dispose() {
    _heroStackCtrl.dispose();
    _villainStackCtrl.dispose();
    super.dispose();
  }

  Set<String> _usedCards() => {for (final c in _cards) '${c.rank}${c.suit}'};

  void _setCard(int i, CardModel c) {
    setState(() {
      if (_cards.length > i) {
        _cards[i] = c;
      } else {
        _cards.add(c);
      }
    });
  }

  Future<void> _save() async {
    if (_cards.length < 2) return;
    final hero = double.tryParse(_heroStackCtrl.text) ?? 0;
    final vil = double.tryParse(_villainStackCtrl.text) ?? hero;
    final spot = TrainingPackSpot(
      id: const Uuid().v4(),
      hand: HandData(
        heroCards: _cards.map((e) => '${e.rank}${e.suit}').join(' '),
        position: _pos,
        heroIndex: 0,
        playerCount: 2,
        stacks: {'0': hero, '1': vil},
        actions: {0: List<ActionEntry>.from(_actions)},
      ),
    );
    final tpl = TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Custom Pack',
      heroBbStack: hero.round(),
      playerStacksBb: [hero.round(), vil.round()],
      heroPos: _pos,
      spots: [spot],
    );
    await context.read<EvaluationExecutorService>().evaluateSingle(
          context,
          spot,
          template: tpl,
          anteBb: spot.hand.anteBb,
        );
    await TrainingPackService.saveCustomSpot(spot);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Spot Pack')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Hero Cards',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CardPickerWidget(
              cards: _cards,
              onChanged: _setCard,
              disabledCards: _usedCards(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<HeroPosition>(
              initialValue: _pos,
              decoration: const InputDecoration(labelText: 'Position'),
              items: [
                for (final p in HeroPosition.values)
                  DropdownMenuItem(value: p, child: Text(p.label)),
              ],
              onChanged: (v) => setState(() => _pos = v ?? HeroPosition.sb),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _heroStackCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Hero Stack'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _villainStackCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Villain Stack',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Preflop Actions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ActionEditorList(
              initial: _actions,
              players: 2,
              positions: [_pos.label, 'Villain'],
              onChanged: (v) => setState(() => _actions = v),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
