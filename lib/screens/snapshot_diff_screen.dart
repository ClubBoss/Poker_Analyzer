import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pack_snapshot.dart';
import '../models/training_pack.dart';
import '../models/saved_hand.dart';
import '../services/training_pack_storage_service.dart';
import '../widgets/saved_hand_viewer_dialog.dart';
import '../utils/snackbar_util.dart';

class SnapshotDiffScreen extends StatefulWidget {
  final TrainingPack pack;
  final PackSnapshot snapshot;
  const SnapshotDiffScreen({super.key, required this.pack, required this.snapshot});

  @override
  State<SnapshotDiffScreen> createState() => _SnapshotDiffScreenState();
}

class _Mod {
  final SavedHand newHand;
  final SavedHand oldHand;
  final bool name;
  final bool tags;
  final bool actions;
  _Mod(this.newHand, this.oldHand, this.name, this.tags, this.actions);
}

class _SnapshotDiffScreenState extends State<SnapshotDiffScreen>
    with SingleTickerProviderStateMixin {
  late TrainingPack _pack;
  late List<SavedHand> _added;
  late List<SavedHand> _removed;
  late List<_Mod> _modified;
  final _selAdd = <SavedHand>{};
  final _selRem = <SavedHand>{};
  final _selMod = <_Mod>{};
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _pack = widget.pack;
    _compute();
    SharedPreferences.getInstance().then((p) =>
        p.setString('pack_editor_last_snapshot_diff', widget.snapshot.id));
  }

  void _compute() {
    final pMap = {
      for (final h in _pack.hands) h.savedAt.millisecondsSinceEpoch: h
    };
    final sMap = {
      for (final h in widget.snapshot.hands) h.savedAt.millisecondsSinceEpoch: h
    };
    _added = [for (final e in sMap.entries) if (!pMap.containsKey(e.key)) e.value];
    _removed = [for (final e in pMap.entries) if (!sMap.containsKey(e.key)) e.value];
    _modified = [];
    for (final key in sMap.keys) {
      if (pMap.containsKey(key)) {
        final a = pMap[key]!;
        final b = sMap[key]!;
        final n = a.name != b.name;
        final t = !Set.from(a.tags).containsAll(b.tags) ||
            !Set.from(b.tags).containsAll(a.tags);
        final ac = a.actions.length != b.actions.length;
        if (n || t || ac) _modified.add(_Mod(b, a, n, t, ac));
      }
    }
  }

  String _sub(_Mod m) {
    final parts = <String>[];
    if (m.name) parts.add('name');
    if (m.tags) parts.add('tags');
    if (m.actions) parts.add('actions');
    return parts.join(', ');
  }

  Future<void> _previewHand(SavedHand hand) async {
    await showSavedHandViewerDialog(context, hand);
  }

  Future<void> _apply() async {
    final add = _selAdd.toList();
    final rem = _selRem.toList();
    final mod = _selMod.toList();
    if (add.isEmpty && rem.isEmpty && mod.isEmpty) return;
    final service = context.read<TrainingPackStorageService>();
    service.applyDiff(
      _pack,
      added: add,
      removed: rem,
      modified: [for (final m in mod) m.newHand],
    );
    final undoAdd = rem;
    final undoRem = add;
    final undoMod = [for (final m in mod) m.oldHand];
    setState(() {
      _pack = service.packs.firstWhere((e) => e.id == _pack.id, orElse: () => _pack);
      _selAdd.clear();
      _selRem.clear();
      _selMod.clear();
      _changed = true;
      _compute();
    });
    SnackbarUtil.showMessage(context, 'Restored ${add.length + rem.length + mod.length} changes', action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            service.applyDiff(
              _pack,
              added: undoAdd,
              removed: undoRem,
              modified: undoMod,
            );
            setState(() {
              _pack = service.packs
                  .firstWhere((e) => e.id == _pack.id, orElse: () => _pack);
              _compute();
            });
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text('+${_added.length}  -${_removed.length}  ±${_modified.length}'),
            bottom: const TabBar(tabs: [
              Tab(text: 'Added'),
              Tab(text: 'Removed'),
              Tab(text: 'Modified'),
            ]),
            leading: BackButton(
              onPressed: () => Navigator.pop(context, _changed),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _apply,
            child: const Icon(Icons.restore),
          ),
          body: TabBarView(
            children: [
              ListView(
                children: [
                  for (final h in _added)
                    CheckboxListTile(
                      value: _selAdd.contains(h),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _selAdd.add(h);
                        } else {
                          _selAdd.remove(h);
                        }
                      }),
                      onLongPress: () => _previewHand(h),
                      title: Text(h.name.isEmpty ? 'Untitled' : h.name),
                    ),
                ],
              ),
              ListView(
                children: [
                  for (final h in _removed)
                    CheckboxListTile(
                      value: _selRem.contains(h),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _selRem.add(h);
                        } else {
                          _selRem.remove(h);
                        }
                      }),
                      onLongPress: () => _previewHand(h),
                      title: Text(h.name.isEmpty ? 'Untitled' : h.name),
                    ),
                ],
              ),
              ListView(
                children: [
                  for (final m in _modified)
                    CheckboxListTile(
                      value: _selMod.contains(m),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _selMod.add(m);
                        } else {
                          _selMod.remove(m);
                        }
                      }),
                      onLongPress: () => _previewHand(m.newHand),
                      title: Text(m.newHand.name.isEmpty ? 'Untitled' : m.newHand.name),
                      subtitle: Text(_sub(m)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
