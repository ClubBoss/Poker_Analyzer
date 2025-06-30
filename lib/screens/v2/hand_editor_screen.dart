import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../helpers/training_pack_storage.dart';

class HandEditorScreen extends StatelessWidget {
  final TrainingPackSpot spot;
  final TextEditingController _cardsCtr;
  final TextEditingController _posCtr;
  final TextEditingController _stacksCtr;
  final TextEditingController _actionsCtr;

  HandEditorScreen({super.key, required this.spot})
      : _cardsCtr = TextEditingController(text: spot.hand.heroCards),
        _posCtr = TextEditingController(text: spot.hand.position),
        _stacksCtr = TextEditingController(
            text: spot.hand.stacks.isEmpty
                ? ''
                : jsonEncode(spot.hand.stacks)),
        _actionsCtr = TextEditingController(
            text: spot.hand.streetActions.isNotEmpty
                ? spot.hand.streetActions.first
                : '');

  void _update() {
    spot.hand.heroCards = _cardsCtr.text;
    spot.hand.position = _posCtr.text;
    try {
      final m = jsonDecode(_stacksCtr.text) as Map<String, dynamic>;
      spot.hand.stacks = {
        for (final e in m.entries) e.key: (e.value as num).toDouble()
      };
    } catch (_) {
      spot.hand.stacks = {};
    }
    spot.hand.streetActions =
        _actionsCtr.text.trim().isEmpty ? [] : [_actionsCtr.text];
  }

  Future<void> _save(BuildContext context) async {
    _update();
    final templates = await TrainingPackStorage.load();
    for (final t in templates) {
      for (var i = 0; i < t.spots.length; i++) {
        if (t.spots[i].id == spot.id) {
          t.spots[i] = spot;
          break;
        }
      }
    }
    await TrainingPackStorage.save(templates);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    void onChanged(String _) => _update();
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
            TextField(
              controller: _actionsCtr,
              decoration: const InputDecoration(labelText: 'Action line'),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
