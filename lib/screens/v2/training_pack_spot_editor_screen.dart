import 'package:flutter/material.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../helpers/training_pack_storage.dart';
import '../../helpers/title_utils.dart';
import '../../models/card_model.dart';
import '../../widgets/card_picker_widget.dart';
import '../../widgets/action_editor_list.dart';
import '../../models/action_entry.dart';
import '../../models/v2/hero_position.dart';
import '../../models/evaluation_result.dart';
import 'package:provider/provider.dart';
import '../../services/evaluation_executor_service.dart';
import '../../services/template_storage_service.dart';
import '../../core/training/engine/training_type_engine.dart';

class TrainingPackSpotEditorScreen extends StatefulWidget {
  final TrainingPackSpot spot;
  final List<String> templateTags;
  final TrainingType trainingType;
  const TrainingPackSpotEditorScreen({
    super.key,
    required this.spot,
    this.templateTags = const [],
    this.trainingType = TrainingType.postflop,
  });

  @override
  State<TrainingPackSpotEditorScreen> createState() =>
      _TrainingPackSpotEditorScreenState();
}

class _TrainingPackSpotEditorScreenState
    extends State<TrainingPackSpotEditorScreen> {
  late final TextEditingController _titleCtr;
  late final TextEditingController _noteCtr;
  late final TextEditingController _heroStackCtr;
  late final TextEditingController _villainStackCtr;
  late List<CardModel> _heroCards;
  late HeroPosition _position;
  late List<ActionEntry> _actions;
  int _priority = 3;
  bool _loading = false;
  int _street = 1;
  String _villainAction = 'none';
  final List<String> _availableHeroActs = [
    'check',
    'bet',
    'raise',
    'call',
    'fold',
  ];
  Set<String> _heroOptions = <String>{};

  Set<String> _usedCards() {
    final hero = _heroCards.map((c) => '${c.rank}${c.suit}');
    return {...hero, ...widget.spot.hand.board};
  }

  CardModel _toCard(String s) {
    return CardModel(rank: s[0], suit: s.substring(1));
  }

  void _setBoardCard(int index, CardModel card) {
    final b = widget.spot.hand.board;
    final v = '${card.rank}${card.suit}';
    setState(() {
      if (index < b.length) {
        b[index] = v;
      } else if (index == b.length) {
        b.add(v);
      }
      widget.spot.board = List<String>.from(widget.spot.hand.board);
    });
  }

  void _setHeroCard(int index, CardModel card) {
    setState(() {
      if (_heroCards.length > index) {
        _heroCards[index] = card;
      } else if (_heroCards.length == index) {
        _heroCards.add(card);
      }
      widget.spot.hand.heroCards =
          _heroCards.map((c) => '${c.rank}${c.suit}').join(' ');
    });
  }

  Widget _streetPicker(String label, int start, int count) {
    final b = widget.spot.hand.board;
    final end = (b.length - start).clamp(0, count);
    final cards = [for (int i = 0; i < end; i++) _toCard(b[start + i])];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        CardPickerWidget(
          cards: cards,
          count: count,
          onChanged: (i, c) => _setBoardCard(start + i, c),
          disabledCards: _usedCards(),
        ),
      ],
    );
  }

  Widget _evPreviewBox() {
    final EvaluationResult? res = widget.spot.evalResult;
    final bg = Colors.grey.shade800;
    if (res == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Text(
              'EV Preview',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            Spacer(),
            Text('Not evaluated', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    final ev = (res.expectedEquity * 100).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text(
            'EV Preview',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const Spacer(),
          Text('$ev%', style: const TextStyle(color: Colors.greenAccent)),
          const SizedBox(width: 8),
          Text(res.expectedAction, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Future<void> _addTagDialog() async {
    final service = context.read<TemplateStorageService>();
    final allTags = {
      ...service.templates.expand((t) => t.tags),
      ...widget.templateTags,
    }.toList();
    final c = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Tag'),
        content: Autocomplete<String>(
          optionsBuilder: (v) {
            final text = v.text.toLowerCase();
            if (text.isEmpty) return allTags;
            return allTags.where((e) => e.toLowerCase().contains(text));
          },
          onSelected: (s) => Navigator.pop(context, s),
          fieldViewBuilder: (context, controller, focus, _) {
            controller.text = c.text;
            controller.selection = c.selection;
            controller.addListener(() {
              if (c.text != controller.text) c.value = controller.value;
            });
            c.addListener(() {
              if (controller.text != c.text) controller.value = c.value;
            });
            return TextField(
              controller: controller,
              focusNode: focus,
              autofocus: true,
              onSubmitted: (v) => Navigator.pop(context, v.trim()),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    c.dispose();
    if (tag != null && tag.isNotEmpty && !widget.spot.tags.contains(tag)) {
      setState(() => widget.spot.tags.add(tag));
    }
  }

  @override
  void initState() {
    super.initState();
    widget.spot.title = normalizeSpotTitle(widget.spot.title);
    _titleCtr = TextEditingController(text: widget.spot.title);
    _noteCtr = TextEditingController(text: widget.spot.note);
    final stacks = widget.spot.hand.stacks;
    _heroStackCtr = TextEditingController(
      text: (stacks['0'] ?? 10).round().toString(),
    );
    _villainStackCtr = TextEditingController(
      text: (stacks['1'] ?? 10).round().toString(),
    );
    _heroCards = widget.spot.hand.heroCards
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .map(_toCard)
        .toList();
    _position = widget.spot.hand.position;
    if (_position == HeroPosition.unknown) _position = HeroPosition.sb;
    _actions = List<ActionEntry>.from(widget.spot.hand.actions[0] ?? []);
    _priority = widget.spot.priority;
    _street = widget.spot.street;
    if (_street == 0) {
      _street = widget.spot.hand.board.length >= 5
          ? 3
          : widget.spot.hand.board.length == 4
              ? 2
              : widget.spot.hand.board.length >= 3
                  ? 1
                  : 1;
    }
    _villainAction = widget.spot.villainAction ?? 'none';
    _heroOptions = widget.spot.heroOptions.toSet();
    widget.spot.hand.playerCount = 2;
    widget.spot.hand.heroIndex = 0;
  }

  @override
  void dispose() {
    _titleCtr.dispose();
    _noteCtr.dispose();
    _heroStackCtr.dispose();
    _villainStackCtr.dispose();
    super.dispose();
  }

  void _sync() {
    widget.spot.hand.heroCards =
        _heroCards.map((c) => '${c.rank}${c.suit}').join(' ');
    widget.spot.hand.position = _position;
    widget.spot.hand.stacks['0'] = double.tryParse(_heroStackCtr.text) ?? 0;
    widget.spot.hand.stacks['1'] = double.tryParse(_villainStackCtr.text) ?? 0;
    widget.spot.hand.playerCount = 2;
    widget.spot.hand.heroIndex = 0;
    widget.spot.hand.actions[0] = List<ActionEntry>.from(_actions);
    widget.spot.priority = _priority;
    widget.spot.board = List<String>.from(widget.spot.hand.board);
    widget.spot.street = _street;
    widget.spot.villainAction = _villainAction;
    widget.spot.heroOptions = _heroOptions.toList();
  }

  Future<void> _save() async {
    _sync();
    final normalized = normalizeSpotTitle(_titleCtr.text);
    widget.spot.title = normalized;
    _titleCtr.text = normalized;
    if (widget.spot.title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    widget.spot.editedAt = DateTime.now();
    final templates = await TrainingPackStorage.load();
    for (final t in templates) {
      for (var i = 0; i < t.spots.length; i++) {
        if (t.spots[i].id == widget.spot.id) {
          t.spots[i] = widget.spot;
        }
      }
    }
    await TrainingPackStorage.save(templates);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _evaluate() async {
    _sync();
    setState(() => _loading = true);
    try {
      final res = await context.read<EvaluationExecutorService>().evaluate(
            widget.spot,
          );
      setState(() => widget.spot.evalResult = res);
      final ev = (res.expectedEquity * 100).toStringAsFixed(1);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('EV $ev% ${res.expectedAction}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Evaluation failed')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit spot'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtr,
              decoration: const InputDecoration(labelText: 'Title'),
              autofocus: true,
              onChanged: (v) => setState(() => widget.spot.title = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteCtr,
              decoration: const InputDecoration(labelText: 'Note'),
              maxLines: 5,
              onChanged: (v) => setState(() => widget.spot.note = v),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final tag in widget.spot.tags)
                  InputChip(
                    label: Text(tag),
                    onDeleted: () =>
                        setState(() => widget.spot.tags.remove(tag)),
                  ),
                InputChip(label: const Text('+ Add'), onPressed: _addTagDialog),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButton<int>(
              value: _priority,
              items: [
                for (int i = 1; i <= 5; i++)
                  DropdownMenuItem(value: i, child: Text('Priority $i')),
              ],
              onChanged: (v) => setState(() => _priority = v ?? 3),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hero Cards',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CardPickerWidget(
              cards: _heroCards,
              onChanged: _setHeroCard,
              disabledCards: _usedCards(),
            ),
            const SizedBox(height: 16),
            DropdownButton<HeroPosition>(
              value: _position,
              items: [
                for (final p in HeroPosition.values)
                  DropdownMenuItem(value: p, child: Text(p.label)),
              ],
              onChanged: (v) => setState(() {
                _position = v ?? _position;
                widget.spot.hand.position = _position;
              }),
            ),
            const SizedBox(height: 16),
            const Text(
              'Stacks (BB)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _heroStackCtr,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Hero'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _villainStackCtr,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Villain'),
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
              positions: [_position.label, 'Villain'],
              onChanged: (v) => setState(() {
                _actions = v;
                widget.spot.hand.actions[0] = List.from(v);
              }),
            ),
            const SizedBox(height: 24),
            if (widget.trainingType != TrainingType.pushFold) ...[
              DropdownButton<int>(
                value: _street,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Flop')),
                  DropdownMenuItem(value: 2, child: Text('Turn')),
                  DropdownMenuItem(value: 3, child: Text('River')),
                ],
                onChanged: (v) => setState(() => _street = v ?? 1),
              ),
              const SizedBox(height: 16),
              _streetPicker('Flop', 0, 3),
              if (_street >= 2) ...[
                const SizedBox(height: 16),
                _streetPicker('Turn', 3, 1),
              ],
              if (_street >= 3) ...[
                const SizedBox(height: 16),
                _streetPicker('River', 4, 1),
              ],
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: _villainAction,
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('Villain: none')),
                  DropdownMenuItem(
                    value: 'check',
                    child: Text('Villain: check'),
                  ),
                  DropdownMenuItem(value: 'bet', child: Text('Villain: bet')),
                ],
                onChanged: (v) => setState(() => _villainAction = v ?? 'none'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  for (final act in _availableHeroActs)
                    FilterChip(
                      label: Text(act),
                      selected: _heroOptions.contains(act),
                      onSelected: (sel) => setState(() {
                        if (sel) {
                          _heroOptions.add(act);
                        } else {
                          _heroOptions.remove(act);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            _evPreviewBox(),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loading ? null : _evaluate,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Evaluate'),
            ),
          ],
        ),
      ),
    );
  }
}
