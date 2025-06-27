import 'package:flutter/material.dart';

import '../models/training_pack_template_model.dart';
import '../repositories/training_pack_template_repository.dart';
import 'training_pack_template_editor_screen.dart';

class TrainingPackTemplateListScreen extends StatefulWidget {
  const TrainingPackTemplateListScreen({super.key});

  @override
  State<TrainingPackTemplateListScreen> createState() => _TrainingPackTemplateListScreenState();
}

class _TrainingPackTemplateListScreenState extends State<TrainingPackTemplateListScreen> {
  List<TrainingPackTemplateModel> _templates = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await TrainingPackTemplateRepository.getAll();
    if (mounted) setState(() => _templates = list);
  }

  Future<void> _add() async {
    final model = await Navigator.push<TrainingPackTemplateModel>(
      context,
      MaterialPageRoute(builder: (_) => const TrainingPackTemplateEditorScreen()),
    );
    if (model != null && mounted) setState(() => _templates.add(model));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Шаблоны паков')),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: _templates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _templates.length,
              itemBuilder: (context, i) {
                final t = _templates[i];
                return ListTile(
                  title: Text(t.name),
                  subtitle: Text('${t.category} • ${t.difficulty}'),
                );
              },
            ),
    );
  }
}
