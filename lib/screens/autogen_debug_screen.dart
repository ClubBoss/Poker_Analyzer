import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/autogen_realtime_stats_panel.dart';
import '../widgets/inline_report_viewer_widget.dart';
import '../widgets/autogen_history_chart_widget.dart';
import '../services/autogen_stats_dashboard_service.dart';
import '../services/autogen_status_dashboard_service.dart';
import '../widgets/seed_lint_panel_widget.dart';
import '../services/autogen_pipeline_executor.dart';
import '../widgets/autogen_status_panel.dart';
import '../services/training_pack_auto_generator.dart';
import '../services/training_pack_template_set_library_service.dart';
import '../services/yaml_pack_exporter.dart';
import '../models/training_pack_template_set.dart';
import '../core/training/export/training_pack_exporter_v2.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/autogen_session_meta.dart';
import '../widgets/autogen_pipeline_debug_control_panel.dart';
import '../widgets/autogen_duplicate_table_widget.dart';
import 'pack_fingerprint_comparer_report_ui.dart';
import '../widgets/deduplication_policy_editor.dart';
import '../widgets/theory_coverage_panel_widget.dart';
import '../models/texture_filter_config.dart';
import '../services/inline_theory_link_auto_injector.dart';
import '../models/autogen_preset.dart';
import '../services/autogen_preset_service.dart';
import '../models/theory_injector_config.dart';

class _DirExporter extends TrainingPackExporterV2 {
  final String outDir;
  const _DirExporter(this.outDir);

  @override
  Future<File> exportToFile(
    TrainingPackTemplateV2 pack, {
    String? fileName,
  }) async {
    final dir = Directory(outDir);
    await dir.create(recursive: true);
    final safeName = (fileName ?? pack.name)
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(' ', '_');
    final file = File('${dir.path}/$safeName.yaml');
    await file.writeAsString(exportYaml(pack));
    return file;
  }
}

enum _AutogenStatus { idle, running, completed, stopped }

/// Debug screen that monitors autogeneration progress and controls the pipeline.
class AutogenDebugScreen extends StatefulWidget {
  const AutogenDebugScreen({super.key});

  @override
  State<AutogenDebugScreen> createState() => _AutogenDebugScreenState();
}

class _AutogenDebugScreenState extends State<AutogenDebugScreen> {
  _AutogenStatus _status = _AutogenStatus.idle;
  TrainingPackAutoGenerator? _generator;
  List<TrainingPackTemplateSet> _templateSets = const [];
  TrainingPackTemplateSet? _selectedSet;
  final TextEditingController _outputDirController = TextEditingController(
    text: 'packs/generated',
  );
  String? _sessionId;
  final Set<String> _include = {};
  final Set<String> _exclude = {};
  final Map<String, double> _targetMix = {};
  final AutogenPresetService _presetService = AutogenPresetService.instance;
  List<AutogenPreset> _presets = [];
  AutogenPreset? _selectedPreset;
  int _spotsPerPack = 12;
  int _streets = 1;
  double _theoryRatio = 0.5;
  static const List<String> _textures = [
    'low',
    'paired',
    'monotone',
    'twoTone',
    'rainbow'
  ];
  bool _theoryEnabled = true;
  int _maxLinks = 2;
  double _minScore = 0.5;
  double _wTag = 0.6;
  double _wTex = 0.25;
  double _wCluster = 0.15;
  bool _preferNovelty = true;
  final TextEditingController _maxLinksController =
      TextEditingController(text: '2');
  final TextEditingController _minScoreController =
      TextEditingController(text: '0.5');
  final TextEditingController _wTagController =
      TextEditingController(text: '0.6');
  final TextEditingController _wTexController =
      TextEditingController(text: '0.25');
  final TextEditingController _wClusterController =
      TextEditingController(text: '0.15');

