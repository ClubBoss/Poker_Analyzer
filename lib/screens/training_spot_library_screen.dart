import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';

import '../models/training_spot.dart';
import '../services/cloud_sync_service.dart';
import '../services/training_spot_storage_service.dart';

class TrainingSpotLibraryScreen extends StatefulWidget {
  const TrainingSpotLibraryScreen({super.key});

  @override
  State<TrainingSpotLibraryScreen> createState() => _TrainingSpotLibraryScreenState();
}

class _TrainingSpotLibraryScreenState extends State<TrainingSpotLibraryScreen> {
  late TrainingSpotStorageService _storage;
  List<TrainingSpot> _spots = [];
  final Set<TrainingSpot> _selected = {};

  bool get _selectionMode => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _storage = TrainingSpotStorageService(cloud: context.read<CloudSyncService>());
    _load();
  }

  Future<void> _load() async {
    final loaded = await _storage.load();
    if (mounted) setState(() => _spots = loaded);
  }

  void _toggleSelect(TrainingSpot s) {
    setState(() {
      if (_selected.contains(s)) {
        _selected.remove(s);
      } else {
        _selected.add(s);
      }
    });
  }

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить тег'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('OK')),
        ],
      ),
    );
    if (tag == null || tag.isEmpty) return;
    for (final s in _selected) {
      final idx = _spots.indexOf(s);
      if (idx == -1) continue;
      final set = {...s.tags, tag};
      _spots[idx] = s.copyWith(tags: set.toList()..sort());
    }
    await _storage.save(_spots);
    await _load();
    setState(() => _selected.clear());
  }

  Future<void> _removeTag() async {
    final tags = <String>{};
    for (final s in _selected) {
      tags.addAll(s.tags);
    }
    if (tags.isEmpty) return;
    String? selected;
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Удалить тег'),
          content: Autocomplete<String>(
            optionsBuilder: (v) {
              final query = v.text.toLowerCase();
              return tags.where((t) => t.toLowerCase().contains(query));
            },
            onSelected: (v) => selected = v,
            fieldViewBuilder: (c, t, f, s) {
              controller.value = t.value;
              return TextField(controller: t, focusNode: f);
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, (selected ?? controller.text).trim()),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (tag == null || tag.isEmpty) return;
    for (final s in _selected) {
      final idx = _spots.indexOf(s);
      if (idx == -1) continue;
      final list = List<String>.from(s.tags)..remove(tag);
      _spots[idx] = s.copyWith(tags: list);
    }
    await _storage.save(_spots);
    await _load();
    setState(() => _selected.clear());
  }

  Future<void> _exportCsv() async {
    final rows = [
      ['date', 'position', 'stackBB', 'tags'],
      for (final s in _selected)
        [
          s.createdAt.toIso8601String(),
          s.positions[s.heroIndex],
          s.stacks[s.heroIndex],
          s.tags.join(' ')
        ]
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/training_spots.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'training_spots.csv');
    setState(() => _selected.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои споты'),
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _selected.clear()),
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: _spots.length,
        itemBuilder: (context, index) {
          final s = _spots[index];
          final selected = _selected.contains(s);
          return ListTile(
            selected: selected,
            leading: Checkbox(
              value: selected,
              onChanged: (_) => _toggleSelect(s),
            ),
            title: Text(s.positions[s.heroIndex]),
            subtitle: Text(s.tags.join(', ')),
            onLongPress: () => _toggleSelect(s),
            onTap: _selectionMode ? () => _toggleSelect(s) : null,
          );
        },
      ),
      bottomNavigationBar: _selectionMode
          ? BottomAppBar(
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
    );
  }
}
