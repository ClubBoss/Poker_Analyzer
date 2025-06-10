import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';

import '../models/training_pack.dart';
import 'training_pack_screen.dart';
import '../theme/constants.dart';
import 'create_pack_screen.dart';
import 'package:provider/provider.dart';
import '../services/training_pack_storage_service.dart';
import '../services/daily_hand_service.dart';

class TrainingPacksScreen extends StatefulWidget {
  const TrainingPacksScreen({super.key});

  @override
  State<TrainingPacksScreen> createState() => _TrainingPacksScreenState();
}

class _TrainingPacksScreenState extends State<TrainingPacksScreen> {
  String _selectedCategory = 'All';
  String _statusFilter = 'Все';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final packsService = context.read<TrainingPackStorageService>();
      await packsService.load();
      final daily = context.read<DailyHandService>();
      await daily.load();
      await daily.ensureTodayHand(packs: packsService.packs);
    });
  }


  Future<void> _exportAllPacks() async {
    final service = context.read<TrainingPackStorageService>();
    final packs = service.packs;
    if (packs.isEmpty) return;
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'packs_\$timestamp.json';
    final file = File('${dir.path}/$fileName');
    final data = [for (final p in packs) p.toJson()];
    await file.writeAsString(jsonEncode(data));
    await OpenFile.open(file.path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Экспорт завершён: \$fileName')),
      );
    }
  }

  Future<void> _importPacks() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final file = File(path);
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is List) {
        final service = context.read<TrainingPackStorageService>();
        final List<TrainingPack> packs = [
          for (final item in data)
            if (item is Map)
              TrainingPack.fromJson(Map<String, dynamic>.from(item))
        ];
        if (packs.isNotEmpty) {
          for (final p in packs) {
            await service.addPack(p);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Импорт завершён: ${packs.length} пакетов')),
            );
          }
        }
      }
    } catch (_) {
      // ignore errors silently
    }
  }

  Widget _buildProgress(TrainingPack pack) {
    if (pack.history.isEmpty) {
      return const Text('Не начат',
          style: TextStyle(color: Colors.white54));
    }
    final last = pack.history.last;
    final progress =
        last.total > 0 ? last.correct / last.total : 0.0;
    final percent = (progress * 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 4),
        Text('$percent% (${last.correct}/${last.total})',
            style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildDailyHandCard() {
    final service = context.watch<DailyHandService>();
    final played = service.result != null;
    return Card(
      color: const Color(0xFF2A2B2E),
      child: ListTile(
        title: const Text('Задача дня',
            style: TextStyle(color: Colors.white)),
        subtitle: const Text('Каждый день — новая раздача',
            style: TextStyle(color: Colors.white70)),
        trailing: played
            ? Icon(
                service.result! ? Icons.check_circle : Icons.cancel,
                color: service.result! ? Colors.green : Colors.red,
              )
            : null,
        onTap: () async {
          final hand = service.hand;
          if (hand == null) return;
          final pack = TrainingPack(
            name: 'Задача дня',
            description: '',
            category: 'Daily',
            hands: [hand],
          );
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TrainingPackScreen(
                pack: pack,
                hands: [hand],
                persistResults: false,
                onComplete: (correct) async {
                  await context.read<DailyHandService>().setResult(correct);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TrainingPackStorageService>();
    var packs = service.packs;
    final categories = ['All', ...{for (final p in packs) p.category}];
    if (_selectedCategory != 'All') {
      packs = packs.where((p) => p.category == _selectedCategory).toList();
    }
    List<TrainingPack> visible = packs;
    if (_statusFilter == 'Начатые') {
      visible = visible.where((p) => p.history.isNotEmpty).toList();
    } else if (_statusFilter == 'Завершённые') {
      visible = visible
          .where((p) =>
              p.history.isNotEmpty &&
              p.history.last.total > 0 &&
              p.history.last.correct == p.history.last.total)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренировочные пакеты'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Экспортировать все',
            onPressed: _exportAllPacks,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Импортировать',
            onPressed: _importPacks,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Очистить всё',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Удалить все тренировочные пакеты?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Удалить'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final service = context.read<TrainingPackStorageService>();
                await service.clear();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Все пакеты удалены')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.padding16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    dropdownColor: const Color(0xFF2A2B2E),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                    items: [
                      for (final c in categories)
                        DropdownMenuItem(value: c, child: Text(c))
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _statusFilter,
                  dropdownColor: const Color(0xFF2A2B2E),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _statusFilter = value);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'Все', child: Text('Все')),
                    DropdownMenuItem(value: 'Начатые', child: Text('Начатые')),
                    DropdownMenuItem(value: 'Завершённые', child: Text('Завершённые')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.padding16),
              itemCount: visible.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildDailyHandCard();
                }
                final pack = visible[index - 1];
                return Card(
                  color: const Color(0xFF2A2B2E),
                  child: ListTile(
                    title: Text(pack.name,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(pack.description,
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A3B3E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(pack.category,
                              style: const TextStyle(color: Colors.white70)),
                        ),
                        const SizedBox(height: 8),
                        _buildProgress(pack),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrainingPackScreen(pack: pack),
                        ),
                      );
                      await context.read<TrainingPackStorageService>().load();
                    },
                    onLongPress: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Удалить пакет «${pack.name}»?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Отмена'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Удалить'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final service = context.read<TrainingPackStorageService>();
                        await service.removePack(pack);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final pack = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePackScreen()),
          );
          if (pack is TrainingPack) {
            await context.read<TrainingPackStorageService>().addPack(pack);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
