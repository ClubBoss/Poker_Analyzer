import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/color_utils.dart';
import '../services/template_storage_service.dart';
import '../models/training_pack_template.dart';
import 'create_pack_from_template_screen.dart';

class TemplateLibraryScreen extends StatefulWidget {
  const TemplateLibraryScreen({super.key});

  @override
  State<TemplateLibraryScreen> createState() => _TemplateLibraryScreenState();
}

class _TemplateLibraryScreenState extends State<TemplateLibraryScreen> {
  static const _key = 'template_filter_game_type';
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _filter = prefs.getString(_key) ?? 'all');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Шаблоны')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
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
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CreatePackFromTemplateScreen(template: t)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
