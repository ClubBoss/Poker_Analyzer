import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:poker_analyzer/plugins/plugin_loader.dart';
import 'package:poker_analyzer/plugins/plugin_manager.dart';
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
  Map<String, Map<String, dynamic>> _status = <String, Map<String, dynamic>>{};
  final TextEditingController _urlCtr = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _urlCtr.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final loader = PluginLoader();
    final config = await loader.loadConfig();
    final manager = PluginManager();
    final status = await manager.loadStatus();
    final dir = Directory(
      p.join((await getApplicationSupportDirectory()).path, 'plugins'),
    );
    final files = <String>[];
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.dart')) {
          files.add(p.basename(entity.path));
        }
      }
    }
    final rootDir = Directory('plugins');
    if (await rootDir.exists()) {
      await for (final entity in rootDir.list()) {
        if (entity is File && entity.path.endsWith('.dart')) {
          files.add(p.basename(entity.path));
        }
      }
    }
    setState(() {
      _config = Map<String, bool>.from(config);
      _files = files;
      _status = status.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)));
    });
  }

  Future<void> _save() async {
    final dir = Directory(
      p.join((await getApplicationSupportDirectory()).path, 'plugins'),
    );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Plugins reloaded')));
    }
    await _load();
  }

  Future<void> _reset() async {
    final dir = await getApplicationSupportDirectory();
    final config = File(p.join(dir.path, 'plugins', 'plugin_config.json'));
    final cache = File(p.join(dir.path, 'plugin_cache.json'));
    if (await config.exists()) await config.delete();
    if (await cache.exists()) await cache.delete();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Plugin config reset')));
    }
    await _load();
  }

  Future<void> _download() async {
    final url = _urlCtr.text.trim();
    if (url.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final controller = messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
            SizedBox(width: 16),
            Text('Downloading...'),
          ],
        ),
        duration: Duration(days: 1),
      ),
    );
    try {
      final downloaded = await PluginLoader().downloadFromUrl(url);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              downloaded ? 'Plugin downloaded' : 'Plugin up to date',
            ),
          ),
        );
      }
      _urlCtr.clear();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    } finally {
      controller.close();
    }
    await _load();
  }

  Future<void> _retry(String file) async {
    final loader = PluginLoader();
    final manager = PluginManager();
    final support = Directory(
      p.join((await getApplicationSupportDirectory()).path, 'plugins'),
    );
    File f = File(p.join(support.path, file));
    if (!await f.exists()) {
      f = File(p.join('plugins', file));
    }
    final plugin = await loader.loadFromFile(f, manager);
    if (plugin != null) {
      final registry = ServiceRegistry();
      manager.load(plugin);
      manager.initializeAll(registry);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Plugin loaded')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Plugin failed')));
      }
    }
    await _load();
  }

  Future<void> _delete(String file) async {
    await PluginLoader().delete(file);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Plugin deleted')));
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
                final info = _status[file];
                final status = info?['status'] as String?;
                final name = info?['name'] as String?;
                final desc = info?['description'] as String?;
                final version = info?['version'] as String?;
                final subtitleWidgets = <Widget>[];
                if (name != null) subtitleWidgets.add(Text(name));
                if (version != null) {
                  subtitleWidgets.add(Text('v$version'));
                }
                if (desc != null) subtitleWidgets.add(Text(desc));
                if (status != null && status != 'loaded') {
                  subtitleWidgets.add(
                    Text(status, style: const TextStyle(color: Colors.red)),
                  );
                }
                return ListTile(
                  title: Text(file),
                  subtitle: subtitleWidgets.isEmpty
                      ? null
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: subtitleWidgets,
                        ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status == 'failed' || status == 'duplicate')
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          color: accent,
                          onPressed: () => _retry(file),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: accent,
                        onPressed: () => _delete(file),
                      ),
                      Switch(
                        value: enabled,
                        activeColor: accent,
                        onChanged: (v) => _toggle(file, v),
                      ),
                    ],
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlCtr,
                        decoration: const InputDecoration(
                          hintText: 'Plugin URL',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _download,
                      child: const Text('Download'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
