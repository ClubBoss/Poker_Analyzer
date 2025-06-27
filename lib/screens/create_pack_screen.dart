import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_pack.dart';
import '../models/training_spot.dart';
import '../models/game_type.dart';
import '../services/training_spot_file_service.dart';
import '../services/category_usage_service.dart';
import '../widgets/common/training_spot_list.dart';

class CreatePackScreen extends StatefulWidget {
  final TrainingPack? initialPack;

  const CreatePackScreen({super.key, this.initialPack});

  @override
  State<CreatePackScreen> createState() => _CreatePackScreenState();
}

class _CreatePackScreenState extends State<CreatePackScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  GameType _gameType = GameType.cash;
  final TrainingSpotFileService _spotFileService = const TrainingSpotFileService();
  List<TrainingSpot> _spots = [];
  final Set<String> _tags = {};
  final List<String> _suggested = [];
  final GlobalKey<TrainingSpotListState> _spotListKey =
      GlobalKey<TrainingSpotListState>();

  void _suggestTags() {
    const map = {
      'push': 'Push',
      'bubble': 'Bubble',
      'bb defense': 'BB defense',
    };
    final text = (_nameController.text + ' ' + _descriptionController.text).toLowerCase();
    final found = <String>[];
    for (final entry in map.entries) {
      if (text.contains(entry.key) && !found.contains(entry.value)) {
        found.add(entry.value);
        if (found.length >= 3) break;
      }
    }
    setState(() {
      _suggested
        ..clear()
        ..addAll(found);
      _tags.addAll(found);
    });
  }

  @override
  void initState() {
    super.initState();
    final pack = widget.initialPack;
    if (pack != null) {
      _nameController.text = pack.name;
      _descriptionController.text = pack.description;
      _categoryController.text = pack.category;
      _gameType = pack.gameType;
      _tags.addAll(pack.tags);
      _suggested.addAll(pack.tags);
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final category = _categoryController.text.trim();
    final pack = TrainingPack(
      name: name,
      description: _descriptionController.text.trim(),
      category: category.isEmpty ? 'Uncategorized' : category,
      gameType: _gameType,
      tags: _tags.toList(),
      hands: widget.initialPack?.hands ?? const [],
    );
    Navigator.pop(context, pack);
  }

  Future<void> _importSpotsCsv() async {
    final spots = await _spotFileService.importSpotsCsv(context);
    if (spots.isNotEmpty) {
      setState(() => _spots = spots);
    }
  }

  Future<void> _exportSpotsMarkdown() async {
    await _spotFileService.exportSpotsMarkdown(context, _spots);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryUsageService>().categories;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialPack == null ? 'Новый пакет' : 'Редактирование'),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Название',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
              ),
              onEditingComplete: _suggestTags,
              onSubmitted: (_) => _suggestTags(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Описание',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
              ),
              onEditingComplete: _suggestTags,
              onSubmitted: (_) => _suggestTags(),
            ),
            const SizedBox(height: 16),
            if (categories.isNotEmpty)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Популярные категории',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                ),
                dropdownColor: const Color(0xFF3A3B3E),
                items: [
                  for (final c in categories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _categoryController.text = v);
                },
              ),
            if (categories.isNotEmpty) const SizedBox(height: 16),
            TextField(
              controller: _categoryController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Категория',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
              ),
            ),
            if (_suggested.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 4,
                children: [
                  for (final tag in _suggested)
                    FilterChip(
                      label: Text(tag),
                      selected: _tags.contains(tag),
                      onSelected: (v) => setState(() {
                        if (v) {
                          _tags.add(tag);
                        } else {
                          _tags.remove(tag);
                        }
                      }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<GameType>(
              value: _gameType,
              decoration: const InputDecoration(
                labelText: 'Тип игры',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
              ),
              dropdownColor: const Color(0xFF3A3B3E),
              items: const [
                DropdownMenuItem(value: GameType.tournament, child: Text('Tournament')),
                DropdownMenuItem(value: GameType.cash, child: Text('Cash Game')),
              ],
              onChanged: (v) => setState(() => _gameType = v ?? GameType.cash),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Сохранить'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _importSpotsCsv,
              child: const Text('Импорт спотов из CSV'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: () =>
                    _spotListKey.currentState?.clearFilters(),
                child: const Text('Очистить фильтры'),
              ),
            ),
            const SizedBox(height: 12),
            TrainingSpotList(
              key: _spotListKey,
              spots: _spots,
              onRemove: (index) {
                setState(() {
                  _spots.removeAt(index);
                });
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  final item = _spots.removeAt(oldIndex);
                  _spots.insert(newIndex, item);
                });
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _spots.isEmpty ? null : _exportSpotsMarkdown,
              child: const Text('Экспортировать в Markdown'),
            ),
          ],
        ),
      ),
    );
  }
}
