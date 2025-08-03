import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_pack.dart';
import '../services/training_pack_storage_service.dart';
import 'snapshot_diff_screen.dart';
import '../utils/snackbar_util.dart';

class SnapshotManagerScreen extends StatefulWidget {
  final TrainingPack pack;
  const SnapshotManagerScreen({super.key, required this.pack});

  @override
  State<SnapshotManagerScreen> createState() => _SnapshotManagerScreenState();
}

class _SnapshotManagerScreenState extends State<SnapshotManagerScreen> {
  bool _changed = false;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TrainingPackStorageService>();
    final snaps = service.snapshotsOf(widget.pack).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Snapshots'),
          leading: BackButton(onPressed: () => Navigator.pop(context, _changed)),
        ),
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
                  SnackbarUtil.showMessage(context, 'Already restored');
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
                    .deleteSnapshot(widget.pack, s);
                if (context.mounted) {
                  SnackbarUtil.showMessage(context, 'Snapshot deleted', action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          context
                              .read<TrainingPackStorageService>()
                              .saveSnapshot(
                                  widget.pack,
                                  removed.hands,
                                  removed.tags,
                                  removed.comment);
                        },
                      ));
                }
                return false;
              }
            },
            child: ListTile(
              title: Text(title),
              subtitle:
                  Text(DateFormat('yyyy-MM-dd HH:mm').format(s.date)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.compare),
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SnapshotDiffScreen(
                            pack: widget.pack,
                            snapshot: s,
                          ),
                        ),
                      );
                      if (result == true) setState(() => _changed = true);
                    },
                  ),
                  Text('${s.hands.length}'),
                ],
              ),
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
                      .renameSnapshot(widget.pack, s, result);
                }
              },
            ),
          );
        },
      ),
      ),
    );
  }
}
