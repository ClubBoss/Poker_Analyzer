import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/training_pack_template_model.dart';
import '../services/training_pack_template_storage_service.dart';
import '../services/training_spot_storage_service.dart';
import 'training_pack_template_editor_screen.dart';

class TrainingPackTemplateListScreen extends StatefulWidget {
  const TrainingPackTemplateListScreen({super.key});

  @override
  State<TrainingPackTemplateListScreen> createState() => _TrainingPackTemplateListScreenState();
}

class _TrainingPackTemplateListScreenState
    extends State<TrainingPackTemplateListScreen> {
  final Map<String, int?> _counts = {};
  final TextEditingController _searchController = TextEditingController();
  late TrainingSpotStorageService _spotStorage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _spotStorage = context.read<TrainingSpotStorageService>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _ensureCount(String id, Map<String, dynamic> filters) {
    if (_counts.containsKey(id)) return;
    _counts[id] = null;
    _spotStorage.evaluateFilterCount(filters).then((value) {
      if (mounted) setState(() => _counts[id] = value);
    });
  }
  Future<void> _add() async {
    final model = await Navigator.push<TrainingPackTemplateModel>(
      context,
      MaterialPageRoute(builder: (_) => const TrainingPackTemplateEditorScreen()),
    );
    if (model != null && mounted) {
      await context.read<TrainingPackTemplateStorageService>().add(model);
    }
  }

  Future<void> _export() async {
    final service = context.read<TrainingPackTemplateStorageService>();
    try {
      final dir =
          await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/training_pack_templates.json');
      await file.writeAsString(
        jsonEncode([for (final t in service.templates) t.toJson()]),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл экспортирован в Загрузки')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Ошибка экспорта')),
        );
      }
    }
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    final service = context.read<TrainingPackTemplateStorageService>();
    bool ok = true;
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is List) {
        final list = <TrainingPackTemplateModel>[];
        for (final e in decoded) {
          if (e is Map<String, dynamic>) {
            try {
              list.add(TrainingPackTemplateModel.fromJson(e));
            } catch (_) {}
          }
        }
        service.merge(list);
        await service.saveAll();
      } else {
        ok = false;
      }
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Шаблоны импортированы' : '⚠️ Ошибка импорта'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<TrainingPackTemplateStorageService>().templates;
    final query = _searchController.text.toLowerCase();
    final templates = query.isEmpty
        ? all
        : [
            for (final t in all)
              if (t.name.toLowerCase().contains(query) ||
                  t.category.toLowerCase().contains(query))
                t
          ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Шаблоны паков'),
        actions: [
          IconButton(onPressed: _export, icon: const Icon(Icons.upload_file)),
          IconButton(onPressed: _import, icon: const Icon(Icons.download)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Поиск…'),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: templates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: templates.length,
              itemBuilder: (context, i) {
                final t = templates[i];
                _ensureCount(t.id, t.filters);
                return Dismissible(
                  key: ValueKey(t.id),
                  confirmDismiss: (_) async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Удалить шаблон?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Отмена'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Удалить'),
                          ),
                        ],
                      ),
                    );
                    return ok == true;
                  },
                  onDismissed: (_) =>
                      context.read<TrainingPackTemplateStorageService>().remove(t),
                  child: ListTile(
                    onTap: () async {
                      final model = await Navigator.push<TrainingPackTemplateModel>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => TrainingPackTemplateEditorScreen(initial: t)),
                      );
                      if (model != null && mounted) {
                        await context
                            .read<TrainingPackTemplateStorageService>()
                            .update(model);
                      }
                    },
                    title: Text(t.name),
                    subtitle: Text(
                      _counts[t.id] == null
                          ? 'Невозможно оценить'
                          : '≈ ${_counts[t.id]} рук',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (_) {
                        _spotStorage.activeFilters
                          ..clear()
                          ..addAll(t.filters);
                        _spotStorage.notifyListeners();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Шаблон применён')));
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'apply', child: Text('Применить шаблон')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
