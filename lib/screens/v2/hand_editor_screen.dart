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
      : _cardsCtr = TextEditingController(text: _val(spot.note, 'Cards')),
        _posCtr = TextEditingController(text: _val(spot.note, 'Position')),
        _stacksCtr = TextEditingController(text: _val(spot.note, 'Stacks')),
        _actionsCtr = TextEditingController(text: _val(spot.note, 'Actions'));

  static String _val(String note, String key) {
    for (final line in note.split('\n')) {
      if (line.trim().startsWith('$key:')) {
        return line.split(':').skip(1).join(':').trim();
      }
    }
    return '';
  }

  void _update() {
    spot.note = [
      'Cards: ${_cardsCtr.text}',
      'Position: ${_posCtr.text}',
      'Stacks: ${_stacksCtr.text}',
      'Actions: ${_actionsCtr.text}',
    ].join('\n');
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
