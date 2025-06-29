import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pack_snapshot.dart';
import '../models/training_pack.dart';
import '../services/training_pack_storage_service.dart';

class SnapshotManagerScreen extends StatelessWidget {
  final TrainingPack pack;
  const SnapshotManagerScreen({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TrainingPackStorageService>();
    final snaps = service.snapshotsOf(pack).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      appBar: AppBar(title: const Text('Snapshots')),
      body: ListView.builder(
        itemCount: snaps.length,
        itemBuilder: (context, index) {
          final s = snaps[index];
          final title = s.comment.isEmpty
              ? DateFormat('dd.MM HH:mm').format(s.date)
              : s.comment;
          return Dismissible(
            key: ValueKey(s.id),
            background: Container(
              color: Colors.green,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.restore, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (dir) async {
              if (dir == DismissDirection.startToEnd) {
                final prefs = await SharedPreferences.getInstance();
                final last =
                    prefs.getString('pack_editor_last_snapshot_restored');
                if (last == s.id) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Already restored')),
                  );
                  return false;
                }
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Restore Snapshot?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Restore'),
                      ),
                    ],
                  ),
                );
                if (ok == true) Navigator.pop(context, s);
                return false;
              } else {
                final removed = s;
                await context
                    .read<TrainingPackStorageService>()
                    .deleteSnapshot(pack, s);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Snapshot deleted'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          context
                              .read<TrainingPackStorageService>()
                              .saveSnapshot(
                                  pack,
                                  removed.hands,
                                  removed.tags,
                                  removed.comment);
                        },
                      ),
                    ),
                  );
                }
                return false;
              }
            },
            child: ListTile(
              title: Text(title),
              subtitle:
                  Text(DateFormat('yyyy-MM-dd HH:mm').format(s.date)),
              trailing: Text('${s.hands.length}'),
              onTap: () async {
                final c = TextEditingController(text: s.comment);
                final result = await showDialog<String>(
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
                        onPressed: () =>
                            Navigator.pop(ctx, c.text.trim()),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
                if (result != null) {
                  await context
                      .read<TrainingPackStorageService>()
                      .renameSnapshot(pack, s, result);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
