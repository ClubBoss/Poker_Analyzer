import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/pack_editor_snapshot.dart';

class SnapshotManagerDialog extends StatefulWidget {
  final List<PackEditorSnapshot> snapshots;
  const SnapshotManagerDialog({super.key, required this.snapshots});

  @override
  State<SnapshotManagerDialog> createState() => _SnapshotManagerDialogState();
}

class _SnapshotManagerDialogState extends State<SnapshotManagerDialog> {
  late List<PackEditorSnapshot> _snaps;

  @override
  void initState() {
    super.initState();
    _snaps = [
      for (final s in widget.snapshots)
        if (!s.isAuto) s,
    ];
  }

  Future<void> _rename(int index) async {
    final c = TextEditingController(text: _snaps[index].name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Snapshot'),
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
      setState(() => _snaps[index] = _snaps[index].copyWith(name: name));
    }
  }

  void _delete(int index) => setState(() => _snaps.removeAt(index));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Snapshots'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: _snaps.length,
          itemBuilder: (ctx, i) {
            final s = _snaps[i];
            return ListTile(
              title: Text(s.name),
              subtitle: Text(
                DateFormat('yyyy-MM-dd HH:mm').format(s.timestamp),
              ),
              onTap: () => _rename(i),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.restore),
                    onPressed: () => Navigator.pop(context, s),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _delete(i),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _snaps),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
