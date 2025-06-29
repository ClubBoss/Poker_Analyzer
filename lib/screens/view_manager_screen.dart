import 'package:flutter/material.dart';
import '../models/view_preset.dart';

class ViewManagerScreen extends StatefulWidget {
  final List<ViewPreset> views;
  final ValueChanged<List<ViewPreset>> onChanged;
  const ViewManagerScreen({super.key, required this.views, required this.onChanged});

  @override
  State<ViewManagerScreen> createState() => _ViewManagerScreenState();
}

class _ViewManagerScreenState extends State<ViewManagerScreen> {
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

  void _delete(int index) {
    setState(() => _views.removeAt(index));
    widget.onChanged(_views);
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final v = _views.removeAt(oldIndex);
      _views.insert(newIndex, v);
    });
    widget.onChanged(_views);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Views'),
          leading: BackButton(onPressed: () => Navigator.pop(context)),
        ),
        body: ReorderableListView(
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
    );
  }
}
