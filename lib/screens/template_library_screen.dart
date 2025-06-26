import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_pack_template.dart';
import '../services/template_storage_service.dart';

import 'create_template_screen.dart';
import 'template_hands_editor_screen.dart';
import 'create_pack_from_template_screen.dart';

class TemplateLibraryScreen extends StatefulWidget {
  const TemplateLibraryScreen({super.key});

  @override
  State<TemplateLibraryScreen> createState() => _TemplateLibraryScreenState();
}

class _TemplateLibraryScreenState extends State<TemplateLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _typeFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteTemplate(TrainingPackTemplate t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Удалить шаблон «${t.name}»?'),
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
    if (confirm == true) {
      final service = context.read<TemplateStorageService>();
      final index = service.templates.indexOf(t);
      service.removeTemplate(t);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Шаблон удалён'),
            action: SnackBarAction(
              label: 'Отмена',
              onPressed: () => service.restoreTemplate(t, index),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _importTemplate() async {
    await context.read<TemplateStorageService>().importTemplateFromFile(context);
  }

  Future<void> _createTemplate() async {
    final template = await Navigator.push<TrainingPackTemplate>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTemplateScreen()),
    );
    if (template != null) {
      context.read<TemplateStorageService>().addTemplate(template);
      if (template.hands.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Шаблон пуст — не забудьте добавить раздачи'),
            action: SnackBarAction(
              label: 'Добавить сейчас',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TemplateHandsEditorScreen(template: template),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = context.watch<TemplateStorageService>().templates;
    List<TrainingPackTemplate> visible = [...templates];
    visible.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (_typeFilter != 'All') {
      visible = [for (final t in visible) if (t.gameType == _typeFilter) t];
    }
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      visible = [
        for (final t in visible)
          if (t.name.toLowerCase().contains(query) ||
              t.description.toLowerCase().contains(query))
            t
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Шаблоны тренировок'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Поиск'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<String>(
              value: _typeFilter,
              underline: const SizedBox.shrink(),
              onChanged: (v) => setState(() => _typeFilter = v ?? 'All'),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('Все')),
                DropdownMenuItem(value: 'Tournament', child: Text('Tournament')),
                DropdownMenuItem(value: 'Cash Game', child: Text('Cash Game')),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? const Center(child: Text('Нет шаблонов'))
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final t = visible[index];
                      final versionParts = t.version.split('.');
                      final versionDisplay = versionParts.length >= 2
                          ? '${versionParts[0]}.${versionParts[1]}'
                          : t.version;
                      return ListTile(
                        leading: t.isBuiltIn ? const Text('📦') : null,
                        title: Text(t.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${t.gameType} • ${t.author.isEmpty ? 'anon' : t.author}'),
                            Text('${t.hands.length} раздач • v$versionDisplay • rev${t.revision}'),
                          ],
                        ),
                        trailing: IconButton(
                          tooltip: 'Мастер создания',
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CreatePackFromTemplateScreen(template: t),
                              ),
                            );
                          },
                        ),
                        onLongPress:
                            t.isBuiltIn ? null : () => _deleteTemplate(t),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'import',
            onPressed: _importTemplate,
            child: const Icon(Icons.upload),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: _createTemplate,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
