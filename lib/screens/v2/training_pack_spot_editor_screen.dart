import 'package:flutter/material.dart';
import '../../models/v2/training_pack_spot.dart';

class TrainingPackSpotEditorScreen extends StatefulWidget {
  final TrainingPackSpot spot;
  const TrainingPackSpotEditorScreen({super.key, required this.spot});

  @override
  State<TrainingPackSpotEditorScreen> createState() => _TrainingPackSpotEditorScreenState();
}

class _TrainingPackSpotEditorScreenState extends State<TrainingPackSpotEditorScreen> {
  late final TextEditingController _titleCtr;
  late final TextEditingController _noteCtr;

  @override
  void initState() {
    super.initState();
    _titleCtr = TextEditingController(text: widget.spot.title);
    _noteCtr = TextEditingController(text: widget.spot.note);
  }

  @override
  void dispose() {
    _titleCtr.dispose();
    _noteCtr.dispose();
    super.dispose();
  }

  void _save() {
    if (widget.spot.title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit spot'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
          ],
        ),
      ),
    );
  }
}
