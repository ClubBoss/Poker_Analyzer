import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/saved_hand.dart';
import '../models/action_entry.dart';
import '../models/card_model.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/v2/training_pack_spot.dart';
import '../services/evaluation_executor_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../theme/app_colors.dart';
import '../widgets/card_picker_widget.dart';

class SavedHandEditorScreen extends StatefulWidget {
  final SavedHand hand;
  const SavedHandEditorScreen({super.key, required this.hand});

  @override
  State<SavedHandEditorScreen> createState() => _SavedHandEditorScreenState();
}

class _SavedHandEditorScreenState extends State<SavedHandEditorScreen> {
  late Map<int, List<ActionEntry>> _actions;
  late HeroPosition _position;
  late List<CardModel> _cards;
  late Map<int, TextEditingController> _stacks;
  late TextEditingController _expected;

  @override
  void initState() {
    super.initState();
    _actions = {for (var s = 0; s < 4; s++) s: <ActionEntry>[]};
    for (final a in widget.hand.actions) {
      _actions[a.street]!.add(a);
    }
    _position = _posFromString(widget.hand.heroPosition);
    _cards = widget.hand.heroIndex < widget.hand.playerCards.length
        ? List<CardModel>.from(widget.hand.playerCards[widget.hand.heroIndex])
        : <CardModel>[];
    _stacks = {
      for (int i = 0; i < widget.hand.numberOfPlayers; i++)
        i: TextEditingController(
          text: (widget.hand.stackSizes[i] ?? 0).toString(),
        ),
    };
    _expected = TextEditingController(text: widget.hand.expectedAction ?? '');
  }

  void _add(int s) {
    setState(() => _actions[s]!.add(ActionEntry(s, 0, 'call')));
  }

  void _update(int s, int i, ActionEntry e) {
    setState(() => _actions[s]![i] = e);
  }

  void _remove(int s, int i) {
    setState(() => _actions[s]!.removeAt(i));
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
    final hero = h.playerCards[h.heroIndex]
        .map((c) => '${c.rank}${c.suit}')
        .join(' ');
    final actionsByStreet = <int, List<ActionEntry>>{
      for (var s = 0; s < 4; s++) s: [],
    };
    for (final a in h.actions) {
      actionsByStreet[a.street]!.add(a);
    }
    final stacks = <String, double>{
      for (int i = 0; i < h.numberOfPlayers; i++)
        '$i': (h.stackSizes[i] ?? 0).toDouble(),
    };
    return TrainingPackSpot(
      id: const Uuid().v4(),
      hand: HandData(
        heroCards: hero,
        position: _posFromString(h.heroPosition),
        heroIndex: h.heroIndex,
        playerCount: h.numberOfPlayers,
        stacks: stacks,
        board: [for (final c in h.boardCards) '${c.rank}${c.suit}'],
        actions: actionsByStreet,
        anteBb: h.anteBb,
      ),
    );
  }

