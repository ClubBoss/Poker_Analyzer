import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';

import '../models/training_spot.dart';
import '../services/training_spot_storage_service.dart';

class TrainingSpotLibraryScreen extends StatefulWidget {
  const TrainingSpotLibraryScreen({super.key});

  @override
  State<TrainingSpotLibraryScreen> createState() => _TrainingSpotLibraryScreenState();
}

class _TrainingSpotLibraryScreenState extends State<TrainingSpotLibraryScreen> {
  late TrainingSpotStorageService _storage;
  List<TrainingSpot> _spots = [];
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _storage = TrainingSpotStorageService();
    _load();
  }

  Future<void> _load() async {
    final loaded = await _storage.load();
    if (mounted) setState(() => _spots = loaded);
  }

  Future<void> _save() async {
    await _storage.save(_spots);
  }

  void _toggle(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (tag == null || tag.isEmpty) return;
    setState(() {
      for (final i in _selected) {
        final spot = _spots[i];
        final tags = {...spot.tags, tag}..removeWhere((e) => e.isEmpty);
        _spots[i] = spot.copyWith(tags: tags.toList()..sort());
      }
      _selected.clear();
    });
    await _save();
  }

  Future<void> _removeTag() async {
    final tags = <String>{};
    for (final i in _selected) {
      tags.addAll(_spots[i].tags);
    }
    final tag = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Tag'),
        content: DropdownButton<String>(
          value: tags.isEmpty ? null : tags.first,
          items: [for (final t in tags) DropdownMenuItem(value: t, child: Text(t))],
          onChanged: (v) => Navigator.pop(context, v),
        ),
      ),
    );
    if (tag == null || tag.isEmpty) return;
    setState(() {
      for (final i in _selected) {
        final spot = _spots[i];
        final newTags = List<String>.from(spot.tags)..remove(tag);
        _spots[i] = spot.copyWith(tags: newTags);
      }
      _selected.clear();
    });
    await _save();
  }

  Future<void> _exportCsv() async {
    final rows = <List<String>>[];
    rows.add(['date', 'position', 'stackBB', 'tags']);
    for (final i in _selected) {
      final s = _spots[i];
      final pos = s.positions.isNotEmpty ? s.positions[s.heroIndex] : '';
      final stack = s.stacks.isNotEmpty ? s.stacks[s.heroIndex].toString() : '';
      final date = s.createdAt.toIso8601String();
      rows.add([date, pos, stack, s.tags.join(';')]);
    }
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/spots_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)]);
    setState(() => _selected.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Spots')),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: _spots.length,
            itemBuilder: (context, index) {
              final s = _spots[index];
              final selected = _selected.contains(index);
              final pos = s.positions.isNotEmpty ? s.positions[s.heroIndex] : '';
              final stack = s.stacks.isNotEmpty ? s.stacks[s.heroIndex] : 0;
              return ListTile(
                leading: Checkbox(
                  value: selected,
                  onChanged: (_) => _toggle(index),
                ),
                title: Text('$pos ${stack}bb'),
                subtitle: s.tags.isNotEmpty ? Text(s.tags.join(', ')) : null,
                onTap: () => _toggle(index),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _selected.isNotEmpty ? 56 : 0,
              child: _selected.isNotEmpty
                  ? Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
