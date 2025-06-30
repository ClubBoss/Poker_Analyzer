import 'package:flutter/material.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../models/v2/hero_position.dart';
import '../../helpers/training_pack_storage.dart';
import '../../widgets/action_list_widget.dart';

class HandEditorScreen extends StatefulWidget {
  final TrainingPackSpot spot;
  const HandEditorScreen({super.key, required this.spot});

  @override
  State<HandEditorScreen> createState() => _HandEditorScreenState();
}

class _HandEditorScreenState extends State<HandEditorScreen> {
  late TextEditingController _cardsCtr;
  List<TextEditingController> _stackCtr = [];
  late HeroPosition _position;
  int _street = 0;

  @override
  void initState() {
    super.initState();
    _cardsCtr = TextEditingController(text: widget.spot.hand.heroCards);
    _position = widget.spot.hand.position;
    _stackCtr = [
      for (var i = 0; i < widget.spot.hand.playerCount; i++)
        TextEditingController(
          text: widget.spot.hand.stacks['$i']?.toString() ?? '',
        )
    ];
  }

  @override
  void dispose() {
    _cardsCtr.dispose();
    for (final c in _stackCtr) c.dispose();
    super.dispose();
  }

  void _update() {
    _updateStacks();
    widget.spot.hand.heroCards = _cardsCtr.text;
    widget.spot.hand.position = _position;
  }

  void _updateStacks() {
    final m = <String, double>{};
    for (var i = 0; i < _stackCtr.length; i++) {
      final v = double.tryParse(_stackCtr[i].text) ?? 0;
      m['$i'] = v;
    }
    widget.spot.hand.stacks = m;
  }

  bool _validateStacks() {
    final stacks = widget.spot.hand.stacks;
    final hero = stacks['${widget.spot.hand.heroIndex}'];
    if (hero == null || hero <= 0) return false;
    int count = 0;
    for (final v in stacks.values) {
      if (v > 0) count++;
    }
    return count >= 2;
  }

  Future<void> _save(BuildContext context) async {
    _update();
    if (!_validateStacks()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: стеков недостаточно для розыгрыша')),
      );
      return;
    }
    widget.spot.editedAt = DateTime.now();
    final templates = await TrainingPackStorage.load();
    for (final t in templates) {
      for (var i = 0; i < t.spots.length; i++) {
        if (t.spots[i].id == widget.spot.id) {
          t.spots[i] = widget.spot;
          break;
        }
      }
    }
    await TrainingPackStorage.save(templates);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    void onChanged(String _) => _update();
    const names = ['Preflop', 'Flop', 'Turn', 'River'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Hand'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
              icon: const Icon(Icons.save), onPressed: () => _save(context))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _cardsCtr,
              decoration: const InputDecoration(labelText: 'Hero cards'),
              onChanged: onChanged,
            ),
            const SizedBox(height: 16),
            DropdownButton<HeroPosition>(
              value: _position,
              items: [
                for (final p in HeroPosition.values)
                  DropdownMenuItem(value: p, child: Text(p.label))
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _position = v;
                  _update();
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Player count'),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: widget.spot.hand.playerCount,
                  items: [
                    for (int i = 2; i <= 9; i++)
                      DropdownMenuItem(value: i, child: Text('$i'))
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      for (var i = _stackCtr.length; i < v; i++) {
                        _stackCtr
                            .add(TextEditingController(text: widget.spot.hand.stacks['$i']?.toString() ?? ''));
                      }
                      while (_stackCtr.length > v) {
                        _stackCtr.removeLast().dispose();
                      }
                      widget.spot.hand.playerCount = v;
                      if (widget.spot.hand.heroIndex >= v) {
                        widget.spot.hand.heroIndex = 0;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Hero index выходит за пределы — сброшен в 0')),
                        );
                      }
                      _updateStacks();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Stacks (BB)'),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.spot.hand.playerCount,
              itemBuilder: (_, i) {
                final ctrl = _stackCtr[i];
                return Row(
                  children: [
                    SizedBox(width: 32, child: Text('P$i')),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'BB',
                          contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        ),
                        onChanged: (_) => _updateStacks(),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Hero index'),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: widget.spot.hand.heroIndex,
                  items: [
                    for (int i = 0; i < widget.spot.hand.playerCount; i++)
                      DropdownMenuItem(value: i, child: Text('$i'))
                  ],
                  onChanged: (v) =>
                      setState(() => widget.spot.hand.heroIndex = v ?? 0),
                ),
                const SizedBox(width: 8),
                const Tooltip(
                  message: '0 — SB, 1 — BB, 2 — UTG, 3 — MP, 4 — CO, 5 — BTN',
                  child:
                      Icon(Icons.info_outline, size: 16, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButton<int>(
              value: _street,
              items: [
                for (int i = 0; i < 4; i++)
                  DropdownMenuItem(value: i, child: Text(names[i]))
              ],
              onChanged: (v) => setState(() => _street = v ?? 0),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ActionListWidget(
                playerCount: widget.spot.hand.playerCount,
                heroIndex: widget.spot.hand.heroIndex,
                initial: widget.spot.hand.actions[_street],
                onChanged: (list) => widget.spot.hand.actions[_street] = list,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
