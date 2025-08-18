import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/v2/training_pack_preset.dart';
import '../models/game_type.dart';
import '../services/pack_generator_service.dart';
import '../repositories/training_pack_preset_repository.dart';
import '../models/training_pack_template_model.dart';
import '../services/training_pack_template_storage_service.dart';

class TrainingPackPresetListScreen extends StatefulWidget {
  const TrainingPackPresetListScreen({super.key});

  @override
  State<TrainingPackPresetListScreen> createState() =>
      _TrainingPackPresetListScreenState();
}

class _TrainingPackPresetListScreenState
    extends State<TrainingPackPresetListScreen> {
  final List<TrainingPackPreset> _presets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    TrainingPackPresetRepository.getAll().then((list) {
      if (!mounted) return;
      setState(() {
        _presets.addAll(list);
        _loading = false;
      });
    });
  }

  Future<void> _generate(TrainingPackPreset preset) async {
    final tpl = await PackGeneratorService.generatePackFromPreset(preset);
    final service = context.read<TrainingPackTemplateStorageService>();
    final model = TrainingPackTemplateModel(
      id: tpl.id,
      name: tpl.name,
      description: tpl.description,
      category: preset.category,
      difficulty: 1,
      rating: 0,
      filters: const {},
      isTournament: preset.gameType == GameType.tournament,
      createdAt: DateTime.now(),
      lastGeneratedAt: tpl.lastGeneratedAt,
    );
    final exists = service.templates.any((e) => e.id == model.id);
    if (exists) {
      await service.update(model);
    } else {
      await service.add(model);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(exists ? 'Пак обновлён' : 'Пак создан')),
    );
  }

  Future<void> _generateAll() async {
    final list = List<TrainingPackPreset>.from(_presets);
    if (list.isEmpty) return;
    var cancel = false;
    var done = 0;
    final total = list.length;
    final service = context.read<TrainingPackTemplateStorageService>();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setDialog) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                for (final p in list) {
                  if (cancel) break;
                  final tpl = await PackGeneratorService.generatePackFromPreset(
                    p,
                  );
                  final model = TrainingPackTemplateModel(
                    id: tpl.id,
                    name: tpl.name,
                    description: tpl.description,
                    category: p.category,
                    difficulty: 1,
                    rating: 0,
                    filters: const {},
                    isTournament: p.gameType == GameType.tournament,
                    createdAt: DateTime.now(),
                    lastGeneratedAt: tpl.lastGeneratedAt,
                  );
                  if (service.templates.any((e) => e.id == model.id)) {
                    await service.update(model);
                  } else {
                    await service.add(model);
                  }
                  done++;
                  if (mounted) setDialog(() {});
                }
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: done / total),
                  const SizedBox(height: 12),
                  Text('Generated $done / $total', textAlign: TextAlign.center),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => cancel = true,
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Generated $done of $total packs')));
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    bool ok = true;
    final list = <TrainingPackPreset>[];
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is List) {
        for (final e in decoded) {
          if (e is Map) {
            try {
              list.add(
                TrainingPackPreset.fromJson(Map<String, dynamic>.from(e)),
              );
            } catch (_) {}
          }
        }
      } else {
        ok = false;
      }
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (ok) setState(() => _presets.addAll(list));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Импортировано ${list.length}' : '⚠️ Ошибка импорта',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presets'),
        actions: [
          IconButton(
            onPressed: _generateAll,
            icon: const Icon(Icons.playlist_play),
          ),
          IconButton(onPressed: _import, icon: const Icon(Icons.upload_file)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _presets.length,
              itemBuilder: (context, index) {
                final p = _presets[index];
                final templates = context
                    .watch<TrainingPackTemplateStorageService>()
                    .templates;
                final exists = templates.any((t) => t.id == p.id);
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text(p.description),
                  trailing: IconButton(
                    icon: Icon(
                      exists ? Icons.done : Icons.play_arrow,
                      color: exists ? Colors.green : null,
                    ),
                    onPressed: () async {
                      if (!exists) {
                        await _generate(p);
                      } else {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Regenerate?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) await _generate(p);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
