import 'package:flutter/material.dart';
import '../models/view_preset.dart';

class ViewManagerDialog extends StatefulWidget {
  final List<ViewPreset> views;
  final ValueChanged<List<ViewPreset>> onChanged;
  const ViewManagerDialog({
    super.key,
    required this.views,
    required this.onChanged,
  });

  @override
  State<ViewManagerDialog> createState() => _ViewManagerDialogState();
}

class _ViewManagerDialogState extends State<ViewManagerDialog> {
  late List<ViewPreset> _views;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _views = List.from(widget.views);
  }

  Future<void> _rename(ViewPreset view) async {
    final index = _views.indexOf(view);
    if (index == -1) return;
    final c = TextEditingController(text: view.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename View'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() => _views[index] = _views[index].copyWith(name: name));
      widget.onChanged(_views);
    }
  }

  Future<void> _delete(ViewPreset view) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete View?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final index = _views.indexOf(view);
      if (index != -1) {
        setState(() => _views.removeAt(index));
        widget.onChanged(_views);
      }
    }
  }

  void _reorder(int oldIndex, int newIndex, List<ViewPreset> filtered) {
    final moved = filtered[oldIndex];
    final oldMainIndex = _views.indexOf(moved);
    var newMainIndex = newIndex >= filtered.length
        ? _views.length
        : _views.indexOf(filtered[newIndex]);
    if (newMainIndex > oldMainIndex) newMainIndex--;
    setState(() {
      final item = _views.removeAt(oldMainIndex);
      _views.insert(newMainIndex, item);
    });
    widget.onChanged(_views);
  }

  @override
  Widget build(BuildContext context) {
    final query = _filter.toLowerCase();
    final filtered = [
      for (final v in _views)
        if (v.name.toLowerCase().contains(query)) v,
    ];
    return AlertDialog(
      title: const Text('Views'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(hintText: 'Search'),
              onChanged: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ReorderableListView(
                onReorder: (o, n) => _reorder(o, n, filtered),
                children: [
                  for (int i = 0; i < filtered.length; i++)
                    ListTile(
                      key: ValueKey(filtered[i].id),
                      leading: ReorderableDragStartListener(
                        index: i,
                        child: const Icon(Icons.drag_handle),
                      ),
                      title: Text(filtered[i].name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _rename(filtered[i]),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _delete(filtered[i]),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
