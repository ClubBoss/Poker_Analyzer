import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/saved_hand.dart';
import '../models/training_pack_template.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/template_storage_service.dart';
import '../widgets/sync_status_widget.dart';

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
  final TextEditingController _categoryController = TextEditingController();
  String _gameType = 'Cash Game';
  late List<SavedHand> _hands;
  final Map<SavedHand, String> _ids = {};
  final Set<String> _selectedIds = {};
  bool get _isSelecting => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.template.name;
    _descController.text = widget.template.description;
    _categoryController.text = widget.template.category ?? '';
    _gameType = widget.template.gameType;
    _hands = List.from(widget.template.hands);
    for (final h in _hands) {
      _ids[h] = const Uuid().v4();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _addHand() async {
    final manager = context.read<SavedHandManagerService>();
    final hand = await manager.selectHand(context);
    if (hand != null && mounted && !_hands.contains(hand)) {
      setState(() {
        _hands.add(hand);
        _ids[hand] = const Uuid().v4();
      });
    }
  }

  void _removeHand(int index) {
    final hand = _hands.removeAt(index);
    final id = _ids.remove(hand);
    setState(() {
      _selectedIds.remove(id);
    });
  }

  void _reorderHand(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _hands.removeAt(oldIndex);
      _hands.insert(newIndex, item);
    });
  }

  SavedHand? _handById(String id) {
    for (final entry in _ids.entries) {
      if (entry.value == id) return entry.key;
    }
    return null;
  }

  Future<void> _bulkAddTag() async {
    final c = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('OK')),
        ],
      ),
    );
    if (tag == null || tag.isEmpty) return;
    setState(() {
      for (final id in _selectedIds) {
        final h = _handById(id);
        if (h != null && !h.tags.contains(tag)) h.tags.add(tag);
      }
      _selectedIds.clear();
    });
  }

  Future<void> _bulkRemoveTag() async {
    final hands = [for (final id in _selectedIds) _handById(id)].whereType<SavedHand>().toList();
    if (hands.isEmpty) return;
    Set<String> tags = Set.from(hands.first.tags);
    for (final h in hands.skip(1)) {
      tags = tags.intersection(h.tags.toSet());
    }
    if (tags.isEmpty) return;
    String? selected = tags.first;
    final tag = await showDialog<String>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Remove Tag'),
          content: DropdownButton<String>(
            value: selected,
            items: [for (final t in tags) DropdownMenuItem(value: t, child: Text(t))],
            onChanged: (v) => setStateDialog(() => selected = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, selected), child: const Text('OK')),
          ],
        ),
      ),
    );
    if (tag == null) return;
    setState(() {
      for (final id in _selectedIds) {
        final h = _handById(id);
        h?.tags.remove(tag);
      }
      _selectedIds.clear();
    });
  }

  Future<void> _bulkDelete() async {
    final count = _selectedIds.length;
    if (count == 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete $count spots?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok ?? false) {
      setState(() {
        _hands.removeWhere((h) => _selectedIds.contains(_ids[h]));
        _ids.removeWhere((h, id) => _selectedIds.contains(id));
        _selectedIds.clear();
      });
    }
  }

  void _save() {
    final updated = TrainingPackTemplate(
      id: widget.template.id,
      name: _nameController.text.trim(),
      gameType: _gameType,
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
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
        leading: _isSelecting
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedIds.clear()),
              )
            : null,
        title: _isSelecting
            ? Text('${_selectedIds.length} selected')
            : const Text('Редактор шаблона'),
        actions: _isSelecting
            ? [
                IconButton(icon: const Icon(Icons.label), onPressed: _bulkAddTag),
                IconButton(icon: const Icon(Icons.label_off), onPressed: _bulkRemoveTag),
                IconButton(icon: const Icon(Icons.delete), onPressed: _bulkDelete),
              ]
            : [SyncStatusIcon.of(context), IconButton(onPressed: _save, icon: const Icon(Icons.check))],
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
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              onReorder: _reorderHand,
              itemCount: _hands.length,
              itemBuilder: (context, index) {
                final hand = _hands[index];
                final id = _ids[hand]!;
                final selected = _selectedIds.contains(id);
                final title = hand.name.isEmpty ? 'Без названия' : hand.name;
                return ListTile(
                  key: ValueKey(id),
                  tileColor: selected ? Colors.blue.withValues(alpha: 0.3) : null,
                  onLongPress: () => setState(() => _selectedIds.add(id)),
                  onTap: _isSelecting
                      ? () {
                          setState(() {
                            if (selected) {
                              _selectedIds.remove(id);
                            } else {
                              _selectedIds.add(id);
                            }
                          });
                        }
                      : null,
                  title: Text(title),
                  subtitle: hand.tags.isEmpty ? null : Text(hand.tags.join(', ')),
                  trailing: _isSelecting
                      ? Checkbox(
                          value: selected,
                          onChanged: (_) {
                            setState(() {
                              if (selected) {
                                _selectedIds.remove(id);
                              } else {
                                _selectedIds.add(id);
                              }
                            });
                          },
                        )
                      : IconButton(
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