  @override
  void initState() {
    super.initState();
    _presetService.load().then((_) async {
      final last = await _presetService.loadLastUsed();
      if (mounted) {
        setState(() {
          _presets = _presetService.presets;
          _selectedPreset = last;
        });
        if (last != null) {
          _applyPreset(last, showToast: false);
        }
      }
    });
    TrainingPackTemplateSetLibraryService.instance.loadAll().then((_) {
      if (mounted) {
        setState(() {
          _templateSets = TrainingPackTemplateSetLibraryService.instance.all;
          if (_templateSets.isNotEmpty) {
            _selectedSet = _templateSets.first;
          }
        });
      }
    });
  }

  Future<void> _startAutogen() async {
    if (_status == _AutogenStatus.running) return;
    final dashboard = AutogenStatsDashboardService.instance;
    dashboard.start();
    final selectedPreset = _selectedPreset;
    if (selectedPreset != null) {
      dashboard.logPreset(selectedPreset);
    }
    final status = AutogenStatusDashboardService.instance;
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    status.registerSession(
      AutogenSessionMeta(
        sessionId: sessionId,
        packId: _selectedSet?.baseSpot.id ?? 'unknown',
        startedAt: DateTime.now(),
        status: 'running',
      ),
    );
    final generator = TrainingPackAutoGenerator(spotsPerPack: _spotsPerPack);
    _generator = generator;
    final exporter = YamlPackExporter(
      delegate: _DirExporter(_outputDirController.text),
    );
    final executor = AutogenPipelineExecutor(
      generator: generator,
      dashboard: dashboard,
      exporter: exporter,
      textureFilters: TextureFilterConfig(
        include: _include,
        exclude: _exclude,
        targetMix: Map.fromEntries(
          _targetMix.entries.where((e) => e.value > 0),
        ),
      ),
      theoryInjector: InlineTheoryLinkAutoInjector(
        enabled: _theoryEnabled,
        maxLinksPerSpot: _maxLinks,
        minScore: _minScore,
        wTag: _wTag,
        wTex: _wTex,
        wCluster: _wCluster,
        preferNovelty: _preferNovelty,
      ),
      presetId: selectedPreset?.id,
      presetName: selectedPreset?.name,
    );
    await status.bindExecutor(executor);
    setState(() {
      _status = _AutogenStatus.running;
      _sessionId = sessionId;
    });
    Future(() async {
      await executor.execute(
        _selectedSet != null ? [_selectedSet!] : const [],
        existingYamlPath: _outputDirController.text,
      );
      if (mounted && _status == _AutogenStatus.running) {
        setState(() => _status = _AutogenStatus.completed);
      }
      status.updateSessionStatus(sessionId, 'done');
    });
  }

  void _stopAutogen() {
    _generator?.abort();
    if (mounted) {
      setState(() => _status = _AutogenStatus.stopped);
    }
    final id = _sessionId;
    if (id != null) {
      AutogenStatusDashboardService.instance.updateSessionStatus(id, 'stopped');
    }
  }

  AutogenPreset _currentPreset({required String id, required String name}) {
    return AutogenPreset(
      id: id,
      name: name,
      textures: TextureFilterConfig(
        include: Set.from(_include),
        exclude: Set.from(_exclude),
        targetMix: Map.from(_targetMix),
      ),
      theory: TheoryInjectorConfig(
        enabled: _theoryEnabled,
        maxLinksPerSpot: _maxLinks,
        minScore: _minScore,
        wTag: _wTag,
        wTex: _wTex,
        wCluster: _wCluster,
        preferNovelty: _preferNovelty,
      ),
      spotsPerPack: _spotsPerPack,
      streets: _streets,
      theoryRatio: _theoryRatio,
      outputDir: _outputDirController.text,
    );
  }

