import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/yaml_pack_markdown_preview_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class YamlLibraryPreviewScreen extends StatefulWidget {
  const YamlLibraryPreviewScreen({super.key});

  @override
  State<YamlLibraryPreviewScreen> createState() => _YamlLibraryPreviewScreenState();
}

class _YamlLibraryPreviewScreenState extends State<YamlLibraryPreviewScreen> {
  final List<File> _files = [];
  bool _loading = true;
  int _selected = -1;
  String? _markdown;
  final ScrollController _mdCtrl = ScrollController();

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

  Future<void> _select(File file, int index) async {
    String? md;
    try {
      final yaml = await file.readAsString();
      final map = const YamlReader().read(yaml);
      final tpl = TrainingPackTemplateV2.fromJson(
        Map<String, dynamic>.from(map),
      );
      md = const YamlPackMarkdownPreviewService()
          .generateMarkdownPreview(tpl);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _selected = index;
      _markdown = md;
    });
    _mdCtrl.jumpTo(0);
  }

  @override
  void dispose() {
    _mdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('YAML Library')),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, c) {
                final list = ListView.builder(
                  itemCount: _files.length,
                  itemBuilder: (_, i) {
                    final f = _files[i];
                    final name = f.path.split(Platform.pathSeparator).last;
                    final date = DateFormat('yyyy-MM-dd HH:mm')
                        .format(f.statSync().modified);
                    return ListTile(
                      selected: i == _selected,
                      title: Text(name),
                      subtitle: Text(date),
                      onTap: () => _select(f, i),
                    );
                  },
                );
                final preview = Container(
                  color: AppColors.cardBackground,
                  padding: const EdgeInsets.all(16),
                  child: _markdown == null
                      ? const Text('Нет предпросмотра')
                      : Column(
                          children: [
                            Expanded(
                              child: Markdown(
                                data: _markdown!,
                                controller: _mdCtrl,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: _markdown!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Скопировано')),
                                  );
                                },
                                child: const Text('📋 Скопировать'),
                              ),
                            ),
                          ],
                        ),
                );
                if (c.maxWidth > 600) {
                  return Row(
                    children: [
                      Expanded(child: list),
                      SizedBox(width: 400, child: preview),
                    ],
                  );
                }
                return Column(
                  children: [
                    Expanded(child: list),
                    SizedBox(height: 300, child: preview),
                  ],
                );
              },
            ),
    );
  }
}
