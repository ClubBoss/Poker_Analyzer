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
  static const List<String> _textures = [
    'low',
    'paired',
    'monotone',
    'twoTone',
    'rainbow'
  ];

  @override
  void initState() {
    super.initState();
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
    final generator = TrainingPackAutoGenerator();
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

  @override
  void dispose() {
    _outputDirController.dispose();
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
                          Text('${((_targetMix[t] ?? 0) * 100).toStringAsFixed(0)}%'),
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
                  onPressed: _status == _AutogenStatus.running
                      ? _stopAutogen
                      : null,
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
