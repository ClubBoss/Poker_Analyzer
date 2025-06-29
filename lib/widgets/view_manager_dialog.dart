import 'package:flutter/material.dart';
import '../models/view_preset.dart';

class ViewManagerDialog extends StatefulWidget {
  final List<ViewPreset> views;
  final ValueChanged<List<ViewPreset>> onChanged;
  const ViewManagerDialog({super.key, required this.views, required this.onChanged});

  @override
  State<ViewManagerDialog> createState() => _ViewManagerDialogState();
}

class _ViewManagerDialogState extends State<ViewManagerDialog> {
  late List<ViewPreset> _views;

  @override
  void initState() {
    super.initState();
    _views = List.from(widget.views);
  }

  Future<void> _rename(int index) async {
    final c = TextEditingController(text: _views[index].name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename View'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() => _views[index] = _views[index].copyWith(name: name));
      widget.onChanged(_views);
    }
  }

  Future<void> _delete(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete View?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _views.removeAt(index));
      widget.onChanged(_views);
    }
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final v = _views.removeAt(oldIndex);
      _views.insert(newIndex, v);
      widget.onChanged(_views);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Views'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ReorderableListView(
          onReorder: _reorder,
          children: [
            for (int i = 0; i < _views.length; i++)
              ListTile(
                key: ValueKey(_views[i].id),
                title: Text(_views[i].name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _rename(i)),
                    IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(i)),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}
