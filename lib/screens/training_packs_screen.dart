import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_pack.dart';
import '../services/training_pack_storage_service.dart';
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
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
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
