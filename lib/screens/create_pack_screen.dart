import 'package:flutter/material.dart';

import '../models/training_pack.dart';

class CreatePackScreen extends StatefulWidget {
  final TrainingPack? initialPack;

  const CreatePackScreen({super.key, this.initialPack});

  @override
  State<CreatePackScreen> createState() => _CreatePackScreenState();
}

class _CreatePackScreenState extends State<CreatePackScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final pack = widget.initialPack;
    if (pack != null) {
      _nameController.text = pack.name;
      _descriptionController.text = pack.description;
      _categoryController.text = pack.category;
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final category = _categoryController.text.trim();
    final pack = TrainingPack(
      name: name,
      description: _descriptionController.text.trim(),
      category: category.isEmpty ? 'Uncategorized' : category,
      hands: widget.initialPack?.hands ?? const [],
    );
    Navigator.pop(context, pack);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialPack == null ? 'Новый пакет' : 'Редактирование'),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Название',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Описание',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _categoryController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Категория',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
