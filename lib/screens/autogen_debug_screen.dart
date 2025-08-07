import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/autogen_realtime_stats_panel.dart';
import '../widgets/inline_report_viewer_widget.dart';
import '../widgets/autogen_history_chart_widget.dart';
import '../services/autogen_stats_dashboard_service.dart';
import '../services/autogen_status_dashboard_service.dart';
import '../services/autogen_pipeline_executor.dart';
import '../services/training_pack_auto_generator.dart';
import '../services/training_pack_template_set_library_service.dart';
import '../services/yaml_pack_exporter.dart';
import '../models/training_pack_template_set.dart';
import '../core/training/export/training_pack_exporter_v2.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/autogen_session_meta.dart';
import '../widgets/autogen_pipeline_debug_control_panel.dart';

class _DirExporter extends TrainingPackExporterV2 {
  final String outDir;
  const _DirExporter(this.outDir);

  @override
  Future<File> exportToFile(TrainingPackTemplateV2 pack, {String? fileName}) async {
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
  final TextEditingController _outputDirController =
      TextEditingController(text: 'packs/generated');
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    TrainingPackTemplateSetLibraryService.instance.loadAll().then((_) {
      if (mounted) {
        setState(() {
          _templateSets =
              TrainingPackTemplateSetLibraryService.instance.all;
          if (_templateSets.isNotEmpty) {
            _selectedSet = _templateSets.first;
          }
        });
      }
    });
  }

  void _startAutogen() {
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
      status: status,
      exporter: exporter,
    );
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
      AutogenStatusDashboardService.instance
          .updateSessionStatus(id, 'stopped');
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
                      DropdownMenuItem(
                        value: s,
                        child: Text(s.baseSpot.id),
                      ),
                  ],
                  onChanged: (v) => setState(() => _selectedSet = v),
                ),
                TextField(
                  controller: _outputDirController,
                  decoration:
                      const InputDecoration(labelText: 'Output Directory'),
                ),
              ],
            ),
          ),
          const AutogenPipelineDebugControlPanel(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed:
                      _status == _AutogenStatus.running ? null : _startAutogen,
                  child: const Text('Start Autogen'),
                ),
                OutlinedButton(
                  onPressed:
                      _status == _AutogenStatus.running ? _stopAutogen : null,
                  child: const Text('Stop'),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${_status.name}'),
                    Text('Template: '
                        '${_selectedSet?.baseSpot.id ?? 'none'}'),
                    Text('Output: ${_outputDirController.text}'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: Container()),
          SizedBox(
            height: 200,
            child: AutogenHistoryChartWidget(),
          ),
          const AutogenRealtimeStatsPanel(),
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

