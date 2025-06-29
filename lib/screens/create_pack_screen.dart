import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_pack.dart';
import '../models/training_spot.dart';
import '../services/training_pack_storage_service.dart';
import '../services/training_spot_storage_service.dart';
import '../widgets/sync_status_widget.dart';

class CreatePackScreen extends StatefulWidget {
  const CreatePackScreen({super.key});

  @override
  State<CreatePackScreen> createState() => _CreatePackScreenState();
}

class _CreatePackScreenState extends State<CreatePackScreen> {
  final _nameController = TextEditingController();
  final _tagsController = TextEditingController();
  int _difficulty = 1;
  List<TrainingSpot> _spots = [];
  final Set<TrainingSpot> _selected = {};
  late TrainingSpotStorageService _storage;

  @override
  void initState() {
    super.initState();
    _storage = context.read<TrainingSpotStorageService>();
    _load();
  }

  Future<void> _load() async {
    final spots = await _storage.load();
    if (mounted) setState(() => _spots = spots);
  }

  void _toggle(TrainingSpot s) {
    setState(() {
      if (_selected.contains(s)) {
        _selected.remove(s);
      } else {
        _selected.add(s);
      }
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selected.isEmpty) return;
    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final pack = TrainingPack(
      name: name,
      description: '',
      tags: tags,
      hands: const [],
      spots: _selected.toList(),
      difficulty: _difficulty,
    );
    await context.read<TrainingPackStorageService>().addPack(pack);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый пакет'),
        actions: [SyncStatusIcon.of(context)],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _save,
        child: const Icon(Icons.check),
      ),
      body: _spots.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                        controller: _tagsController,
                        decoration: const InputDecoration(labelText: 'Теги'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _difficulty,
                        decoration:
                            const InputDecoration(labelText: 'Сложность'),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Beginner')),
                          DropdownMenuItem(value: 2, child: Text('Intermediate')),
                          DropdownMenuItem(value: 3, child: Text('Advanced')),
                        ],
                        onChanged: (v) => setState(() => _difficulty = v ?? 1),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _spots.length,
                    itemBuilder: (_, i) {
                      final s = _spots[i];
                      final pos =
                          s.positions.isNotEmpty ? s.positions[s.heroIndex] : '';
                      final stack =
                          s.stacks.isNotEmpty ? s.stacks[s.heroIndex] : 0;
                      return CheckboxListTile(
                        value: _selected.contains(s),
                        onChanged: (_) => _toggle(s),
                        title: Text('$pos ${stack}bb'),
                        subtitle:
                            s.tags.isNotEmpty ? Text(s.tags.join(', ')) : null,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
