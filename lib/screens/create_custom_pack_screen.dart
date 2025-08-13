import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/color_utils.dart';
import '../models/game_type.dart';
import '../models/saved_hand.dart';
import '../models/training_pack.dart';
import '../services/training_pack_storage_service.dart';
import '../widgets/color_picker_dialog.dart';
import 'my_training_packs_screen.dart';
import '../widgets/sync_status_widget.dart';

class CreateCustomPackScreen extends StatefulWidget {
  const CreateCustomPackScreen({super.key});

  @override
  State<CreateCustomPackScreen> createState() => _CreateCustomPackScreenState();
}

class _CreateCustomPackScreenState extends State<CreateCustomPackScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();
  GameType _gameType = GameType.cash;
  Color _color = Colors.blue;
  final List<SavedHand> _hands = [];
  SharedPreferences? _prefs;
  static const _lastCategoryKey = 'pack_last_category';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cat = prefs.getString(_lastCategoryKey);
    if (cat != null && cat.isNotEmpty) {
      _categoryController.text = cat;
    }
    _prefs = prefs;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
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
        }
      }
    });
  }

  void _remove(int index) {
    if (index < 0 || index >= _hands.length) return;
    setState(() => _hands.removeAt(index));
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _hands.removeAt(oldIndex);
      _hands.insert(newIndex, item);
    });
  }

  Future<void> _pickColor() async {
    final c = await showColorPickerDialog(context, initialColor: _color);
    if (c != null) setState(() => _color = c);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _hands.isEmpty) return;
    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final pack = TrainingPack(
      name: name,
      description: _descController.text.trim(),
      category: _categoryController.text.trim().isEmpty
          ? 'Uncategorized'
          : _categoryController.text.trim(),
      gameType: _gameType,
      colorTag: colorToHex(_color),
      tags: tags,
      hands: List.from(_hands),
      spots: const [],
      difficulty: 1,
      history: const [],
    );
    await context.read<TrainingPackStorageService>().addCustomPack(pack);
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final cat = _categoryController.text.trim();
    if (cat.isNotEmpty) await prefs.setString(_lastCategoryKey, cat);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MyTrainingPacksScreen()),
      (r) => false,
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Пак сохранён')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый кастомный пак'),
        actions: [
          SyncStatusIcon.of(context),
          IconButton(
            onPressed: _hands.isEmpty ? null : _save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Название'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Описание'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Категория'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GameType>(
                  value: _gameType,
                  decoration: const InputDecoration(labelText: 'Тип игры'),
                  items: const [
                    DropdownMenuItem(
                        value: GameType.tournament, child: Text('Tournament')),
                    DropdownMenuItem(
                        value: GameType.cash, child: Text('Cash Game')),
                  ],
                  onChanged: (v) =>
                      setState(() => _gameType = v ?? GameType.cash),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: CircleAvatar(backgroundColor: _color),
                  title: const Text('Цвет'),
                  trailing: IconButton(
                      icon: const Icon(Icons.color_lens),
                      onPressed: _pickColor),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tagsController,
                  decoration:
                      const InputDecoration(labelText: 'Теги через запятую'),
                ),
              ],
            ),
          ),
          const Divider(),
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
    );
  }
}
