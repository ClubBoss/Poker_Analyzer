import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';
import 'yaml_viewer_screen.dart';

class YamlLibraryPreviewScreen extends StatefulWidget {
  const YamlLibraryPreviewScreen({super.key});

  @override
  State<YamlLibraryPreviewScreen> createState() => _YamlLibraryPreviewScreenState();
}

class _YamlLibraryPreviewScreenState extends State<YamlLibraryPreviewScreen> {
  final List<File> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dir = await getApplicationDocumentsDirectory();
    final libDir = Directory('${dir.path}/training_packs/library');
    final list = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'))
        .toList();
    list.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    if (mounted) {
      setState(() {
        _files
          ..clear()
          ..addAll(list);
        _loading = false;
      });
    }
  }

  Future<void> _open(File file) async {
    final yaml = await file.readAsString();
    final name = file.path.split(Platform.pathSeparator).last;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YamlViewerScreen(yamlText: yaml, title: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('YAML Library')),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (_, i) {
                final f = _files[i];
                final name = f.path.split(Platform.pathSeparator).last;
                final date = DateFormat('yyyy-MM-dd HH:mm').format(f.statSync().modified);
                return ListTile(
                  title: Text(name),
                  subtitle: Text(date),
                  onTap: () => _open(f),
                );
              },
            ),
    );
  }
}
