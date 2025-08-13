import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';

class BoosterYAMLPreviewerScreen extends StatefulWidget {
  const BoosterYAMLPreviewerScreen({super.key});

  @override
  State<BoosterYAMLPreviewerScreen> createState() =>
      _BoosterYAMLPreviewerScreenState();
}

class _BoosterYAMLPreviewerScreenState
    extends State<BoosterYAMLPreviewerScreen> {
  final List<File> _files = [];
  bool _loading = true;
  int _selected = -1;
  String? _yaml;
  Map<String, dynamic>? _json;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dir = Directory('yaml_out/boosters');
    if (!dir.existsSync()) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final list = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    if (!mounted) return;
    setState(() {
      _files
        ..clear()
        ..addAll(list);
      _loading = false;
    });
  }

  Future<void> _select(File file, int index) async {
    try {
      final yaml = await file.readAsString();
      final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
      if (!mounted) return;
      setState(() {
        _selected = index;
        _yaml = yaml;
        _json = tpl.toJson();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final jsonText =
        _json == null ? '' : const JsonEncoder.withIndent('  ').convert(_json);
    return Scaffold(
      appBar: AppBar(title: const Text('Booster YAML Preview')),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? const Center(child: Text('No files'))
              : Row(
                  children: [
                    SizedBox(
                      width: 280,
                      child: ListView.builder(
                        itemCount: _files.length,
                        itemBuilder: (_, i) {
                          final f = _files[i];
                          final name =
                              f.path.split(Platform.pathSeparator).last;
                          return ListTile(
                            selected: i == _selected,
                            title: Text(name),
                            onTap: () => _select(f, i),
                          );
                        },
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            const TabBar(
                                tabs: [Tab(text: 'YAML'), Tab(text: 'JSON')]),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  SingleChildScrollView(
                                    padding: const EdgeInsets.all(16),
                                    child: SelectableText(
                                      _yaml ?? 'Select file',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  SingleChildScrollView(
                                    padding: const EdgeInsets.all(16),
                                    child: SelectableText(
                                      jsonText.isEmpty
                                          ? 'Select file'
                                          : jsonText,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
