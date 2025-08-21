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
import 'yaml_pack_diff_screen.dart';
import '../widgets/selectable_list_item.dart';

class YamlPackHistoryScreen extends StatefulWidget {
  const YamlPackHistoryScreen({super.key});

  @override
  State<YamlPackHistoryScreen> createState() => _YamlPackHistoryScreenState();
}

class _YamlPackHistoryScreenState extends State<YamlPackHistoryScreen> {
  final List<File> _files = [];
  bool _loading = true;
  int _preview = -1;
  final Set<int> _selectedIndices = {};
  String? _markdown;
  String? _yaml;
  final ScrollController _ctrl = ScrollController();

  bool get _selectionMode => _selectedIndices.isNotEmpty;

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
        _preview = -1;
        _markdown = null;
        _yaml = null;
        _selectedIndices.clear();
      });
    }
  }

  Future<void> _select(File file, int index) async {
    if (_selectionMode) {
      _toggleSelection(index);
      return;
    }
    String? md;
    String? y;
    try {
      final yaml = await file.readAsString();
      y = yaml;
      final map = const YamlReader().read(yaml);
      final tpl = TrainingPackTemplateV2.fromJson(
        Map<String, dynamic>.from(map),
      );
      md = const YamlPackMarkdownPreviewService().generateMarkdownPreview(tpl);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _preview = index;
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

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIndices.clear());
  }

  Future<TrainingPackTemplateV2?> _loadPack(File file) async {
    try {
      final yaml = await file.readAsString();
      final map = const YamlReader().read(yaml);
      return TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
    } catch (_) {
      return null;
    }
  }

  Future<void> _compare() async {
    if (_selectedIndices.length != 2) return;
    final idx = _selectedIndices.toList();
    final a = await _loadPack(_files[idx[0]]);
    final b = await _loadPack(_files[idx[1]]);
    if (a == null || b == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YamlPackDiffScreen(packA: a, packB: b),
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
      appBar: AppBar(
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              )
            : null,
        title: _selectionMode
            ? Text('${_selectedIndices.length}')
            : const Text('Yaml History'),
        actions: _selectionMode && _selectedIndices.length == 2
            ? [IconButton(onPressed: _compare, icon: const Icon(Icons.compare))]
            : null,
      ),
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
                    final date = DateFormat(
                      'yyyy-MM-dd HH:mm',
                    ).format(f.statSync().modified);
                    final selected = _selectedIndices.contains(i);
                    return SelectableListItem(
                      selectionMode: _selectionMode,
                      selected: selected,
                      onTap: _selectionMode
                          ? () => _toggleSelection(i)
                          : () => _select(f, i),
                      onLongPress: () => _toggleSelection(i),
                      child: ListTile(
                        selected: i == _preview,
                        title: Text(name),
                        subtitle: Text(date),
                      ),
                    );
                  },
                );
                final preview = Container(
                  color: AppColors.cardBackground,
                  padding: const EdgeInsets.all(16),
                  child: _preview == -1
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
