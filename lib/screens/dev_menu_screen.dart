import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../core/training/generation/gpt_pack_template_generator.dart';
import '../core/training/generation/pack_yaml_config_parser.dart';
import '../core/training/engine/training_type_engine.dart';
import '../services/tag_service.dart';
import '../services/pack_batch_generator_service.dart';
import '../ui/tools/training_pack_yaml_previewer.dart';
import '../services/training_coverage_service.dart';
import '../services/yaml_validation_service.dart';
import '../services/pack_library_import_service.dart';
import '../services/pack_library_export_service.dart';
import '../services/pack_library_duplicate_cleaner.dart';
import '../services/pack_library_merge_service.dart';
import '../services/pack_library_refactor_service.dart';
import '../services/training_pack_ranking_engine.dart';
import '../services/tag_health_check_service.dart';
import 'yaml_library_preview_screen.dart';
import 'pack_library_health_screen.dart';
import 'pack_library_stats_screen.dart';
import 'pack_library_conflicts_screen.dart';

class DevMenuScreen extends StatefulWidget {
  const DevMenuScreen({super.key});

  @override
  State<DevMenuScreen> createState() => _DevMenuScreenState();
}

class _DevMenuScreenState extends State<DevMenuScreen> {
  bool _loading = false;
  bool _batchLoading = false;
  bool _libraryLoading = false;
  bool _importLoading = false;
  bool _exportLoading = false;
  bool _cleanLoading = false;
  bool _mergeLoading = false;
  bool _refactorLoading = false;
  bool _rankLoading = false;
  bool _tagHealthLoading = false;
  static const _basePrompt = 'Создай тренировочный YAML пак';
  static const _apiKey = '';
  String _audience = 'Beginner';
  final Set<String> _tags = {};

  String get _prompt {
    final tagStr = _tags.join(', ');
    return '${_basePrompt} для audience: ${_audience}, tags: ${tagStr}, формат: 10 BB турниры.';
  }

