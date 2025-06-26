import 'package:flutter/material.dart';

import '../models/training_pack.dart';
import '../models/training_spot.dart';
import '../services/training_spot_file_service.dart';
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
  String _gameType = 'Cash Game';
  final TrainingSpotFileService _spotFileService = const TrainingSpotFileService();
  List<TrainingSpot> _spots = [];
  final GlobalKey<TrainingSpotListState> _spotListKey =
      GlobalKey<TrainingSpotListState>();

  @override
  void initState() {
    super.initState();
    final pack = widget.initialPack;
    if (pack != null) {
      _nameController.text = pack.name;
      _descriptionController.text = pack.description;
      _categoryController.text = pack.category;
      _gameType = pack.gameType;
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
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _categoryController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Категория',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _gameType,
              decoration: const InputDecoration(
                labelText: 'Тип игры',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
              ),
              dropdownColor: const Color(0xFF3A3B3E),
              items: const [
                DropdownMenuItem(value: 'Tournament', child: Text('Tournament')),
                DropdownMenuItem(value: 'Cash Game', child: Text('Cash Game')),
              ],
              onChanged: (v) => setState(() => _gameType = v ?? 'Cash Game'),
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
