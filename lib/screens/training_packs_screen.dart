import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_pack.dart';
import '../models/training_pack_template.dart';
import '../services/training_pack_storage_service.dart';
import '../services/template_storage_service.dart';
import 'training_pack_screen.dart';
import 'training_pack_comparison_screen.dart';

class TrainingPacksScreen extends StatefulWidget {
  const TrainingPacksScreen({super.key});

  @override
  State<TrainingPacksScreen> createState() => _TrainingPacksScreenState();
}

class _TrainingPacksScreenState extends State<TrainingPacksScreen> {
  static const _hideKey = 'hide_completed_packs';

  final TextEditingController _searchController = TextEditingController();

  bool _hideCompleted = false;
  String _typeFilter = 'All';
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _prefs = prefs;
      _hideCompleted = prefs.getBool(_hideKey) ?? false;
    });
  }

  Future<void> _toggleHideCompleted(bool value) async {
    setState(() => _hideCompleted = value);
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_hideKey, value);
  }

  Future<void> _createFromTemplate() async {
    final packService = context.read<TrainingPackStorageService>();
    final templateService = context.read<TemplateStorageService>();
    String type = 'Tournament';
    TrainingPackTemplate? selected;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final templates = [
            for (final t in templateService.templates
                .where((tpl) => tpl.gameType == type))
              t
          ];
          return AlertDialog(
            title: const Text('Шаблоны'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: type,
                    onChanged: (v) => setStateDialog(() => type = v ?? 'Tournament'),
                    items: const [
                      DropdownMenuItem(value: 'Tournament', child: Text('Tournament')),
                      DropdownMenuItem(value: 'Cash Game', child: Text('Cash Game')),
                    ],
                  ),
                  for (final t in templates)
                    ListTile(
                      title: Text(t.name),
                      subtitle: Text(
                          'v${t.version} • rev ${t.revision} • ${t.author.isEmpty ? "anon" : t.author}'),
                      onTap: () {
                        selected = t;
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (selected != null) {
      await packService.createFromTemplate(selected!);
    }
  }

  bool _isPackCompleted(TrainingPack pack) {
    final progress = _prefs?.getInt('training_progress_${pack.name}') ?? 0;
    return progress >= pack.hands.length;
  }

  @override
  Widget build(BuildContext context) {
    final packs = context.watch<TrainingPackStorageService>().packs;

    if (_prefs == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Тренировочные споты'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    List<TrainingPack> visible = _hideCompleted
        ? [for (final p in packs) if (!_isPackCompleted(p)) p]
        : packs;

    if (_typeFilter != 'All') {
      visible = [for (final p in visible) if (p.gameType == _typeFilter) p];
    }

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      visible = [
        for (final p in visible)
          if (p.name.toLowerCase().contains(query) ||
              p.description.toLowerCase().contains(query))
            p
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренировочные споты'),
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Скрыть завершённые'),
            value: _hideCompleted,
            onChanged: _toggleHideCompleted,
            activeColor: Colors.orange,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Поиск'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrainingPackComparisonScreen(),
                      ),
                    );
                  },
                  child: const Text('📊 Сравнить паки'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _createFromTemplate,
                  child: const Text('✚ Создать из шаблона'),
                ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? const Center(child: Text('Нет доступных пакетов'))
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final pack = visible[index];
                      final completed = _isPackCompleted(pack);
                      return ListTile(
                        leading: pack.isBuiltIn ? const Text('📦') : null,
                        title: Text(pack.name),
                        subtitle: Text(
                          pack.description.isEmpty
                              ? pack.gameType
                              : '${pack.description} • ${pack.gameType}',
                        ),
                        trailing: completed
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TrainingPackScreen(pack: pack),
                            ),
                          );
                          setState(() {});
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
