import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/v2/training_pack_preset.dart';
import "../models/game_type.dart";
import '../services/pack_generator_service.dart';
import '../repositories/training_pack_preset_repository.dart';
import '../models/training_pack_template_model.dart';
import '../services/training_pack_template_storage_service.dart';

class TrainingPackPresetListScreen extends StatefulWidget {
  const TrainingPackPresetListScreen({super.key});

  @override
  State<TrainingPackPresetListScreen> createState() => _TrainingPackPresetListScreenState();
}

class _TrainingPackPresetListScreenState extends State<TrainingPackPresetListScreen> {
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
    final model = TrainingPackTemplateModel(
      id: tpl.id,
      name: tpl.name,
      description: tpl.description,
      category: preset.category,
      difficulty: 1,
      filters: const {},
      isTournament: preset.gameType == GameType.tournament,
      createdAt: DateTime.now(),
    );
    await context.read<TrainingPackTemplateStorageService>().add(model);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пак создан')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presets')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _presets.length,
              itemBuilder: (context, index) {
                final p = _presets[index];
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text(p.description),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => _generate(p),
                  ),
                );
              },
            ),
    );
  }
}
