import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/template_snapshot.dart';

class SnapshotListDialog extends StatelessWidget {
  final List<TemplateSnapshot> snapshots;
  const SnapshotListDialog({super.key, required this.snapshots});

  @override
  Widget build(BuildContext context) {
    final snaps = [...snapshots]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return AlertDialog(
      title: const Text('Snapshots'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: snaps.length,
          itemBuilder: (ctx, i) {
            final s = snaps[i];
            return ListTile(
              title: Text(s.comment),
              subtitle: Text(
                DateFormat('yyyy-MM-dd HH:mm').format(s.timestamp),
              ),
              onTap: () => Navigator.pop(ctx, s),
            );
          },
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

Future<TemplateSnapshot?> showSnapshotListDialog(
  BuildContext context,
  List<TemplateSnapshot> snapshots,
) {
  return showDialog<TemplateSnapshot>(
    context: context,
    builder: (_) => SnapshotListDialog(snapshots: snapshots),
  );
}
