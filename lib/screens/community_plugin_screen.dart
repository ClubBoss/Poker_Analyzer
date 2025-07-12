import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../plugins/plugin_loader.dart';

class CommunityPlugin {
  final String name;
  final String url;
  final String? checksum;
  final String? description;
  const CommunityPlugin({
    required this.name,
    required this.url,
    this.checksum,
    this.description,
  });
  factory CommunityPlugin.fromJson(Map<String, dynamic> json) {
    return CommunityPlugin(
      name: json['name'] as String,
      url: json['url'] as String,
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
                    final p = _plugins[index];
                    return ListTile(
                      title: Text(p.name),
                      subtitle: p.description == null ? null : Text(p.description!),
                      trailing: TextButton(
                        onPressed: () => _install(p),
                        child: const Text('Install'),
                      ),
                    );
                  },
                ),
    );
  }
}