  void _applyPreset(AutogenPreset preset, {bool showToast = true}) {
    setState(() {
      _include
        ..clear()
        ..addAll(preset.textures.include);
      _exclude
        ..clear()
        ..addAll(preset.textures.exclude);
      _targetMix
        ..clear()
        ..addAll(preset.textures.targetMix);
      final total = _targetMix.values.fold(0.0, (a, b) => a + b);
      if (total > 1 && total > 0) {
        _targetMix.updateAll((key, value) => value / total);
      }
      _theoryEnabled = preset.theory.enabled;
      _maxLinks = preset.theory.maxLinksPerSpot;
      _minScore = preset.theory.minScore;
      _wTag = preset.theory.wTag.clamp(0, 1);
      _wTex = preset.theory.wTex.clamp(0, 1);
      _wCluster = preset.theory.wCluster.clamp(0, 1);
      _preferNovelty = preset.theory.preferNovelty;
      _maxLinksController.text = _maxLinks.toString();
      _minScoreController.text = _minScore.toString();
      _wTagController.text = _wTag.toString();
      _wTexController.text = _wTex.toString();
      _wClusterController.text = _wCluster.toString();
      _outputDirController.text = preset.outputDir;
      _spotsPerPack = preset.spotsPerPack;
      _streets = preset.streets;
      _theoryRatio = preset.theoryRatio;
    });
    _presetService.persistLastUsed(preset.id);
    if (showToast) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preset "${preset.name}" applied')),
      );
    }
  }

  void _applySelectedPreset() {
    final p = _selectedPreset;
    if (p != null) {
      _applyPreset(p);
    }
  }

  Future<void> _saveAsPreset() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save Preset'),
        content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final preset = _currentPreset(id: id, name: name);
    await _presetService.savePreset(preset);
    setState(() {
      _presets = _presetService.presets;
      _selectedPreset = preset;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Preset saved')));
  }

  Future<void> _updatePreset() async {
    final p = _selectedPreset;
    if (p == null) return;
    final updated = _currentPreset(id: p.id, name: p.name);
    await _presetService.savePreset(updated);
    setState(() {
      _presets = _presetService.presets;
      _selectedPreset = updated;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Preset updated')));
  }

  Future<void> _deletePreset() async {
    final p = _selectedPreset;
    if (p == null) return;
    await _presetService.deletePreset(p.id);
    setState(() {
      _presets = _presetService.presets;
      _selectedPreset = null;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Preset deleted')));
  }

  void _exportPresets() {
    final json = _presetService.exportPresets();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export Presets'),
        content: SingleChildScrollView(child: SelectableText(json)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _importPresets() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import Presets'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'JSON'),
          maxLines: 8,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import')),
        ],
      ),
    );
    if (ok == true) {
      await _presetService.importPresets(controller.text);
      setState(() {
        _presets = _presetService.presets;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Presets imported')));
    }
  }

  @override
  void dispose() {
    _outputDirController.dispose();
    _maxLinksController.dispose();
    _minScoreController.dispose();
    _wTagController.dispose();
    _wTexController.dispose();
    _wClusterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final statusService = AutogenStatusDashboardService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Autogen Debug')),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Presets'),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<AutogenPreset>(
                        isExpanded: true,
                        value: _selectedPreset,
                        hint: const Text('Select Preset'),
                        items: [
                          for (final p in _presets)
                            DropdownMenuItem(value: p, child: Text(p.name)),
                        ],
                        onChanged: (v) => setState(() => _selectedPreset = v),
                      ),
                    ),
                    TextButton(
                        onPressed: _applySelectedPreset,
                        child: const Text('Apply')),
                    TextButton(
                        onPressed: _saveAsPreset,
                        child: const Text('Save as...')),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                        onPressed: _updatePreset, child: const Text('Update')),
                    TextButton(
                        onPressed: _deletePreset, child: const Text('Delete')),
                    TextButton(
                        onPressed: _exportPresets, child: const Text('Export')),
                    TextButton(
                        onPressed: _importPresets, child: const Text('Import')),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButton<TrainingPackTemplateSet>(
                  isExpanded: true,
                  value: _selectedSet,
                  hint: const Text('Select Template Set'),
                  items: [
                    for (final s in _templateSets)
                      DropdownMenuItem(value: s, child: Text(s.baseSpot.id)),
                  ],
                  onChanged: (v) => setState(() => _selectedSet = v),
                ),
                TextField(
                  controller: _outputDirController,
                  decoration: const InputDecoration(
                    labelText: 'Output Directory',
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Include Textures'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final t in _textures)
                      FilterChip(
                        label: Text(t),
                        selected: _include.contains(t),
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _include.add(t);
                            } else {
                              _include.remove(t);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Exclude Textures'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final t in _textures)
                      FilterChip(
                        label: Text(t),
                        selected: _exclude.contains(t),
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _exclude.add(t);
                            } else {
                              _exclude.remove(t);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Target Mix'),
                Column(
                  children: [
                    for (final t in _textures)
                      Row(
                        children: [
                          SizedBox(width: 80, child: Text(t)),
                          Expanded(
                            child: Slider(
                              value: _targetMix[t] ?? 0,
                              onChanged: (v) {
                                setState(() {
                                  _targetMix[t] = v;
                                });
                              },
                            ),
                          ),
                          Text(
                              '${((_targetMix[t] ?? 0) * 100).toStringAsFixed(0)}%'),
                        ],
                      ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _include.clear();
                      _exclude.clear();
                      _targetMix.clear();
                    });
                  },
                  child: const Text('Reset Textures'),
                ),
                const SizedBox(height: 16),
                const Text('Theory Injector'),
                SwitchListTile(
                  title: const Text('Enable'),
                  value: _theoryEnabled,
                  onChanged: (v) => setState(() => _theoryEnabled = v),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _maxLinksController,
                        decoration: const InputDecoration(
                          labelText: 'Max links per spot',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            _maxLinks = int.tryParse(v) ?? _maxLinks,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _minScoreController,
                        decoration: const InputDecoration(
                          labelText: 'Min score',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            _minScore = double.tryParse(v) ?? _minScore,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _wTagController,
                        decoration: const InputDecoration(
                          labelText: 'w_tag',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _wTag = double.tryParse(v) ?? _wTag,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _wTexController,
                        decoration: const InputDecoration(
                          labelText: 'w_tex',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _wTex = double.tryParse(v) ?? _wTex,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _wClusterController,
                        decoration: const InputDecoration(
                          labelText: 'w_cluster',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            _wCluster = double.tryParse(v) ?? _wCluster,
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  title: const Text('Prefer novelty'),
                  value: _preferNovelty,
                  onChanged: (v) => setState(() => _preferNovelty = v),
                ),
              ],
            ),
          ),
          const AutogenStatusPanel(),
          const AutogenPipelineDebugControlPanel(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _status == _AutogenStatus.running
                      ? null
                      : () => _startAutogen(),
                  child: const Text('Start Autogen'),
                ),
                OutlinedButton(
                  onPressed:
                      _status == _AutogenStatus.running ? _stopAutogen : null,
                  child: const Text('Stop'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PackFingerprintComparerReportUI(),
                      ),
                    );
                  },
                  child: const Text('View Duplicate Report'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DeduplicationPolicyEditor(),
                      ),
                    );
                  },
                  child: const Text('Edit Policies'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final dashboard = AutogenStatsDashboardService.instance;
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Category Coverage'),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              for (final entry
                                  in dashboard.categoryCoverage.entries)
                                ListTile(
                                  title: Text(entry.key),
                                  trailing: Text(
                                    '${dashboard.categoryCounts[entry.key] ?? 0} - '
                                    '${(entry.value * 100).toStringAsFixed(0)}%',
                                  ),
                                ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Coverage View'),
                ),
                ValueListenableBuilder<List<DuplicatePackInfo>>(
                  valueListenable: statusService.duplicatesNotifier,
                  builder: (context, dups, _) {
                    final color = dups.isEmpty ? null : Colors.orange;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: ${_status.name}',
                          style: TextStyle(color: color),
                        ),
                        Text(
                          'Template: '
                          '${_selectedSet?.baseSpot.id ?? 'none'}',
                        ),
                        Text('Output: ${_outputDirController.text}'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(child: Container()),
          SizedBox(height: 200, child: AutogenHistoryChartWidget()),
          const AutogenRealtimeStatsPanel(),
          SizedBox(height: 200, child: TheoryCoveragePanelWidget()),
          SizedBox(height: 200, child: SeedLintPanelWidget()),
          SizedBox(height: 200, child: AutogenDuplicateTableWidget()),
          SizedBox(
            height: 200,
            child: _sessionId == null
                ? const Center(child: Text('No session'))
                : InlineReportViewerWidget(sessionId: _sessionId!),
          ),
        ],
      ),
    );
  }
}
