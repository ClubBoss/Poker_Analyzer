import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_hand.dart';
import '../models/training_pack_template.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/template_storage_service.dart';

class TemplateHandsEditorScreen extends StatefulWidget {
  final TrainingPackTemplate template;
  const TemplateHandsEditorScreen({super.key, required this.template});

  @override
  State<TemplateHandsEditorScreen> createState() =>
      _TemplateHandsEditorScreenState();
}

class _TemplateHandsEditorScreenState extends State<TemplateHandsEditorScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _gameType = 'Cash Game';
  late List<SavedHand> _hands;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.template.name;
    _descController.text = widget.template.description;
    _gameType = widget.template.gameType;
    _hands = List.from(widget.template.hands);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _addHand() async {
    final manager = context.read<SavedHandManagerService>();
    final hand = await manager.selectHand(context);
    if (hand != null && mounted && !_hands.contains(hand)) {
      setState(() => _hands.add(hand));
    }
  }

  void _removeHand(int index) {
    setState(() => _hands.removeAt(index));
  }

  void _reorderHand(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _hands.removeAt(oldIndex);
      _hands.insert(newIndex, item);
    });
  }

  void _save() {
    final updated = TrainingPackTemplate(
      id: widget.template.id,
      name: _nameController.text.trim(),
      gameType: _gameType,
      description: _descController.text.trim(),
      hands: _hands,
      version: widget.template.version,
      author: widget.template.author,
      revision: widget.template.revision,
      createdAt: widget.template.createdAt,
      updatedAt: DateTime.now(),
      isBuiltIn: widget.template.isBuiltIn,
    );
    context.read<TemplateStorageService>().updateTemplate(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактор шаблона'),
        actions: [IconButton(onPressed: _save, icon: const Icon(Icons.check))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Название'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Описание'),
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
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              onReorder: _reorderHand,
              itemCount: _hands.length,
              itemBuilder: (context, index) {
                final hand = _hands[index];
                final title = hand.name.isEmpty ? 'Без названия' : hand.name;
                return ListTile(
                  key: ValueKey(hand),
                  title: Text(title),
                  subtitle:
                      hand.tags.isEmpty ? null : Text(hand.tags.join(', ')),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeHand(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHand,
        child: const Icon(Icons.add),
      ),
    );
  }
}
