import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';
import '../core/training/generation/yaml_reader.dart';
import '../core/training/generation/yaml_writer.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/yaml_pack_markdown_preview_service.dart';
import '../services/yaml_pack_validator_service.dart';
import '../services/yaml_pack_auto_fix_engine.dart';
import '../services/yaml_pack_formatter_service.dart';
import '../services/yaml_pack_history_service.dart';
import '../services/yaml_pack_exporter_service.dart';
import '../services/yaml_pack_changelog_service.dart';
import 'package:open_filex/open_filex.dart';
import '../widgets/markdown_preview_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class YamlLibraryPreviewScreen extends StatefulWidget {
  const YamlLibraryPreviewScreen({super.key});

  @override
  State<YamlLibraryPreviewScreen> createState() =>
      _YamlLibraryPreviewScreenState();
}

class _YamlLibraryPreviewScreenState extends State<YamlLibraryPreviewScreen> {
  final List<File> _files = [];
  final Map<String, bool> _outdated = {};
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
    _outdated.clear();
    for (final f in list) {
      var outdated = false;
      try {
        final yaml = await f.readAsString();
        final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
        final map = const YamlReader().read(yaml);
        final v = tpl.meta['schemaVersion']?.toString();
        outdated = _versionLess(v, '2.0.0');
      } catch (_) {}
      _outdated[f.path] = outdated;
    }
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
      final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
      md = const YamlPackMarkdownPreviewService().generateMarkdownPreview(tpl);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _selected = index;
      _markdown = md;
    });
    _mdCtrl.jumpTo(0);
  }

  Future<void> _validate(File file) async {
    try {
      final yaml = await file.readAsString();
      final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
      final report = const YamlPackValidatorService().validate(tpl);
      if (!mounted) return;
      final msg = report.errors.isEmpty && report.warnings.isEmpty
          ? 'OK'
          : 'Ошибки: ${report.errors.length} \u2022 Предупреждения: ${report.warnings.length}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ошибка')));
      }
    }
  }

  Future<void> _autoFix(File file) async {
    try {
      final yaml = await file.readAsString();
      final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
      final map = const YamlReader().read(yaml);
      await const YamlPackHistoryService().saveSnapshot(tpl, 'fix');
      final fixed = const YamlPackAutoFixEngine().autoFix(tpl);
      const service = YamlPackHistoryService();
      service.addChangeLog(fixed, 'fix', 'editor', 'auto');
      await const YamlWriter().write(fixed.toJson(), file.path);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Готово')));
        if (_selected >= 0 && _files[_selected].path == file.path) {
          _markdown = const YamlPackMarkdownPreviewService()
              .generateMarkdownPreview(fixed);
          await _load();
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ошибка')));
      }
    }
  }

  Future<void> _formatYaml(File file) async {
    try {
      final yaml = await file.readAsString();
      final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
      final map = const YamlReader().read(yaml);
      await const YamlPackHistoryService().saveSnapshot(tpl, 'format');
      const service = YamlPackHistoryService();
      service.addChangeLog(tpl, 'format', 'editor', 'format');
      final formatted = const YamlPackFormatterService().format(tpl);
      final outMap = const YamlReader().read(formatted);
      await const YamlWriter().write(outMap, file.path);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Готово')));
        if (_selected >= 0 && _files[_selected].path == file.path) {
          _markdown = const YamlPackMarkdownPreviewService()
              .generateMarkdownPreview(tpl);
          await _load();
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ошибка')));
      }
    }
  }

  Future<void> _previewMarkdown(File file) async {
    try {
      final yaml = await file.readAsString();
      final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
      final map = const YamlReader().read(yaml);
      final md =
          const YamlPackMarkdownPreviewService().generateMarkdownPreview(tpl);
      if (md != null && mounted) {
        await showMarkdownPreviewDialog(context, md);
      }
    } catch (_) {}
  }

  Future<void> _showHistory(File file) async {
    try {
      final yaml = await file.readAsString();
      final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
      final md = await const YamlPackChangelogService().loadChangeLog(tpl.id);
      if (!mounted) return;
      if (md == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('История изменений отсутствует')));
      } else {
        await showMarkdownPreviewDialog(context, md);
      }
    } catch (_) {}
  }

  Future<void> _export(File file) async {
    final format = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('YAML'),
              onTap: () => Navigator.pop(context, 'yaml'),
            ),
            ListTile(
              title: const Text('Markdown'),
              onTap: () => Navigator.pop(context, 'markdown'),
            ),
            ListTile(
              title: const Text('Text'),
              onTap: () => Navigator.pop(context, 'plain'),
            ),
          ],
        ),
      ),
    );
    if (format == null) return;
    final fileOut =
        await const YamlPackExporterService().exportToTextFile(file, format);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Файл сохранён: ${fileOut.path}'),
        action: SnackBarAction(
          label: '📂 Открыть',
          onPressed: () => OpenFilex.open(fileOut.path),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mdCtrl.dispose();
    super.dispose();
  }

  bool _versionLess(String? v, String target) {
    if (v == null || v.isEmpty) return true;
    final a = v.split('.').map(int.parse).toList();
    final b = target.split('.').map(int.parse).toList();
    while (a.length < 3) {
      a.add(0);
    }
    while (b.length < 3) {
      b.add(0);
    }
    for (var i = 0; i < 3; i++) {
      if (a[i] < b[i]) return true;
      if (a[i] > b[i]) return false;
    }
    return false;
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
                    final outdated = _outdated[f.path] == true;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          selected: i == _selected,
                          title: Text(name),
                          subtitle: Text(date),
                          trailing: outdated
                              ? const Text(
                                  '⚠ Устаревшая схема',
                                  style: TextStyle(color: Colors.amber),
                                )
                              : null,
                          onTap: () => _select(f, i),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                tooltip: 'Проверить',
                                icon: const Icon(Icons.check),
                                onPressed: () => _validate(f),
                              ),
                              IconButton(
                                tooltip: 'Автофикс',
                                icon: const Icon(Icons.build),
                                onPressed: () => _autoFix(f),
                              ),
                              IconButton(
                                tooltip: 'Формат',
                                icon: const Icon(Icons.straighten),
                                onPressed: () => _formatYaml(f),
                              ),
                              IconButton(
                                tooltip: 'MD',
                                icon: const Icon(Icons.description),
                                onPressed: () => _previewMarkdown(f),
                              ),
                              IconButton(
                                tooltip: 'Экспорт',
                                icon: const Icon(Icons.download),
                                onPressed: () => _export(f),
                              ),
                              IconButton(
                                tooltip: 'История',
                                icon: const Icon(Icons.history),
                                onPressed: () => _showHistory(f),
                              ),
                            ],
                          ),
                        ),
                      ],
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
