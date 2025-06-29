import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../plugins/plugin_loader.dart';
import '../../plugins/plugin_manager.dart';
import '../services/service_registry.dart';
import '../widgets/sync_status_widget.dart';

class PluginManagerScreen extends StatefulWidget {
  const PluginManagerScreen({super.key});

  @override
  State<PluginManagerScreen> createState() => _PluginManagerScreenState();
}

class _PluginManagerScreenState extends State<PluginManagerScreen> {
  Map<String, bool> _config = <String, bool>{};
  List<String> _files = <String>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loader = PluginLoader();
    final config = await loader.loadConfig();
    final dir = Directory(p.join((await getApplicationSupportDirectory()).path, 'plugins'));
    final files = <String>[];
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.dart')) {
          files.add(p.basename(entity.path));
        }
      }
    }
    setState(() {
      _config = Map<String, bool>.from(config);
      _files = files;
    });
  }

  Future<void> _save() async {
    final dir = Directory(p.join((await getApplicationSupportDirectory()).path, 'plugins'));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'plugin_config.json'));
    await file.writeAsString(jsonEncode(_config));
  }

  Future<void> _toggle(String file, bool value) async {
    setState(() => _config[file] = value);
    await _save();
  }

  Future<void> _reload() async {
    final registry = ServiceRegistry();
    final manager = PluginManager();
    final loader = PluginLoader();
    await loader.loadAll(registry, manager, context: context);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plugins reloaded')));
    }
  }

  Future<void> _reset() async {
    final dir = await getApplicationSupportDirectory();
    final config = File(p.join(dir.path, 'plugins', 'plugin_config.json'));
    final cache = File(p.join(dir.path, 'plugin_cache.json'));
    if (await config.exists()) await config.delete();
    if (await cache.exists()) await cache.delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plugin config reset')));
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Plugins'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                final enabled = _config[file] ?? true;
                return ListTile(
                  title: Text(file),
                  trailing: Switch(
                    value: enabled,
                    activeColor: accent,
                    onChanged: (v) => _toggle(file, v),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: _reload,
                  child: const Text('Reload Plugins'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _reset,
                  child: const Text('Reset Plugins'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