  Future<void> _save() async {
    var actions = _actions.values.expand((l) => l).toList();
    final stacks = {
      for (int i = 0; i < widget.hand.numberOfPlayers; i++)
        i: int.tryParse(_stacks[i]?.text ?? '') ?? 0,
    };
    final cards = <List<CardModel>>[
      for (final l in widget.hand.playerCards) List<CardModel>.from(l),
    ];
    if (cards.length <= widget.hand.heroIndex) {
      cards.length = widget.hand.heroIndex + 1;
      while (cards.length <= widget.hand.heroIndex) {
        cards.add(<CardModel>[]);
      }
    }
    if (cards.length > widget.hand.heroIndex) {
      cards[widget.hand.heroIndex] = List<CardModel>.from(_cards);
    }
    var hand = widget.hand.copyWith(
      actions: actions,
      heroPosition: _position.label,
      stackSizes: stacks,
      playerCards: cards,
      expectedAction: _expected.text.trim().isEmpty
          ? null
          : _expected.text.trim(),
    );
    final heroCards = hand.playerCards.length > hand.heroIndex
        ? hand.playerCards[hand.heroIndex]
        : <dynamic>[];
    final complete =
        heroCards.length >= 2 &&
        hand.boardCards.isNotEmpty &&
        actions.isNotEmpty;
    if (complete) {
      final spot = _spotFromHand(hand);
      await context.read<EvaluationExecutorService>().evaluateSingle(
        context,
        spot,
        hand: hand,
        anteBb: hand.anteBb,
      );
      actions = spot.hand.actions.values.expand((l) => l).toList();
      hand = hand.copyWith(actions: actions, gtoAction: spot.correctAction);
      await context.read<SavedHandManagerService>().save(hand);
      final ev = spot.heroEv;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saved ${ev != null ? ev.toStringAsFixed(2) : '--'} BB',
            ),
          ),
        );
      }
      if (mounted) Navigator.pop(context, hand);
    } else {
      Navigator.pop(context, hand);
    }
  }

  @override
  void dispose() {
    for (final c in _stacks.values) {
      c.dispose();
    }
    _expected.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const names = ['Preflop', 'Flop', 'Turn', 'River'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Hand'),
        actions: [IconButton(onPressed: _save, icon: const Icon(Icons.check))],
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Hero Cards', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 8),
            CardPickerWidget(
              cards: _cards,
              onChanged: (i, c) => setState(() {
                if (_cards.length > i) {
                  _cards[i] = c;
                } else {
                  _cards.add(c);
                }
              }),
              disabledCards: const {},
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Position', style: TextStyle(color: Colors.white)),
            ),
            DropdownButton<HeroPosition>(
              value: _position,
              dropdownColor: Colors.black,
              onChanged: (v) => setState(() => _position = v ?? _position),
              items: [
                for (final p in HeroPosition.values)
                  if (p != HeroPosition.unknown)
                    DropdownMenuItem(
                      value: p,
                      child: Text(
                        p.label,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Stacks (BB)', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < widget.hand.numberOfPlayers; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _stacks[i],
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'P${i + 1}',
                    labelStyle: const TextStyle(color: Colors.white),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _expected,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Action',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            for (int s = 0; s < 4; s++)
              _StreetBlock(
                title: names[s],
                actions: _actions[s]!,
                playerCount: widget.hand.numberOfPlayers,
                onAdd: () => _add(s),
                onChanged: (i, e) => _update(s, i, e),
                onRemove: (i) => _remove(s, i),
              ),
          ],
        ),
      ),
    );
  }
}

class _StreetBlock extends StatelessWidget {
  final String title;
  final List<ActionEntry> actions;
  final int playerCount;
  final VoidCallback onAdd;
  final void Function(int index, ActionEntry entry) onChanged;
  final void Function(int index) onRemove;
  const _StreetBlock({
    required this.title,
    required this.actions,
    required this.playerCount,
    required this.onAdd,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      iconColor: Colors.white,
      collapsedIconColor: Colors.white,
      collapsedTextColor: Colors.white,
      textColor: Colors.white,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          itemBuilder: (_, i) => _ActionRow(
            entry: actions[i],
            playerCount: playerCount,
            onChanged: (e) => onChanged(i, e),
            onDelete: () => onRemove(i),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Action'),
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatefulWidget {
  final ActionEntry entry;
  final int playerCount;
  final ValueChanged<ActionEntry> onChanged;
  final VoidCallback onDelete;
  const _ActionRow({
    required this.entry,
    required this.playerCount,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  late int player;
  late String action;
  late TextEditingController amount;

  @override
  void initState() {
    super.initState();
    player = widget.entry.playerIndex;
    action = widget.entry.action;
    amount = TextEditingController(text: widget.entry.amount?.toString() ?? '');
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      ActionEntry(
        widget.entry.street,
        player,
        action,
        amount: double.tryParse(amount.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DropdownButton<int>(
          value: player,
          items: [
            for (int i = 0; i < widget.playerCount; i++)
              DropdownMenuItem(value: i, child: Text('P${i + 1}')),
          ],
          onChanged: (v) {
            setState(() => player = v ?? player);
            _emit();
          },
        ),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: action,
          items: const [
            DropdownMenuItem(value: 'fold', child: Text('fold')),
            DropdownMenuItem(value: 'call', child: Text('call')),
            DropdownMenuItem(value: 'raise', child: Text('raise')),
            DropdownMenuItem(value: 'push', child: Text('push')),
            DropdownMenuItem(value: 'post', child: Text('post')),
          ],
          onChanged: (v) {
            setState(() => action = v ?? action);
            _emit();
          },
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: TextField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Amount',
            ),
            onChanged: (_) => _emit(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: widget.onDelete,
        ),
      ],
    );
  }
}
