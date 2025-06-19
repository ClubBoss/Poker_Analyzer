import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tag_service.dart';

class TagManagementScreen extends StatelessWidget {
  const TagManagementScreen({super.key});

  Future<void> _addTag(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый тег'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Tag'),
        ),
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
    if (result != null && result.isNotEmpty) {
      await context.read<TagService>().addTag(result);
    }
  }

  Future<void> _renameTag(BuildContext context, int index, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Переименовать тег'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Tag'),
        ),
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
    if (result != null && result.isNotEmpty) {
      await context.read<TagService>().renameTag(index, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = context.watch<TagService>().tags;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Теги'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Экспорт',
            onPressed: () =>
                context.read<TagService>().exportToFile(context),
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Импорт',
            onPressed: () =>
                context.read<TagService>().importFromFile(context),
          ),
        ],
      ),
      body: ReorderableListView(
        onReorder: (oldIndex, newIndex) =>
            context.read<TagService>().reorderTags(oldIndex, newIndex),
        children: [
          for (int i = 0; i < tags.length; i++)
            ListTile(
              key: ValueKey(tags[i]),
              title: Text(tags[i]),
              leading: const Icon(Icons.drag_handle),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _renameTag(context, i, tags[i]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => context.read<TagService>().deleteTag(i),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTag(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
