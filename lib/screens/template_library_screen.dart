import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

import '../helpers/color_utils.dart';
import '../services/template_storage_service.dart';
import '../models/training_pack_template.dart';
import 'create_pack_from_template_screen.dart';
import 'create_template_screen.dart';
import 'template_hands_editor_screen.dart';
import 'template_preview_dialog.dart';
import '../widgets/sync_status_widget.dart';

class TemplateLibraryScreen extends StatefulWidget {
  const TemplateLibraryScreen({super.key});

  @override
  State<TemplateLibraryScreen> createState() => _TemplateLibraryScreenState();
}

class _TemplateLibraryScreenState extends State<TemplateLibraryScreen> {
  static const _key = 'template_filter_game_type';
  static const _sortKey = 'template_sort_order';
  String _filter = 'all';
  String _sort = 'updatedAt';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _filter = prefs.getString(_key) ?? 'all';
      _sort = prefs.getString(_sortKey) ?? 'updatedAt';
    });
  }

  Future<void> _setFilter(String value) async {
    setState(() => _filter = value);
    final prefs = await SharedPreferences.getInstance();
    if (value == 'all') {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, value);
    }
  }

  Future<void> _setSort(String value) async {
    setState(() => _sort = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortKey, value);
  }

  List<TrainingPackTemplate> _applySorting(List<TrainingPackTemplate> list) {
    final copy = [...list];
    switch (_sort) {
      case 'name':
        copy.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'hands':
        copy.sort((a, b) {
          final cmp = b.hands.length.compareTo(a.hands.length);
          return cmp == 0 ? a.name.compareTo(b.name) : cmp;
        });
        break;
      default:
        copy.sort((a, b) {
          final cmp = b.updatedAt.compareTo(a.updatedAt);
          return cmp == 0 ? a.name.compareTo(b.name) : cmp;
        });
    }
    return copy;
  }

  Future<void> _importTemplate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    Uint8List? data = result.files.single.bytes;
    final path = result.files.single.path;
    if (data == null && path != null) data = await File(path).readAsBytes();
    if (data == null) return;
    final service = context.read<TemplateStorageService>();
    final error = service.importTemplate(data);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('⚠️ $error')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Шаблон импортирован')));
    }
  }

  Future<void> _createTemplate() async {
    final template = await Navigator.push<TrainingPackTemplate?>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTemplateScreen()),
    );
    if (template == null) return;
    context.read<TemplateStorageService>().addTemplate(template);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateHandsEditorScreen(template: template),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = context.watch<TemplateStorageService>().templates;
    List<TrainingPackTemplate> visible = templates;
    if (_filter == 'tournament') {
      visible = [
        for (final t in templates)
          if (t.gameType.toLowerCase().startsWith('tour')) t
      ];
    } else if (_filter == 'cash') {
      visible = [
        for (final t in templates)
          if (t.gameType.toLowerCase().contains('cash')) t
      ];
    }
    visible = _applySorting(visible);
    return Scaffold(
      appBar: AppBar(title: const Text('Шаблоны')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _filter,
                    underline: const SizedBox.shrink(),
                    onChanged: (v) => v != null ? _setFilter(v) : null,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Все')),
                      DropdownMenuItem(value: 'tournament', child: Text('Tournament')),
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: _sort,
                    underline: const SizedBox.shrink(),
                    onChanged: (v) => v != null ? _setSort(v) : null,
                    items: const [
                      DropdownMenuItem(value: 'updatedAt', child: Text('По дате')),
                      DropdownMenuItem(value: 'name', child: Text('По имени')),
                      DropdownMenuItem(value: 'hands', child: Text('По рукам')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: visible.length,
              itemBuilder: (context, i) {
                final t = visible[i];
                final parts = t.version.split('.');
                final version =
                    parts.length >= 2 ? '${parts[0]}.${parts[1]}' : t.version;
                return Card(
                  child: ListTile(
                    leading:
                        CircleAvatar(backgroundColor: colorFromHex(t.defaultColor)),
                    title: Text(t.name),
                    subtitle: Text(
                        '${t.category ?? 'Без категории'} • ${t.hands.length} рук • v$version'),
                    onTap: () async {
                      final create = await showDialog<bool>(
                        context: context,
                        builder: (_) => TemplatePreviewDialog(template: t),
                      );
                      if (create == true && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  CreatePackFromTemplateScreen(template: t)),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      actions: [SyncStatusIcon.of(context)],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'importTemplateFab',
            onPressed: _importTemplate,
            child: const Icon(Icons.upload_file),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'createTemplateFab',
            onPressed: _createTemplate,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
