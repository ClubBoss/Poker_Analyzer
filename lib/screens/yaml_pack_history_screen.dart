import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/yaml_pack_markdown_preview_service.dart';
import '../theme/app_colors.dart';
import 'yaml_viewer_screen.dart';

class YamlPackHistoryScreen extends StatefulWidget {
  const YamlPackHistoryScreen({super.key});

  @override
  State<YamlPackHistoryScreen> createState() => _YamlPackHistoryScreenState();
}

class _YamlPackHistoryScreenState extends State<YamlPackHistoryScreen> {
  final List<File> _files = [];
  bool _loading = true;
  int _selected = -1;
  String? _markdown;
  String? _yaml;
  final ScrollController _ctrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dir = await getApplicationDocumentsDirectory();
    final hist = Directory('${dir.path}/training_packs/history');
    final list = hist
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'))
        .toList();
    list.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    if (mounted) {
      setState(() {
        _files
          ..clear()
          ..addAll(list);
        _loading = false;
      });
    }
  }

  Future<void> _select(File file, int index) async {
    String? md;
    String? y;
    try {
      final yaml = await file.readAsString();
      y = yaml;
      final map = const YamlReader().read(yaml);
      final tpl = TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
      md = const YamlPackMarkdownPreviewService().generateMarkdownPreview(tpl);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _selected = index;
      _markdown = md;
      _yaml = y;
    });
    _ctrl.jumpTo(0);
  }

  Future<void> _open(File file) async {
    final yaml = await file.readAsString();
    final name = file.path.split(Platform.pathSeparator).last;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YamlViewerScreen(yamlText: yaml, title: name),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Yaml History')),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, c) {
                final list = ListView.builder(
                  itemCount: _files.length,
                  itemBuilder: (_, i) {
                    final f = _files[i];
                    final name = f.path.split(Platform.pathSeparator).last;
                    final date = DateFormat('yyyy-MM-dd HH:mm')
                        .format(f.statSync().modified);
                    return ListTile(
                      selected: i == _selected,
                      title: Text(name),
                      subtitle: Text(date),
                      onTap: () => _select(f, i),
                      onLongPress: () => _open(f),
                    );
                  },
                );
                final preview = Container(
                  color: AppColors.cardBackground,
                  padding: const EdgeInsets.all(16),
                  child: _selected == -1
                      ? const Text('Нет файла')
                      : _markdown != null
                          ? SingleChildScrollView(
                              controller: _ctrl,
                              child: SelectableText(
                                _markdown!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            )
                          : SingleChildScrollView(
                              controller: _ctrl,
                              child: SelectableText(
                                _yaml ?? '',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                );
                if (c.maxWidth > 600) {
                  return Row(
                    children: [
                      Expanded(child: list),
                      SizedBox(width: 400, child: preview),
                    ],
                  );
                }
                return Column(
                  children: [
                    Expanded(child: list),
                    SizedBox(height: 300, child: preview),
                  ],
                );
              },
            ),
    );
  }
}
