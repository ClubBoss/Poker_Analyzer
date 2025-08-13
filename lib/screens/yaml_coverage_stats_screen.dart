import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/pack_library_loader_service.dart';
import '../services/yaml_coverage_report_service.dart';
import '../models/yaml_coverage_report.dart';
import '../theme/app_colors.dart';

class YamlCoverageStatsScreen extends StatefulWidget {
  const YamlCoverageStatsScreen({super.key});

  @override
  State<YamlCoverageStatsScreen> createState() =>
      _YamlCoverageStatsScreenState();
}

class _YamlCoverageStatsScreenState extends State<YamlCoverageStatsScreen> {
  bool _loading = true;
  YamlCoverageReport? _report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final map = await compute(_reportTask, '');
    if (!mounted) return;
    setState(() {
      _report = YamlCoverageReport.fromJson(map);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('YAML Coverage')),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ElevatedButton(
                    onPressed: _load, child: const Text('🔄 Обновить')),
                const SizedBox(height: 16),
                if (_report != null) ...[
                  _section('Частота тегов', _report!.tags),
                  const SizedBox(height: 24),
                  _section('Частота аудиторий', _report!.audiences),
                  const SizedBox(height: 24),
                  _section('Частота позиций', _report!.positions),
                  const SizedBox(height: 24),
                  _section('Частота категорий', _report!.categories),
                ],
              ],
            ),
    );
  }

  Widget _section(String title, Map<String, int> data) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = entries.isNotEmpty ? entries.first.value : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(width: 140, child: Text(e.key)),
                Expanded(
                  child: LinearProgressIndicator(
                    value: e.value / max,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.lightBlue),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${e.value}'),
              ],
            ),
          ),
      ],
    );
  }
}

Future<Map<String, dynamic>> _reportTask(String _) async {
  await PackLibraryLoaderService.instance.loadLibrary();
  final list = PackLibraryLoaderService.instance.library;
  final report = const YamlCoverageReportService().generate(list);
  return report.toJson();
}
