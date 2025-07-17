import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../services/training_pack_template_storage_service.dart';
import '../services/yaml_pack_history_service.dart';
import '../services/yaml_pack_exporter_service.dart';
import '../theme/app_colors.dart';
import 'package:open_filex/open_filex.dart';
import 'v2/training_pack_spot_editor_screen.dart';

class YamlPackEditorScreen extends StatefulWidget {
  const YamlPackEditorScreen({super.key});
  @override
  State<YamlPackEditorScreen> createState() => _YamlPackEditorScreenState();
}

class _YamlPackEditorScreenState extends State<YamlPackEditorScreen> {
  File? _file;
  TrainingPackTemplateV2? _pack;
  final _name = TextEditingController();
  final _goal = TextEditingController();
  final _desc = TextEditingController();
  List<String> _tags = [];

  bool get _outdated =>
      _versionLess(_pack?.meta['schemaVersion']?.toString(), '2.0.0');

  bool _versionLess(String? v, String target) {
    if (v == null || v.isEmpty) return true;
    final a = v.split('.').map(int.parse).toList();
    final b = target.split('.').map(int.parse).toList();
    while (a.length < 3) a.add(0);
    while (b.length < 3) b.add(0);
    for (var i = 0; i < 3; i++) {
      if (a[i] < b[i]) return true;
      if (a[i] > b[i]) return false;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _pick();
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
    );
    if (result == null || result.files.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final path = result.files.single.path;
    if (path == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final file = File(path);
    try {
      final yaml = await file.readAsString();
      final map = const YamlReader().read(yaml);
      final pack = TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
      setState(() {
        _file = file;
        _pack = pack;
        _name.text = pack.name;
        _goal.text = pack.goal;
        _desc.text = pack.description;
        _tags = List<String>.from(pack.tags);
      });
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _save() async {
    final pack = _pack;
    final file = _file;
    if (pack == null || file == null) return;
    pack
      ..name = _name.text.trim()
      ..goal = _goal.text.trim()
      ..description = _desc.text.trim()
      ..tags
          ..clear()
          ..addAll(_tags)
      ..spotCount = pack.spots.length;
    await const YamlPackHistoryService().saveSnapshot(pack, 'save');
    const service = YamlPackHistoryService();
    service.addChangeLog(pack, 'save', 'editor', 'save');
    await file.writeAsString(pack.toYaml());
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Сохранено')));
  }

  Future<void> _editSpot(TrainingPackSpot spot) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackSpotEditorScreen(
          spot: spot,
          templateTags: _tags,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _addSpot() async {
    final spot = TrainingPackSpot(id: const Uuid().v4());
    _pack!.spots.add(spot);
    await _editSpot(spot);
  }

  void _removeSpot(int index) {
    setState(() => _pack!.spots.removeAt(index));
  }

  Future<void> _addTag() async {
    final c = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Новый тег'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('OK')),
        ],
      ),
    );
    if (tag != null && tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
    }
  }

  Future<void> _export() async {
    final pack = _pack;
    if (pack == null) return;
    final format = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('YAML'),
              onTap: () => Navigator.pop(context, 'yaml'),
            ),
            ListTile(
              title: const Text('Markdown'),
              onTap: () => Navigator.pop(context, 'markdown'),
            ),
            ListTile(
              title: const Text('Text'),
              onTap: () => Navigator.pop(context, 'plain'),
            ),
          ],
        ),
      ),
    );
    if (format == null) return;
    final file = await const YamlPackExporterService().exportToTextFile(pack, format);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Файл сохранён: ${file.path}'),
        action: SnackBarAction(
          label: '📂 Открыть',
          onPressed: () => OpenFilex.open(file.path),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final pack = _pack;
    final file = _file;
    return Scaffold(
      appBar: AppBar(
        title: Text(file == null ? 'YAML Pack' : file.path.split(Platform.pathSeparator).last),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
          IconButton(icon: const Icon(Icons.download), onPressed: _export),
        ],
      ),
      backgroundColor: AppColors.background,
      body: pack == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_outdated)
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.amber,
                      child: const Text(
                        '⚠ Устаревшая схема',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  if (_outdated) const SizedBox(height: 12),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Название'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _goal,
                    decoration: const InputDecoration(labelText: 'Цель'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _desc,
                    decoration: const InputDecoration(labelText: 'Описание'),
                    maxLines: null,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    children: [
                      for (final t in _tags)
                        InputChip(
                          label: Text(t),
                          onDeleted: () => setState(() => _tags.remove(t)),
                        ),
                      InputChip(label: const Text('+'), onPressed: _addTag),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pack.spots.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final s = pack.spots[i];
                      final title = s.title.isNotEmpty ? s.title : s.hand.heroCards;
                      final sub = '${s.hand.position.label} ${s.hand.board.join(' ')}';
                      return Card(
                        color: AppColors.cardBackground,
                        child: ListTile(
                          title: Text(title),
                          subtitle: Text(sub),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeSpot(i),
                          ),
                          onTap: () => _editSpot(s),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addSpot,
                    child: const Text('＋ Spot'),
                  ),
                ],
              ),
            ),
    );
  }
}
