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
  State<TemplateHandsEditorScreen> createState() => _TemplateHandsEditorScreenState();
}

class _TemplateHandsEditorScreenState extends State<TemplateHandsEditorScreen> {
  late List<SavedHand> _hands;

  @override
  void initState() {
    super.initState();
    _hands = List.from(widget.template.hands);
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

  void _save() {
    final updated = TrainingPackTemplate(
      id: widget.template.id,
      name: widget.template.name,
      gameType: widget.template.gameType,
      description: widget.template.description,
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
        title: const Text('Раздачи шаблона'),
        actions: [IconButton(onPressed: _save, icon: const Icon(Icons.check))],
      ),
      body: ListView.builder(
        itemCount: _hands.length,
        itemBuilder: (context, index) {
          final hand = _hands[index];
          final title = hand.name.isEmpty ? 'Без названия' : hand.name;
          return ListTile(
            title: Text(title),
            subtitle: hand.tags.isEmpty ? null : Text(hand.tags.join(', ')),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeHand(index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHand,
        child: const Icon(Icons.add),
      ),
    );
  }
}
