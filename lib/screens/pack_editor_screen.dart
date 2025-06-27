import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/saved_hand.dart';
import '../models/training_pack.dart';
import '../services/training_pack_storage_service.dart';

class PackEditorScreen extends StatefulWidget {
  final TrainingPack pack;
  const PackEditorScreen({super.key, required this.pack});

  @override
  State<PackEditorScreen> createState() => _PackEditorScreenState();
}

class _PackEditorScreenState extends State<PackEditorScreen> {
  late List<SavedHand> _hands;
  bool _modified = false;
  SavedHand? _removed;
  int _removedIndex = -1;

  @override
  void initState() {
    super.initState();
    _hands = List.from(widget.pack.hands);
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result;
  }

  List<SavedHand> _parseCsv(String content) {
    final lines = content.trim().split(RegExp(r'\r?\n'));
    if (lines.length < 2) return [];
    final headers = _parseCsvLine(lines.first);
    final hands = <SavedHand>[];
    for (int i = 1; i < lines.length; i++) {
      final values = _parseCsvLine(lines[i]);
      if (values.every((v) => v.trim().isEmpty)) continue;
      final map = <String, String>{};
      for (int j = 0; j < headers.length && j < values.length; j++) {
        map[headers[j]] = values[j];
      }
      hands.add(
        SavedHand(
          name: map['name'] ?? '',
          heroIndex: 0,
          heroPosition: map['heroPosition'] ?? 'BTN',
          numberOfPlayers: 2,
          playerCards: const [],
          boardCards: const [],
          boardStreet: 0,
          actions: const [],
          stackSizes: const {},
          playerPositions: const {},
          comment: map['comment'],
          tags: (map['tags'] ?? '')
              .split('|')
              .where((e) => e.isNotEmpty)
              .toList(),
          tournamentId: map['tournamentId'],
          buyIn: int.tryParse(map['buyIn'] ?? ''),
          totalPrizePool: int.tryParse(map['totalPrizePool'] ?? ''),
          numberOfEntrants: int.tryParse(map['numberOfEntrants'] ?? ''),
          gameType: map['gameType'],
          savedAt: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
          date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
        ),
      );
    }
    return hands;
  }

  Future<void> _addHands() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['json', 'hand.json', 'csv'],
    );
    if (result == null || result.files.isEmpty) return;
    final added = <SavedHand>[];
    for (final f in result.files) {
      final path = f.path;
      if (path == null) continue;
      try {
        final content = await File(path).readAsString();
        if (path.endsWith('.csv')) {
          added.addAll(_parseCsv(content));
        } else {
          final data = jsonDecode(content);
          if (data is Map<String, dynamic>) {
            added.add(SavedHand.fromJson(data));
          } else if (data is List) {
            for (final e in data) {
              if (e is Map<String, dynamic>) {
                added.add(SavedHand.fromJson(e));
              }
            }
          }
        }
      } catch (_) {}
    }
    if (added.isEmpty) return;
    setState(() {
      for (final h in added) {
        if (_hands.every((e) => e.savedAt != h.savedAt)) {
          _hands.add(h);
          _modified = true;
        }
      }
    });
  }

  void _remove(int index) {
    if (index < 0 || index >= _hands.length) return;
    final hand = _hands.removeAt(index);
    setState(() {
      _removed = hand;
      _removedIndex = index;
      _modified = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Раздача удалена'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            if (_removed != null) {
              setState(() {
                _hands.insert(_removedIndex.clamp(0, _hands.length), _removed!);
                _removed = null;
                _modified = true;
              });
            }
          },
        ),
      ),
    );
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _hands.removeAt(oldIndex);
      _hands.insert(newIndex, item);
      _modified = true;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_modified) return true;
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сохранить изменения?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Да'),
          ),
        ],
      ),
    );
    if (save == true) {
      await _save();
      return true;
    }
    return save ?? false;
  }

  Future<void> _save() async {
    final updated = TrainingPack(
      name: widget.pack.name,
      description: widget.pack.description,
      category: widget.pack.category,
      gameType: widget.pack.gameType,
      colorTag: widget.pack.colorTag,
      isBuiltIn: widget.pack.isBuiltIn,
      tags: widget.pack.tags,
      hands: _hands,
      spots: widget.pack.spots,
      difficulty: widget.pack.difficulty,
    );
    await context
        .read<TrainingPackStorageService>()
        .updatePack(widget.pack, updated);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.pack.name),
          actions: [
            IconButton(
              onPressed: _hands.isEmpty ? null : _save,
              icon: const Icon(Icons.check),
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ReorderableListView.builder(
                onReorder: _reorder,
                itemCount: _hands.length,
                itemBuilder: (context, index) {
                  final hand = _hands[index];
                  final title = hand.name.isEmpty ? 'Без названия' : hand.name;
                  return Dismissible(
                    key: ValueKey(hand.savedAt.toIso8601String()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => _remove(index),
                    child: ListTile(
                      leading: const Icon(Icons.drag_handle),
                      title: Text(title),
                      subtitle:
                          hand.tags.isEmpty ? null : Text(hand.tags.join(', ')),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _addHands,
                child: const Text('Добавить раздачи'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
