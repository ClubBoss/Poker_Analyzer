import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/training_pack_template_model.dart';

class TrainingPackTemplateEditorScreen extends StatefulWidget {
  final TrainingPackTemplateModel? initial;
  const TrainingPackTemplateEditorScreen({super.key, this.initial});

  @override
  State<TrainingPackTemplateEditorScreen> createState() =>
      _TrainingPackTemplateEditorScreenState();
}

class _TrainingPackTemplateEditorScreenState
    extends State<TrainingPackTemplateEditorScreen> {
  late TextEditingController _name;
  late TextEditingController _desc;
  late TextEditingController _category;
  late TextEditingController _filters;
  int _difficulty = 1;
  bool _isTournament = false;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    _name = TextEditingController(text: m?.name ?? '');
    _desc = TextEditingController(text: m?.description ?? '');
    _category = TextEditingController(text: m?.category ?? '');
    _filters = TextEditingController(
        text: m != null && m.filters.isNotEmpty ? jsonEncode(m.filters) : '');
    _difficulty = m?.difficulty ?? 1;
    _isTournament = m?.isTournament ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _category.dispose();
    _filters.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Map<String, dynamic> filters = {};
    final fText = _filters.text.trim();
    if (fText.isNotEmpty) {
      try {
        final data = jsonDecode(fText);
        if (data is Map<String, dynamic>) {
          filters = data;
        } else {
          throw const FormatException();
        }
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Некорректный JSON фильтров')));
        return;
      }
    }
    final model = TrainingPackTemplateModel(
      id: widget.initial?.id ?? const Uuid().v4(),
      name: name,
      description: _desc.text.trim(),
      category: _category.text.trim(),
      difficulty: _difficulty,
      filters: filters,
      isTournament: _isTournament,
      createdAt: widget.initial?.createdAt,
    );
    Navigator.pop(context, model);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Шаблон пака')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _desc,
              decoration: const InputDecoration(labelText: 'Описание'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'Категория'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _difficulty,
              decoration: const InputDecoration(labelText: 'Сложность'),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1')),
                DropdownMenuItem(value: 2, child: Text('2')),
                DropdownMenuItem(value: 3, child: Text('3')),
              ],
              onChanged: (v) => setState(() => _difficulty = v ?? 1),
            ),
            SwitchListTile(
              value: _isTournament,
              onChanged: (v) => setState(() => _isTournament = v),
              title: const Text('Турнирный режим'),
            ),
            TextField(
              controller: _filters,
              decoration: const InputDecoration(labelText: 'Фильтры (JSON)'),
              maxLines: null,
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
