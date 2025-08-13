import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../models/training_pack_template.dart';
import '../widgets/sync_status_widget.dart';

class _SaveIntent extends Intent {
  const _SaveIntent();
}

class CreateTemplateScreen extends StatefulWidget {
  const CreateTemplateScreen({super.key});

  @override
  State<CreateTemplateScreen> createState() => _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends State<CreateTemplateScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  String _gameType = 'Cash Game';

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final template = TrainingPackTemplate(
      id: const Uuid().v4(),
      name: name,
      gameType: _gameType,
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      description: _descController.text.trim(),
      hands: const [],
      isBuiltIn: false,
    );
    Navigator.pop(context, template);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать шаблон'),
        actions: [SyncStatusIcon.of(context)],
      ),
      body: Shortcuts(
        shortcuts: const {
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.enter):
              _SaveIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.enter):
              _SaveIntent(),
        },
        child: Actions(
          actions: {
            _SaveIntent: CallbackAction<_SaveIntent>(onInvoke: (_) => _save()),
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Focus(
                  autofocus: true,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Название'),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Описание'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _categoryController,
                  decoration:
                      const InputDecoration(labelText: 'Категория (опц.)'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _gameType,
                  decoration: const InputDecoration(labelText: 'Тип игры'),
                  items: const [
                    DropdownMenuItem(
                        value: 'Tournament', child: Text('Tournament')),
                    DropdownMenuItem(
                        value: 'Cash Game', child: Text('Cash Game')),
                  ],
                  onChanged: (v) =>
                      setState(() => _gameType = v ?? 'Cash Game'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text('Далее'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
