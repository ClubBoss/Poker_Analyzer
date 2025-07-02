import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

const _validStreets = ['preflop', 'flop', 'turn', 'river'];

import '../models/training_pack_template_model.dart';
import '../widgets/sync_status_widget.dart';
import '../services/training_pack_template_storage_service.dart';

class TrainingPackTemplateEditorScreen extends StatefulWidget {
  final TrainingPackTemplateModel? initial;
  const TrainingPackTemplateEditorScreen({super.key, this.initial});

  @override
  State<TrainingPackTemplateEditorScreen> createState() =>
      _TrainingPackTemplateEditorScreenState();
}

class _TrainingPackTemplateEditorScreenState
    extends State<TrainingPackTemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _desc;
  late TextEditingController _category;
  late TextEditingController _filters;
  int _difficulty = 1;
  late String _templateName;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    _templateName = m?.name ?? '';
    _name = TextEditingController(text: _templateName);
    _desc = TextEditingController(text: m?.description ?? '');
    _category = TextEditingController(text: m?.category ?? '');
    Map<String, dynamic> f = {};
    if (m != null && m.filters.isNotEmpty) {
      f = Map<String, dynamic>.from(m.filters);
    }
    var streets = f['streets'];
    if (streets is List) {
      streets = streets
          .whereType<String>()
          .where((s) => _validStreets.contains(s))
          .toList();
    }
    if (streets is! List || streets.isEmpty) {
      streets = ['preflop'];
    }
    f['streets'] = streets;
    _filters =
        TextEditingController(text: const JsonEncoder.withIndent('  ').convert(f));
    _difficulty = m?.difficulty ?? 1;
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
    if (!_formKey.currentState!.validate()) return;
    final name = _name.text.trim();
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
    final streets = filters['streets'];
    if (streets is! List || streets.isEmpty || streets.any((e) => e is! String)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Некорректный список улиц')));
      return;
    }
    for (final s in streets) {
      if (!_validStreets.contains(s)) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Улица "$s" не поддерживается')));
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
      isTournament: widget.initial?.isTournament ?? false,
      createdAt: widget.initial?.createdAt,
    );
    Navigator.pop(context, model);
  }

  Future<void> _renameTemplate() async {
    final ctrl = TextEditingController(text: _templateName);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename template'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final name = ctrl.text.trim();
      if (name.isNotEmpty) {
        setState(() {
          _templateName = name;
          _name.text = name;
        });
        final model = widget.initial?.copyWith(name: name);
        if (model != null) {
          await context.read<TrainingPackTemplateStorageService>().update(model);
        }
      }
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _renameTemplate,
          child: Text(_templateName.isEmpty ? 'Шаблон пака' : _templateName),
        ),
        actions: [SyncStatusIcon.of(context)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Название'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Обязательное поле' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Описание'),
              ),
              const SizedBox(height: 16),
              TextFormField(
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
