import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/v2/training_pack_template.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../helpers/training_pack_storage.dart';
import 'training_pack_spot_editor_screen.dart';
import '../../widgets/v2/training_pack_spot_preview_card.dart';

class TrainingPackTemplateEditorScreen extends StatefulWidget {
  final TrainingPackTemplate template;
  final List<TrainingPackTemplate> templates;
  const TrainingPackTemplateEditorScreen({
    super.key,
    required this.template,
    required this.templates,
  });

  @override
  State<TrainingPackTemplateEditorScreen> createState() => _TrainingPackTemplateEditorScreenState();
}

class _TrainingPackTemplateEditorScreenState extends State<TrainingPackTemplateEditorScreen> {
  late final TextEditingController _nameCtr;
  late final TextEditingController _descCtr;

  void _addSpot() async {
    final spot = TrainingPackSpot(id: const Uuid().v4(), title: 'New spot');
    setState(() => widget.template.spots.add(spot));
    TrainingPackStorage.save(widget.templates);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TrainingPackSpotEditorScreen(spot: spot)),
    );
    setState(() {});
    TrainingPackStorage.save(widget.templates);
  }

  @override
  void initState() {
    super.initState();
    _nameCtr = TextEditingController(text: widget.template.name);
    _descCtr = TextEditingController(text: widget.template.description);
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _descCtr.dispose();
    super.dispose();
  }

  void _save() {
    if (widget.template.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    TrainingPackStorage.save(widget.templates);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit pack'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
      ),
      floatingActionButton:
          FloatingActionButton(onPressed: _addSpot, child: const Icon(Icons.add)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtr,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
              onChanged: (v) {
                setState(() => widget.template.name = v);
                TrainingPackStorage.save(widget.templates);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtr,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
              onChanged: (v) {
                setState(() => widget.template.description = v);
                TrainingPackStorage.save(widget.templates);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: widget.template.spots.length,
                itemBuilder: (context, index) {
                  final spot = widget.template.spots[index];
                  return Container(
                    key: ValueKey(spot.id),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: TrainingPackSpotPreviewCard(spot: spot)),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => TrainingPackSpotEditorScreen(spot: spot)),
                                );
                                setState(() {});
                                TrainingPackStorage.save(widget.templates);
                              },
                              child: const Text('📝 Edit'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete spot?'),
                                    actions: [
                                      TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel')),
                                      TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Delete')),
                                    ],
                                  ),
                                );
                                if (ok ?? false) {
                                  setState(() => widget.template.spots.removeAt(index));
                                  TrainingPackStorage.save(widget.templates);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                onReorder: (o, n) {
                  setState(() {
                    final s = widget.template.spots.removeAt(o);
                    widget.template.spots.insert(n > o ? n - 1 : n, s);
                  });
                  TrainingPackStorage.save(widget.templates);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