  Future<void> _selectTags() async {
    final tags = context.read<TagService>().tags.toSet();
    final local = Set<String>.from(_tags);
    final res = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121212),
          title: const Text('Выбор тегов'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 300,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final t in tags)
                      CheckboxListTile(
                        value: local.contains(t),
                        title: Text(t),
                        activeColor: Colors.greenAccent,
                        onChanged: (v) {
                          setStateDialog(() {
                            if (v ?? false) {
                              local.add(t);
                            } else {
                              local.remove(t);
                            }
                          });
                        },
                      ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, local),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (res != null) {
      setState(() {
        _tags
          ..clear()
          ..addAll(res);
      });
    }
  }

  Future<void> _createPack() async {
    setState(() => _loading = true);
    final gpt = GptPackTemplateGenerator(apiKey: _apiKey);
    final yaml = await gpt.generateYamlTemplate(_prompt);
    setState(() => _loading = false);
    if (!mounted || yaml.isEmpty) return;
    try {
      final config = const PackYamlConfigParser().parse(yaml);
      if (config.requests.isNotEmpty) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final custom = Directory('${dir.path}/training_packs/custom');
          await custom.create(recursive: true);
          final ts = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
          final file = File('${custom.path}/pack_$ts.yaml');
          await file.writeAsString(yaml);
          if (mounted) {
            final name = file.path.split(Platform.pathSeparator).last;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Файл сохранён: $name')));
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Ошибка сохранения')));
          }
        }
        final tpl = await TrainingTypeEngine().build(
          TrainingType.pushfold,
          config.requests.first,
        );
        await showTrainingPackYamlPreviewer(context, tpl);
        return;
      }
    } catch (_) {}
    final ctr = TextEditingController(text: yaml);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        content: TextField(
          controller: ctr,
          readOnly: true,
          maxLines: null,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: ctr.text));
              Navigator.pop(context);
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateYamlBatch(
    List<(String audience, List<String> tags)> items,
  ) async {
    if (_batchLoading) return;
    setState(() => _batchLoading = true);
    final total = items.length.clamp(0, 10);
    var success = 0;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var started = false;
        var progress = 0.0;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                final gpt = GptPackTemplateGenerator(apiKey: _apiKey);
                final parser = const PackYamlConfigParser();
                final dir = await getApplicationDocumentsDirectory();
                final custom = Directory('${dir.path}/training_packs/custom');
                await custom.create(recursive: true);
                for (var i = 0; i < total; i++) {
                  final item = items[i];
                  final tags = item.$2.length > 5
                      ? item.$2.sublist(0, 5)
                      : List<String>.from(item.$2);
                  final tagStr = tags.join(', ');
                  final prompt =
                      '$_basePrompt для audience: ${item.$1}, tags: $tagStr, формат: 10 BB турниры';
                  final yaml = await gpt.generateYamlTemplate(prompt);
                  if (yaml.isNotEmpty) {
                    try {
                      final cfg = parser.parse(yaml);
                      if (cfg.requests.isNotEmpty) {
                        final ts = DateFormat(
                          'yyyyMMdd_HHmm',
                        ).format(DateTime.now());
                        final safeA = item.$1.replaceAll(' ', '_');
                        final safeT = tags.isNotEmpty
                            ? tags.first.replaceAll(' ', '_')
                            : 'pack';
                        final file = File(
                          '${custom.path}/pack_${safeA}_${safeT}_$ts.yaml',
                        );
                        await file.writeAsString(yaml);
                        success++;
                      }
                    } catch (_) {}
                  }
                  setStateDialog(() {
                    progress = (i + 1) / total;
                  });
                }
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return AlertDialog(
              backgroundColor: const Color(0xFF121212),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 16),
                  Text(
                    '$success / $total',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Готово: $success / $total')));
    }
    setState(() => _batchLoading = false);
  }

  Future<void> _generatePackLibrary() async {
    if (_libraryLoading || !kDebugMode) return;
    setState(() => _libraryLoading = true);
    final gpt = GptPackTemplateGenerator(apiKey: _apiKey);
    final service = PackBatchGeneratorService(gpt: gpt);
    try {
      final count = await service.generateFullLibrary([
        ('Beginner', ['pushfold']),
        ('Intermediate', ['call']),
        ('Advanced', ['icm']),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count паков сгенерировано')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('ошибка')));
      }
    }
    if (mounted) setState(() => _libraryLoading = false);
  }

  Future<void> _importPacks() async {
    if (_importLoading || !kDebugMode) return;
    setState(() => _importLoading = true);
    final res = await const PackLibraryImportService().importFromExternalDir();
    if (!mounted) return;
    setState(() => _importLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Импортировано: ${res.success}, ошибок: ${res.failed}')),
    );
  }

  Future<void> _exportCoverage() async {
    if (!kDebugMode) return;
    final ok = await compute(_coverageTask, '');
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Готово' : 'Ошибка')));
  }

  Future<void> _validateYaml() async {
    if (!kDebugMode) return;
    final errors = await compute(_validateYamlTask, '');
    if (!mounted) return;
    if (errors.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ошибок нет')));
      return;
    }
    final text = errors.map((e) => '${e.$1}: ${e.$2}').join('\n');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        content: SingleChildScrollView(
          child: Text(text, style: const TextStyle(color: Colors.white)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportLibrary() async {
    if (_exportLoading || !kDebugMode) return;
    setState(() => _exportLoading = true);
    final count = await const PackLibraryExportService().exportAll();
    if (!mounted) return;
    setState(() => _exportLoading = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Экспортировано: $count')));
  }

  Future<void> _cleanDuplicates() async {
    if (_cleanLoading || !kDebugMode) return;
    setState(() => _cleanLoading = true);
    final count = await const PackLibraryDuplicateCleaner().removeDuplicates();
    if (!mounted) return;
    setState(() => _cleanLoading = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Удалено: $count')));
  }

  Future<void> _mergeLibraries() async {
    if (_mergeLoading || !kDebugMode) return;
    setState(() => _mergeLoading = true);
    final res = await const PackLibraryMergeService().mergeAll(
      ['/import_a', '/import_b'],
    );
    if (!mounted) return;
    setState(() => _mergeLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Объединено: ${res.success}, ошибок: ${res.failed}')),
    );
  }

  Future<void> _refactorLibrary() async {
    if (_refactorLoading || !kDebugMode) return;
    setState(() => _refactorLoading = true);
    final count = await const PackLibraryRefactorService().refactorAll();
    if (!mounted) return;
    setState(() => _refactorLoading = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Отрефакторено: $count')));
  }

  Future<void> _recalcRanking() async {
    if (_rankLoading || !kDebugMode) return;
    setState(() => _rankLoading = true);
    final count = await compute(_rankTask, '');
    if (!mounted) return;
    setState(() => _rankLoading = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Пересчитано: $count')));
  }

  Future<void> _checkTagHealth() async {
    if (_tagHealthLoading || !kDebugMode) return;
    setState(() => _tagHealthLoading = true);
    final ok = await compute(_tagHealthTask, '');
    if (!mounted) return;
    setState(() => _tagHealthLoading = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? 'Готово' : 'Ошибка')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dev Menu')),
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _audience,
              decoration: const InputDecoration(labelText: 'Audience'),
              items: const [
                DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
                DropdownMenuItem(
                  value: 'Intermediate',
                  child: Text('Intermediate'),
                ),
                DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
              ],
              onChanged: (v) => setState(() => _audience = v ?? _audience),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _selectTags,
              child: Text(
                _tags.isEmpty ? 'Выбрать теги' : 'Теги: ${_tags.join(', ')}',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _createPack,
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(),
                    )
                  : const Text('Создать тренировку (GPT)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _batchLoading
                  ? null
                  : () => _generateYamlBatch([(_audience, _tags.toList())]),
              child: _batchLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(),
                    )
                  : const Text('Сгенерировать партию (GPT)'),
            ),
            if (kDebugMode)
              ListTile(
                title: const Text('🔁 Генерировать библиотеку паков'),
                onTap: _libraryLoading ? null : _generatePackLibrary,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📊 Покрытие тем (coverage_report.json)'),
                onTap: _exportCoverage,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('Проверка YAML'),
                onTap: _validateYaml,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('⬇ Импортировать паки из /import'),
                onTap: _importLoading ? null : _importPacks,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📤 Экспортировать библиотеку'),
                onTap: _exportLoading ? null : _exportLibrary,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🧹 Очистить дубликаты'),
                onTap: _cleanLoading ? null : _cleanDuplicates,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('♻️ Автоочистка и улучшения'),
                onTap: _refactorLoading ? null : _refactorLibrary,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🏅 Пересчитать рейтинг паков'),
                onTap: _rankLoading ? null : _recalcRanking,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📦 Объединить библиотеки'),
                onTap: _mergeLoading ? null : _mergeLibraries,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📋 Проверка библиотеки'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PackLibraryHealthScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📂 Просмотр YAML паков'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const YamlLibraryPreviewScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📈 Статистика библиотеки'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PackLibraryStatsScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🔍 Проверка качества тегов'),
                onTap: _tagHealthLoading ? null : _checkTagHealth,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🚨 Конфликты библиотеки'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PackLibraryConflictsScreen(),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _coverageTask(String _) async {
  try {
    await const TrainingCoverageService().exportCoverageReport();
    return true;
  } catch (_) {
    return false;
  }
}

Future<List<(String, String)>> _validateYamlTask(String _) async {
  return const YamlValidationService().validateAll();
}

Future<int> _rankTask(String _) async {
  return const TrainingPackRankingEngine().computeRankings();
}

Future<bool> _tagHealthTask(String _) async {
  try {
    await const TagHealthCheckService().runChecks();
    return true;
  } catch (_) {
    return false;
  }
}
