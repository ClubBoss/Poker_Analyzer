import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../models/training_pack_template_model.dart';
import '../services/training_pack_template_storage_service.dart';
import 'training_pack_template_editor_screen.dart';

class TrainingPackTemplateListScreen extends StatefulWidget {
  const TrainingPackTemplateListScreen({super.key});

  @override
  State<TrainingPackTemplateListScreen> createState() => _TrainingPackTemplateListScreenState();
}

class _TrainingPackTemplateListScreenState
    extends State<TrainingPackTemplateListScreen> {
  Future<void> _add() async {
    final model = await Navigator.push<TrainingPackTemplateModel>(
      context,
      MaterialPageRoute(builder: (_) => const TrainingPackTemplateEditorScreen()),
    );
    if (model != null && mounted) {
      await context.read<TrainingPackTemplateStorageService>().add(model);
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = context.watch<TrainingPackTemplateStorageService>().templates;
    return Scaffold(
      appBar: AppBar(title: const Text('Шаблоны паков')),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: templates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: templates.length,
              itemBuilder: (context, i) {
                final t = templates[i];
                return Dismissible(
                  key: ValueKey(t.id),
                  onDismissed: (_) =>
                      context.read<TrainingPackTemplateStorageService>().remove(t),
                  child: ListTile(
                    onTap: () async {
                      final model = await Navigator.push<TrainingPackTemplateModel>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => TrainingPackTemplateEditorScreen(initial: t)),
                      );
                      if (model != null && mounted) {
                        await context
                            .read<TrainingPackTemplateStorageService>()
                            .update(model);
                      }
                    },
                    title: Text(t.name),
                    subtitle: Text(
                        '${t.category.isEmpty ? 'Без категории' : t.category} • сложность: ${t.difficulty}'),
                  ),
                );
              },
            ),
    );
  }
}
