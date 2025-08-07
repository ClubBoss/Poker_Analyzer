import 'dart:io';

import 'package:flutter/material.dart';

import '../models/game_type.dart';
import '../models/training_pack_template_set.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/autogen_pipeline_executor.dart';
import '../services/training_pack_auto_generator.dart';
import '../services/training_pack_template_set_library_service.dart';
import '../services/yaml_pack_exporter.dart';

class AutogenPipelineDebugControlPanel extends StatefulWidget {
  const AutogenPipelineDebugControlPanel({super.key});

  @override
  State<AutogenPipelineDebugControlPanel> createState() =>
      _AutogenPipelineDebugControlPanelState();
}

class _AutogenPipelineDebugControlPanelState
    extends State<AutogenPipelineDebugControlPanel> {
  final TrainingPackAutoGenerator _generator = TrainingPackAutoGenerator();
  final YamlPackExporter _exporter = const YamlPackExporter();
  List<TrainingPackTemplateSet> _sets = [];
  TrainingPackTemplateSet? _selectedSet;
  TrainingPackTemplateV2? _pack;

  @override
  void initState() {
    super.initState();
    TrainingPackTemplateSetLibraryService.instance.loadAll().then((_) {
      final all = TrainingPackTemplateSetLibraryService.instance.all;
      if (mounted) {
        setState(() {
          _sets = all;
          if (all.isNotEmpty) {
            _selectedSet = all.first;
          }
        });
      }
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _runGenerator() async {
    final set = _selectedSet;
    if (set == null) {
      _showSnack('Select a template set first');
      return;
    }
    final spots = await _generator.generate(set);
    final base = set.baseSpot;
    final pack = TrainingPackTemplateV2(
      id: base.id,
      name: base.title.isNotEmpty ? base.title : base.id,
      trainingType: TrainingType.custom,
      spots: spots,
      spotCount: spots.length,
      tags: List<String>.from(base.tags),
      gameType: GameType.cash,
      bb: base.hand.stacks['0']?.toInt() ?? 0,
      positions: [base.hand.position.name],
      meta: Map<String, dynamic>.from(base.meta),
    );
    setState(() => _pack = pack);
    _showSnack('Generated ${spots.length} spots');
  }

  Future<void> _runEnricher() async {
    final pack = _pack;
    if (pack == null) {
      _showSnack('Run generator first');
      return;
    }
    final executor = AutogenPipelineExecutor(generator: _generator);
    executor.theoryInjector.injectAll(pack.spots, {});
    executor.boardClassifier?.classifyAll(pack.spots);
    executor.skillLinker.linkAll(pack.spots);
    setState(() {});
    _showSnack('Enrichment complete');
  }

  Future<void> _runExporter() async {
    final pack = _pack;
    if (pack == null) {
      _showSnack('Nothing to export');
      return;
    }
    final file = await _exporter.export(pack);
    _showSnack('Exported to ${file.path}');
  }

  Future<void> _runFullPipeline() async {
    final set = _selectedSet;
    if (set == null) {
      _showSnack('Select a template set first');
      return;
    }
    final executor = AutogenPipelineExecutor();
    await executor.execute([set], existingYamlPath: 'packs/generated');
    _showSnack('Full pipeline completed');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<TrainingPackTemplateSet>(
              isExpanded: true,
              value: _selectedSet,
              hint: const Text('Select Template Set'),
              items: [
                for (final set in _sets)
                  DropdownMenuItem(
                    value: set,
                    child: Text(set.baseSpot.id),
                  ),
              ],
              onChanged: (v) => setState(() => _selectedSet = v),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _runGenerator,
                  child: const Text('Run Generator'),
                ),
                ElevatedButton(
                  onPressed: _runEnricher,
                  child: const Text('Run Enricher'),
                ),
                ElevatedButton(
                  onPressed: _runExporter,
                  child: const Text('Run Exporter'),
                ),
                ElevatedButton(
                  onPressed: _runFullPipeline,
                  child: const Text('Run Full Pipeline'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
