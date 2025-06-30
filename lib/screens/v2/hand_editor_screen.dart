import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/v2/training_pack_spot.dart';
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
  late TextEditingController _posCtr;
  late TextEditingController _stacksCtr;
  int _street = 0;

  @override
  void initState() {
    super.initState();
    _cardsCtr = TextEditingController(text: widget.spot.hand.heroCards);
    _posCtr = TextEditingController(text: widget.spot.hand.position);
    _stacksCtr = TextEditingController(
        text: widget.spot.hand.stacks.isEmpty
            ? ''
            : jsonEncode(widget.spot.hand.stacks));
  }

  @override
  void dispose() {
    _cardsCtr.dispose();
    _posCtr.dispose();
    _stacksCtr.dispose();
    super.dispose();
  }

  void _update() {
    widget.spot.hand.heroCards = _cardsCtr.text;
    widget.spot.hand.position = _posCtr.text;
    try {
      final m = jsonDecode(_stacksCtr.text) as Map<String, dynamic>;
      widget.spot.hand.stacks = {
        for (final e in m.entries) e.key: (e.value as num).toDouble()
      };
    } catch (_) {
      widget.spot.hand.stacks = {};
    }
  }

  Future<void> _save(BuildContext context) async {
    _update();
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
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: () => _save(context))],
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
            TextField(
              controller: _posCtr,
              decoration: const InputDecoration(labelText: 'Position'),
              onChanged: onChanged,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _stacksCtr,
              decoration: const InputDecoration(labelText: 'Stacks'),
              onChanged: onChanged,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Hero index'),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: widget.spot.hand.heroIndex,
                  items: [for (int i = 0; i < 6; i++) DropdownMenuItem(value: i, child: Text('$i'))],
                  onChanged: (v) => setState(() => widget.spot.hand.heroIndex = v ?? 0),
                ),
                const SizedBox(width: 8),
                const Tooltip(
                  message: '0 — SB, 1 — BB, 2 — UTG, 3 — MP, 4 — CO, 5 — BTN',
                  child: Icon(Icons.info_outline, size: 16, color: Colors.white54),
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
                playerCount: 6,
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

