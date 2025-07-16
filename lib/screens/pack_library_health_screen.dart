import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/yaml_validation_service.dart';
import '../theme/app_colors.dart';

class PackLibraryHealthScreen extends StatefulWidget {
  const PackLibraryHealthScreen({super.key});

  @override
  State<PackLibraryHealthScreen> createState() => _PackLibraryHealthScreenState();
}

class _PackLibraryHealthScreenState extends State<PackLibraryHealthScreen> {
  bool _loading = true;
  final List<List<String>> _topics = [];
  final List<List<String>> _errors = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final coverage =
        await compute(_loadCoverageTask, 'assets/packs/v2/coverage_report.json');
    final errors = await compute(_validateYamlTask, '');
    if (!mounted) return;
    _topics
      ..clear()
      ..addAll([
        for (final m in coverage['missing'] as List<List<String>>) [...m, 'miss'],
        for (final w in coverage['weak'] as List<List<String>>) [...w, 'weak'],
      ]);
    _errors
      ..clear()
      ..addAll(errors.cast<List<String>>());
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Проверка библиотеки')),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ElevatedButton(
                  onPressed: _load,
                  child: const Text('🔄 Обновить'),
                ),
                const SizedBox(height: 16),
                DataTable(
                  columns: const [
                    DataColumn(label: Text('Audience')),
                    DataColumn(label: Text('Tag')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: [
                    for (final t in _topics)
                      DataRow(cells: [
                        DataCell(Text(t[0])),
                        DataCell(Text(t[1])),
                        DataCell(Text(t[2] == 'miss' ? 'missing' : 'weak')),
                      ]),
                  ],
                ),
                const SizedBox(height: 24),
                for (final e in _errors)
                  ListTile(
                    title: Text(e[0]),
                    subtitle: Text(e[1]),
                  ),
              ],
            ),
    );
  }
}

Future<Map<String, List<List<String>>>> _loadCoverageTask(String path) async {
  final file = File(path);
  if (!file.existsSync()) return {'missing': [], 'weak': []};
  final data = jsonDecode(await file.readAsString());
  final missing = <List<String>>[];
  final weak = <List<String>>[];
  if (data is Map) {
    final m = data['missing'];
    if (m is List) {
      for (final item in m) {
        if (item is Map) {
          final a = item['audience']?.toString();
          final t = item['tag']?.toString();
          if (a != null && t != null) missing.add([a, t]);
        }
      }
    }
    final w = data['weak'];
    if (w is List) {
      for (final item in w) {
        if (item is Map) {
          final a = item['audience']?.toString();
          final t = item['tag']?.toString();
          if (a != null && t != null) weak.add([a, t]);
        }
      }
    }
  }
  return {'missing': missing, 'weak': weak};
}

Future<List<List<String>>> _validateYamlTask(String _) async {
  final res = await const YamlValidationService().validateAll();
  return [for (final e in res) [e.$1, e.$2]];
}

