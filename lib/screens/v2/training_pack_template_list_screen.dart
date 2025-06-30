import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/v2/training_pack_template.dart';
import 'training_pack_template_editor_screen.dart';

class TrainingPackTemplateListScreen extends StatefulWidget {
  const TrainingPackTemplateListScreen({super.key});

  @override
  State<TrainingPackTemplateListScreen> createState() => _TrainingPackTemplateListScreenState();
}

class _TrainingPackTemplateListScreenState extends State<TrainingPackTemplateListScreen> {
  final List<TrainingPackTemplate> _templates = [];

  void _edit(TrainingPackTemplate template) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TrainingPackTemplateEditorScreen(template: template)),
    );
    setState(() {});
  }

  void _add() {
    final template = TrainingPackTemplate(id: const Uuid().v4(), name: 'New Pack');
    setState(() => _templates.add(template));
    _edit(template);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training Packs')),
      body: ListView.builder(
        itemCount: _templates.length,
        itemBuilder: (context, index) {
          final t = _templates[index];
          return ListTile(
            title: Text(t.name),
            trailing: TextButton(
              onPressed: () => _edit(t),
              child: const Text('📝 Edit'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}
