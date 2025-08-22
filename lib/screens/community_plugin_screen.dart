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
  final String? category;
  final double? rating;
  const CommunityPlugin({
    required this.name,
    required this.url,
    required this.version,
    this.checksum,
    this.description,
    this.category,
    this.rating,
  });
  factory CommunityPlugin.fromJson(Map<String, dynamic> json) {
    return CommunityPlugin(
      name: json['name'] as String,
      url: json['url'] as String,
      version: json['version'] as String,
      checksum: json['checksum'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
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
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _categoryFilter = 'All';
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse(_url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          _plugins = [
            for (final e in data)
              CommunityPlugin.fromJson(e as Map<String, dynamic>),
          ];
          _categories =
              _plugins
                  .map((e) => e.category)
                  .whereType<String>()
                  .toSet()
                  .toList()
                ..sort();
        }
      }
      _status = await PluginManager().loadStatus();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _install(CommunityPlugin p) async {
    try {
      final downloaded = await PluginLoader().downloadFromUrl(
        p.url,
        checksum: p.checksum,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              downloaded ? 'Plugin installed' : 'Plugin up to date',
            ),
          ),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Install failed: $e')));
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Search...',
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () => setState(() {
                                      _searchCtrl.clear();
                                      _query = '';
                                    }),
                                  ),
                          ),
                          onChanged: (v) =>
                              setState(() => _query = v.trim().toLowerCase()),
                        ),
                      ),
                      if (_categories.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _categoryFilter,
                          dropdownColor: const Color(0xFF2A2B2E),
                          onChanged: (v) =>
                              setState(() => _categoryFilter = v ?? 'All'),
                          items: ['All', ..._categories]
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _filtered().length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final plugin = _filtered()[index];
                      final file = p.basename(Uri.parse(plugin.url).path);
                      final localVersion = _status[file]?['version'] as String?;
                      final installed = localVersion != null;
                      final needsUpdate =
                          installed && localVersion != plugin.version;
                      final subtitle = <Widget>[];
                      if (plugin.category != null) {
                        subtitle.add(Text(plugin.category!));
                      }
                      subtitle.add(Text('v${plugin.version}'));
                      if (plugin.rating != null) {
                        subtitle.add(
                          Row(
                            children: [
                              for (var i = 0; i < plugin.rating!.round(); i++)
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                            ],
                          ),
                        );
                      }
                      if (plugin.description != null) {
                        subtitle.add(Text(plugin.description!));
                      }
                      if (needsUpdate) {
                        subtitle.add(
                          Text(
                            'Installed v$localVersion',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      return ListTile(
                        title: Text(plugin.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: subtitle,
                        ),
                        trailing: TextButton(
                          onPressed: installed && !needsUpdate
                              ? null
                              : () => _install(plugin),
                          child: Text(
                            needsUpdate
                                ? 'Update'
                                : installed
                                ? 'Installed'
                                : 'Install',
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

  List<CommunityPlugin> _filtered() {
    return [
      for (final p in _plugins)
        if ((_categoryFilter == 'All' || p.category == _categoryFilter) &&
            (_query.isEmpty ||
                p.name.toLowerCase().contains(_query) ||
                (p.description?.toLowerCase().contains(_query) ?? false)))
          p,
    ];
  }
}
