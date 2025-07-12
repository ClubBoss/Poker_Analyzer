import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../plugins/plugin_loader.dart';
import '../plugins/plugin_manager.dart';

class CommunityPlugin {
  final String name;
  final String url;
  final String version;
  final String? checksum;
  final String? description;
  const CommunityPlugin({
    required this.name,
    required this.url,
    required this.version,
    this.checksum,
    this.description,
  });
  factory CommunityPlugin.fromJson(Map<String, dynamic> json) {
    return CommunityPlugin(
      name: json['name'] as String,
      url: json['url'] as String,
      version: json['version'] as String,
      checksum: json['checksum'] as String?,
      description: json['description'] as String?,
    );
  }
}

class CommunityPluginScreen extends StatefulWidget {
  const CommunityPluginScreen({super.key});
  @override
  State<CommunityPluginScreen> createState() => _CommunityPluginScreenState();
}

class _CommunityPluginScreenState extends State<CommunityPluginScreen> {
  static const _url = 'https://pokeranalyzer.app/plugins.json';
  List<CommunityPlugin> _plugins = [];
  Map<String, Map<String, dynamic>> _status = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(Uri.parse(_url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          _plugins = [for (final e in data) CommunityPlugin.fromJson(e as Map<String, dynamic>)];
        }
      }
      _status = await PluginManager().loadStatus();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _install(CommunityPlugin p) async {
    try {
      final downloaded =
          await PluginLoader().downloadFromUrl(p.url, checksum: p.checksum);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(downloaded ? 'Plugin installed' : 'Plugin up to date')),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Install failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Community Plugins'),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.sync), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plugins.isEmpty
              ? const Center(child: Text('No plugins'))
              : ListView.separated(
                  itemCount: _plugins.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final plugin = _plugins[index];
                    final file = p.basename(Uri.parse(plugin.url).path);
                    final localVersion = _status[file]?['version'] as String?;
                    final installed = localVersion != null;
                    final needsUpdate = installed && localVersion != plugin.version;
                    final subtitle = <Widget>[Text('v${plugin.version}')];
                    if (plugin.description != null) subtitle.add(Text(plugin.description!));
                    if (needsUpdate)
                      subtitle.add(Text('Installed v$localVersion', style: const TextStyle(color: Colors.red)));
                    return ListTile(
                      title: Text(plugin.name),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: subtitle),
                      trailing: TextButton(
                        onPressed: installed && !needsUpdate ? null : () => _install(plugin),
                        child: Text(needsUpdate ? 'Update' : installed ? 'Installed' : 'Install'),
                      ),
                    );
                  },
                ),
    );
  }
}
