import 'dart:io';

import 'package:flutter/material.dart';

import '../models/inline_theory_entry.dart';
import '../models/training_pack_template_set.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/autogen_pipeline_executor.dart';
import '../services/training_pack_auto_generator.dart';
import '../services/training_pack_template_set_library_service.dart';
import '../services/yaml_pack_exporter.dart';

/// Debug panel allowing manual control over autogen pipeline steps.
class AutogenPipelineDebugControlPanel extends StatefulWidget {
  const AutogenPipelineDebugControlPanel({super.key});

  @override
  State<AutogenPipelineDebugControlPanel> createState() =>
      _AutogenPipelineDebugControlPanelState();
}

class _AutogenPipelineDebugControlPanelState
    extends State<AutogenPipelineDebugControlPanel> {
  List<TrainingPackTemplateSet> _sets = [];
  TrainingPackTemplateSet? _selected;
  List<TrainingPackSpot> _spots = [];
  TrainingPackTemplateV2? _pack;

  @override
  void initState() {
    super.initState();
    TrainingPackTemplateSetLibraryService.instance.loadAll().then((_) {
      if (!mounted) return;
      setState(() {
        _sets = TrainingPackTemplateSetLibraryService.instance.all;
        if (_sets.isNotEmpty) {
          _selected = _sets.first;
        }
      });
    });
  }

  Future<void> _runGenerator() async {
    final set = _selected;
    if (set == null) return;
    final generator = TrainingPackAutoGenerator();
    final spots = await generator.generate(set);
    if (!mounted) return;
    setState(() {
      _spots = spots;
      _pack = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generated ${spots.length} spots')),
    );
  }

  Future<void> _runEnricher() async {
    final set = _selected;
    if (set == null || _spots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generate spots first')),
      );
      return;
    }
    final exporter = _MemoryExporter();
    final executor = AutogenPipelineExecutor(
      generator: _StaticGenerator(_spots),
      exporter: exporter,
    );
    await executor.execute([set]);
    if (!mounted) return;
    setState(() {
      _pack = exporter.pack;
    });
    final count = _pack?.spots.length ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Enriched pack with $count spots')),
    );
  }

  Future<void> _runExporter() async {
    final pack = _pack;
    if (pack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to export')),
      );
      return;
    }
    final file = await const YamlPackExporter().export(pack);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported to ${file.path}')),
    );
  }

  Future<void> _runFull() async {
    final set = _selected;
    if (set == null) return;
    final generator = TrainingPackAutoGenerator();
    final executor = AutogenPipelineExecutor(generator: generator);
    final files = await executor.execute([set]);
    if (!mounted) return;
    final path = files.isNotEmpty ? files.first.path : 'none';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Full pipeline complete: $path')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<TrainingPackTemplateSet>(
              isExpanded: true,
              value: _selected,
              hint: const Text('Select Template Set'),
              items: [
                for (final s in _sets)
                  DropdownMenuItem(
                    value: s,
                    child: Text(s.baseSpot.id),
                  ),
              ],
              onChanged: (v) => setState(() => _selected = v),
            ),
            const SizedBox(height: 8),
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
                  onPressed: _runFull,
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

class _StaticGenerator extends TrainingPackAutoGenerator {
  final List<TrainingPackSpot> _spots;
  _StaticGenerator(this._spots);

  @override
  Future<List<TrainingPackSpot>> generate(
    dynamic template, {
    Map<String, InlineTheoryEntry> theoryIndex = const {},
    Iterable<TrainingPackSpot> existingSpots = const [],
    bool deduplicate = true,
  }) async {
    return _spots;
  }
}

class _MemoryExporter extends YamlPackExporter {
  TrainingPackTemplateV2? pack;
  _MemoryExporter();

  @override
  Future<File> export(TrainingPackTemplateV2 p) async {
    pack = p;
    final tmp = File('${Directory.systemTemp.path}/${p.id}.yaml');
    await tmp.writeAsString(exportYaml(p));
    return tmp;
  }
}
