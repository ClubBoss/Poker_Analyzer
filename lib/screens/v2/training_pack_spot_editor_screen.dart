import 'package:flutter/material.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../helpers/training_pack_storage.dart';
import '../../helpers/title_utils.dart';

class TrainingPackSpotEditorScreen extends StatefulWidget {
  final TrainingPackSpot spot;
  const TrainingPackSpotEditorScreen({super.key, required this.spot});

  @override
  State<TrainingPackSpotEditorScreen> createState() => _TrainingPackSpotEditorScreenState();
}

class _TrainingPackSpotEditorScreenState extends State<TrainingPackSpotEditorScreen> {
  late final TextEditingController _titleCtr;
  late final TextEditingController _noteCtr;

  Future<void> _addTagDialog() async {
    final c = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('OK')),
        ],
      ),
    );
    c.dispose();
    if (tag != null && tag.isNotEmpty) {
      setState(() => widget.spot.tags.add(tag));
    }
  }

  @override
  void initState() {
    super.initState();
    widget.spot.title = normalizeSpotTitle(widget.spot.title);
    _titleCtr = TextEditingController(text: widget.spot.title);
    _noteCtr = TextEditingController(text: widget.spot.note);
  }

  @override
  void dispose() {
    _titleCtr.dispose();
    _noteCtr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final normalized = normalizeSpotTitle(_titleCtr.text);
    widget.spot.title = normalized;
    _titleCtr.text = normalized;
    if (widget.spot.title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
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
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            for (final tag in widget.spot.tags)
              InputChip(
                label: Text(tag),
                onDeleted: () => setState(() => widget.spot.tags.remove(tag)),
              ),
            InputChip(
              label: const Text('+ Add'),
              onPressed: _addTagDialog,
            ),
          ],
        ),
          ],
        ),
      ),
    );
  }
}
