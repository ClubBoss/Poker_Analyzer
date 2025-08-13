import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tag_service.dart';
import '../helpers/color_utils.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../widgets/sync_status_widget.dart';

class TagManagementScreen extends StatelessWidget {
  const TagManagementScreen({super.key});

  Future<MapEntry<String, String>?> _showTagDialog(
      BuildContext context, String title,
      {String? initialName, String? initialColor}) {
    final controller = TextEditingController(text: initialName ?? '');
    Color pickerColor =
        initialColor != null ? colorFromHex(initialColor) : Colors.blue;
    return showDialog<MapEntry<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: 'Tag'),
                ),
                const SizedBox(height: 8),
                BlockPicker(
                  pickerColor: pickerColor,
                  onColorChanged: (c) => setStateDialog(() => pickerColor = c),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context,
                MapEntry(controller.text.trim(), colorToHex(pickerColor))),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _addTag(BuildContext context) async {
    final result = await _showTagDialog(context, 'Новый тег');
    if (result != null && result.key.isNotEmpty) {
      await context.read<TagService>().addTag(result.key, color: result.value);
    }
  }

  Future<void> _renameTag(
      BuildContext context, int index, String current) async {
    final color = context.read<TagService>().colorOf(current);
    final result = await _showTagDialog(context, 'Переименовать тег',
        initialName: current, initialColor: color);
    if (result != null && result.key.isNotEmpty) {
      await context
          .read<TagService>()
          .renameTag(index, result.key, color: result.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = context.watch<TagService>().tags;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Теги'),
        actions: [
          SyncStatusIcon.of(context),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Экспорт',
            onPressed: () => context.read<TagService>().exportToFile(context),
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Импорт',
            onPressed: () => context.read<TagService>().importFromFile(context),
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
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colorFromHex(
                          context.read<TagService>().colorOf(tags[i])),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.drag_handle),
                ],
              ),
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
