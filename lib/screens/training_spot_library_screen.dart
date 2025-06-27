import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';

import '../models/training_spot.dart';
import '../services/training_spot_storage_service.dart';
import '../services/cloud_sync_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common/training_spot_list.dart';

class TrainingSpotLibraryScreen extends StatefulWidget {
  const TrainingSpotLibraryScreen({super.key});

  @override
  State<TrainingSpotLibraryScreen> createState() =>
      _TrainingSpotLibraryScreenState();
}

class _TrainingSpotLibraryScreenState extends State<TrainingSpotLibraryScreen> {
  late TrainingSpotStorageService _storage;
  final _listKey = GlobalKey<TrainingSpotListState>();
  List<TrainingSpot> _spots = [];

  Set<TrainingSpot> get _selected =>
      _listKey.currentState?.selectedSpots ?? {};

  @override
  void initState() {
    super.initState();
    _storage = TrainingSpotStorageService(
      cloud: context.read<CloudSyncService>(),
    );
    _load();
  }

  Future<void> _load() async {
    final loaded = await _storage.load();
    if (mounted) setState(() => _spots = loaded);
  }

  Future<void> _save() async {
    await _storage.save(_spots);
  }

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Add Tag', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Tag',
              labelStyle: TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (tag == null || tag.isEmpty) return;
    setState(() {
      for (final s in _selected) {
        final i = _spots.indexOf(s);
        if (i != -1) {
          final set = {..._spots[i].tags, tag}..removeWhere((e) => e.isEmpty);
          _spots[i] = _spots[i].copyWith(tags: set.toList()..sort());
        }
      }
    });
    await _save();
    _listKey.currentState?.clearSelection();
  }

  Future<void> _removeTag() async {
    final allTags = <String>{};
    for (final s in _selected) {
      allTags.addAll(s.tags);
    }
    if (allTags.isEmpty) return;
    final tag = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Remove Tag', style: TextStyle(color: Colors.white)),
          children: [
            for (final t in allTags.toList()..sort())
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, t),
                child: Text(t, style: const TextStyle(color: Colors.white)),
              ),
          ],
        );
      },
    );
    if (tag == null) return;
    setState(() {
      for (final s in _selected) {
        final i = _spots.indexOf(s);
        if (i != -1) {
          final list = List<String>.from(_spots[i].tags)..remove(tag);
          _spots[i] = _spots[i].copyWith(tags: list);
        }
      }
    });
    await _save();
    _listKey.currentState?.clearSelection();
  }

  Future<void> _exportCsv() async {
    final spots = _selected.toList();
    if (spots.isEmpty) return;
    final rows = <List<dynamic>>[
      ['date', 'position', 'stackBB', 'tags']
    ];
    for (final s in spots) {
      rows.add([
        s.createdAt.toIso8601String(),
        s.positions.isNotEmpty ? s.positions[s.heroIndex] : '',
        s.stacks.isNotEmpty ? s.stacks[s.heroIndex] : '',
        s.tags.join(';'),
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file =
        File('${dir.path}/spots_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'spots.csv');
    _listKey.currentState?.clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selected.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Библиотека спотов')),
      bottomNavigationBar: hasSelection
          ? BottomAppBar(
              color: AppColors.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _addTag,
                      child: const Text('🏷 Add Tag'),
                    ),
                    ElevatedButton(
                      onPressed: _removeTag,
                      child: const Text('❌ Remove Tag'),
                    ),
                    ElevatedButton(
                      onPressed: _exportCsv,
                      child: const Text('📄 Export CSV'),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: TrainingSpotList(
        key: _listKey,
        spots: _spots,
        onRemove: (i) {
          setState(() => _spots.removeAt(i));
          _save();
        },
        onChanged: () => setState(() {}),
        onReorder: (o, n) {
          final item = _spots.removeAt(o);
          _spots.insert(n, item);
          _save();
        },
      ),
    );
  }
}
