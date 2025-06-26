import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_pack_template.dart';
import '../models/saved_hand.dart';
import '../services/training_pack_storage_service.dart';

class CreatePackFromTemplateScreen extends StatefulWidget {
  final TrainingPackTemplate template;
  const CreatePackFromTemplateScreen({super.key, required this.template});

  @override
  State<CreatePackFromTemplateScreen> createState() => _CreatePackFromTemplateScreenState();
}

class _CreatePackFromTemplateScreenState extends State<CreatePackFromTemplateScreen> {
  late List<SavedHand> _selected;
  final TextEditingController _category = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.template.hands);
  }

  void _toggle(SavedHand h) {
    setState(() {
      if (_selected.contains(h)) {
        _selected.remove(h);
      } else {
        _selected.add(h);
      }
    });
  }

  Future<void> _create() async {
    if (_selected.isEmpty) return;
    await context.read<TrainingPackStorageService>().createFromTemplate(
      widget.template,
      hands: _selected,
      categoryOverride: _category.text.trim(),
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Пакет создан из шаблона')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name),
        actions: [IconButton(onPressed: _create, icon: const Icon(Icons.check))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'Категория (опц.)'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.template.hands.length,
              itemBuilder: (_, i) {
                final h = widget.template.hands[i];
                return CheckboxListTile(
                  value: _selected.contains(h),
                  onChanged: (_) => _toggle(h),
                  title: Text(h.name.isNotEmpty ? h.name : 'Раздача ${i + 1}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
