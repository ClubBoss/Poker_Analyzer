import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/pack_matrix_config.dart';
import '../theme/app_colors.dart';

class PackMatrixConfigEditorScreen extends StatefulWidget {
  const PackMatrixConfigEditorScreen({super.key});

  @override
  State<PackMatrixConfigEditorScreen> createState() =>
      _PackMatrixConfigEditorScreenState();
}

class _PackMatrixConfigEditorScreenState
    extends State<PackMatrixConfigEditorScreen> {
  final List<(String, List<String>)> _matrix = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await const PackMatrixConfig().loadMatrix();
    if (!mounted) return;
    setState(() {
      _matrix
        ..clear()
        ..addAll(data);
      _loading = false;
    });
  }

  Future<void> _save() async {
    await const PackMatrixConfig().saveMatrix(_matrix);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Сохранено')));
  }

  void _reorderAudience(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _matrix.removeAt(oldIndex);
      _matrix.insert(newIndex, item);
    });
  }

  Future<void> _addAudience() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая аудитория'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    setState(() => _matrix.add((name, [])));
  }

  Future<void> _renameAudience(int index) async {
    final item = _matrix[index];
    final controller = TextEditingController(text: item.$1);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Переименовать'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    setState(() => _matrix[index] = (name, item.$2));
  }

  Future<void> _editTags(int index) async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _TagsEditorScreen(initial: List<String>.from(_matrix[index].$2)),
      ),
    );
    if (result != null) {
      setState(() => _matrix[index] = (_matrix[index].$1, result));
    }
  }

  void _removeAudience(int index) {
    setState(() => _matrix.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tag Matrix'),
        actions: [IconButton(onPressed: _save, icon: const Icon(Icons.save))],
      ),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ReorderableListView(
              onReorder: _reorderAudience,
              padding: const EdgeInsets.all(16),
              children: [
                for (int i = 0; i < _matrix.length; i++)
                  Card(
                    key: ValueKey(_matrix[i].$1),
                    color: AppColors.cardBackground,
                    child: ListTile(
                      title: Text(_matrix[i].$1),
                      subtitle: Wrap(
                        spacing: 4,
                        children: [
                          for (final t in _matrix[i].$2) Chip(label: Text(t)),
                        ],
                      ),
                      leading: const Icon(Icons.drag_handle),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _renameAudience(i),
                          ),
                          IconButton(
                            icon: const Icon(Icons.list),
                            onPressed: () => _editTags(i),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeAudience(i),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAudience,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TagsEditorScreen extends StatefulWidget {
  const _TagsEditorScreen({required this.initial});
  final List<String> initial;

  @override
  State<_TagsEditorScreen> createState() => _TagsEditorScreenState();
}

class _TagsEditorScreenState extends State<_TagsEditorScreen> {
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _tags = [...widget.initial];
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _tags.removeAt(oldIndex);
      _tags.insert(newIndex, item);
    });
  }

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый тег'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (tag == null || tag.isEmpty) return;
    setState(() => _tags.add(tag));
  }

  void _removeTag(int index) {
    setState(() => _tags.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Теги'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context, _tags),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: ReorderableListView(
        onReorder: _reorder,
        padding: const EdgeInsets.all(16),
        children: [
          for (int i = 0; i < _tags.length; i++)
            ListTile(
              key: ValueKey(_tags[i] + i.toString()),
              title: Text(_tags[i]),
              leading: const Icon(Icons.drag_handle),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _removeTag(i),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTag,
        child: const Icon(Icons.add),
      ),
    );
  }
}
