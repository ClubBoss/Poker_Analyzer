import 'package:flutter/material.dart';
import '../../models/v2/training_pack_template.dart';

class TrainingPackTemplateEditorScreen extends StatefulWidget {
  final TrainingPackTemplate template;
  const TrainingPackTemplateEditorScreen({super.key, required this.template});

  @override
  State<TrainingPackTemplateEditorScreen> createState() => _TrainingPackTemplateEditorScreenState();
}

class _TrainingPackTemplateEditorScreenState extends State<TrainingPackTemplateEditorScreen> {
  late final TextEditingController _nameCtr;
  late final TextEditingController _descCtr;

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
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit pack'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtr,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
              onChanged: (v) => setState(() => widget.template.name = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtr,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
              onChanged: (v) => setState(() => widget.template.description = v),
            ),
          ],
        ),
      ),
    );
  }
}
