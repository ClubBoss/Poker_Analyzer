import 'dart:io';
import 'dart:convert';

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
import '../services/pack_library_generation_engine.dart';
import '../services/yaml_pack_duplicate_cleaner_service.dart';
import '../services/pack_library_merge_service.dart';
import '../services/yaml_pack_merge_engine.dart';
import '../services/pack_library_refactor_service.dart';
import '../services/training_pack_ranking_engine.dart';
import '../services/training_pack_rating_engine.dart';
import '../services/tag_health_check_service.dart';
import '../services/pack_library_refactor_engine.dart';
import '../services/pack_tag_index_service.dart';
import '../services/auto_tag_generator_service.dart';
import '../services/tag_suggestion_engine.dart';
import '../services/smart_tag_suggestor.dart';
import '../services/training_pack_filter_engine.dart';
import '../services/smart_pack_recommendation_engine.dart';
import '../services/training_pack_suggestion_service.dart';
import '../services/smart_suggestion_engine.dart';
import '../services/yaml_pack_balance_analyzer.dart';
import '../services/pack_library_loader_service.dart';
import '../services/pack_dependency_map.dart';
import '../services/training_goal_suggestion_engine.dart';
import '../services/smart_goal_recommender_service.dart';
import '../services/session_log_service.dart';
import '../services/tag_mastery_service.dart';
import '../services/training_pack_generator_v2.dart';
import '../models/training_attempt.dart';
import '../services/weakness_cluster_engine_v2.dart';
import '../services/goal_completion_engine.dart';
import '../services/pack_library_review_engine.dart';
import '../services/yaml_pack_auto_fix_engine.dart';
import '../services/pack_library_smart_validator.dart';
import '../services/pack_library_validator_service.dart';
import '../services/training_pack_template_validator.dart';
import '../services/training_pack_template_storage.dart';
import '../services/pack_search_engine.dart';
import '../services/pack_library_index_loader.dart';
import '../models/validation_issue.dart';
import '../models/yaml_pack_review_report.dart';
import '../models/yaml_pack_validation_report.dart';
import '../models/pack_rating_report.dart';
import '../models/smart_validation_result.dart';
import '../services/yaml_pack_refactor_engine.dart';
import '../services/pack_validation_engine.dart';
import '../services/yaml_pack_validator_service.dart';
import '../services/pack_template_refactor_engine.dart';
import '../services/training_reminder_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pack_balance_issue.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../core/training/generation/yaml_reader.dart';
import '../core/training/generation/yaml_writer.dart';
import 'package:file_picker/file_picker.dart';
import 'pack_matrix_config_editor_screen.dart';
import 'yaml_library_preview_screen.dart';
import 'yaml_pack_quick_preview_screen.dart';
import 'yaml_pack_previewer_screen.dart';
import 'yaml_pack_editor_screen.dart';
import 'pack_library_health_screen.dart';
import 'pack_library_stats_screen.dart';
import '../services/smart_stage_unlock_engine.dart';
import '../services/learning_path_service.dart';
import '../services/smart_spot_injector.dart';
import '../services/learning_path_engine.dart';
import '../services/learning_path_stage_seeder.dart';
import 'pack_filter_debug_screen.dart';
import 'pack_library_conflicts_screen.dart';
import 'pack_suggestion_preview_screen.dart';
import 'yaml_coverage_stats_screen.dart';
import 'pack_coverage_stats_screen.dart';
import 'pack_library_qa_screen.dart';
import 'pack_conflict_analysis_screen.dart';
import 'pack_merge_duplicates_screen.dart';
import '../services/pack_library_rating_engine.dart';
import '../models/pack_library_rating_report.dart';
import '../services/yaml_pack_history_service.dart';
import 'yaml_pack_history_screen.dart';
import 'yaml_pack_archive_screen.dart';
import 'yaml_pack_archive_cleanup_screen.dart';
import 'yaml_pack_archive_stats_screen.dart';
import 'yaml_pack_archive_duplicates_screen.dart';
import 'yaml_pack_archive_validator_screen.dart';
import 'yaml_pack_validator_screen.dart';
import '../services/auto_advance_pack_engine.dart';
import '../services/training_session_service.dart';
import 'training_session_screen.dart';

import 'pack_tag_analyzer_screen.dart';

import 'pack_library_diff_screen.dart';
import 'pack_merge_explorer_screen.dart';
import 'tools/spot_duplication_wizard.dart';
import 'tag_matrix_coverage_screen.dart';
import 'skill_map_screen.dart';
import 'goal_screen.dart';
import 'goal_center_screen.dart';
import 'goal_insights_screen.dart';
import 'lesson_path_screen.dart';
import 'learning_path_screen.dart';
import 'learning_path_intro_screen.dart';
import '../services/learning_path_progress_service.dart';
import '../services/achievement_trigger_engine.dart';
import 'achievement_dashboard_screen.dart';
import 'achievements_dashboard_screen.dart';
import 'basic_achievements_screen.dart';
import 'mistake_review_screen.dart';
import 'mistake_insight_screen.dart';
import 'cluster_mistake_dashboard_screen.dart';
import '../services/lesson_path_reminder_scheduler.dart';
import '../services/lesson_streak_engine.dart';
import '../services/training_streak_tracker_service.dart';

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
  bool _yamlDupeLoading = false;
  bool _yamlAssetsDupeLoading = false;
  bool _mergeLoading = false;
  bool _yamlMergeLoading = false;
  bool _refactorLoading = false;
  bool _ratingLoading = false;
  bool _tagHealthLoading = false;
  bool _normalizeYamlLoading = false;
  bool _tagIndexLoading = false;
  bool _tagSuggestLoading = false;
  bool _yamlTagSuggestLoading = false;
  bool _templateTagSuggestLoading = false;
  bool _bestLoading = false;
  bool _historyLoading = false;
  bool _smartHistoryLoading = false;
  bool _goalLoading = false;
  bool _smartGoalLoading = false;
  bool _balanceLoading = false;
  bool _reviewLoading = false;
  bool _yamlCheckLoading = false;
  bool _validatePackLoading = false;
  bool _templateValidateLoading = false;
  bool _autoFixLoading = false;
  bool _refactorYamlPackLoading = false;
  bool _ratePackLoading = false;
  bool _libraryValidateLoading = false;
  bool _libraryRatingLoading = false;
  bool _recommendPacksLoading = false;
  bool _jsonLibraryLoading = false;
  bool _smartValidateLoading = false;
  bool _weaknessYamlLoading = false;
  bool _templateStorageTestLoading = false;
  bool _packSearchLoading = false;
  bool _reminderLoading = false;
  bool _progressExportLoading = false;
  bool _progressImportLoading = false;
  bool _trainingStreakExportLoading = false;
  bool _autoAdvanceLoading = false;
  bool _seedBeginnerLoading = false;
  bool _seedFullPathLoading = false;
  bool _unlockStages = false;
  bool _smartMode = false;
  bool _injectWeakSpots = false;
  bool _smartRecoveryStage = false;
  bool _showCompletedGoals = false;
  bool _achievementsCheckLoading = false;
  int _lessonStreak = 0;
  StreamSubscription<int>? _lessonSub;
  static const _basePrompt = 'Создай тренировочный YAML пак';
  static const _apiKey = '';
  String _audience = 'Beginner';
  final Set<String> _tags = {};

  @override
  void initState() {
    super.initState();
    _loadStreak();
    _lessonSub = LessonStreakEngine.instance.streakStream.listen(
      (v) => setState(() => _lessonStreak = v),
    );
  }

  Future<void> _loadStreak() async {
    final s = await LessonStreakEngine.instance.getCurrentStreak();
    if (mounted) setState(() => _lessonStreak = s);
  }

  @override
  void dispose() {
    _lessonSub?.cancel();
    super.dispose();
  }

  String get _prompt {
    final tagStr = _tags.join(', ');
    return '$_basePrompt для audience: $_audience, tags: $tagStr, формат: 10 BB турниры.';
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
          TrainingType.pushFold,
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
                const parser = PackYamlConfigParser();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$count паков сгенерировано')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ошибка')));
      }
    }
    if (mounted) setState(() => _libraryLoading = false);
  }

  Future<void> _generateJsonLibrary() async {
    if (_jsonLibraryLoading || !kDebugMode) return;
    setState(() => _jsonLibraryLoading = true);
    final docs = await getApplicationDocumentsDirectory();
    await const PackLibraryGenerationEngine().generate(
      inputDir: '${docs.path}/training_packs/library',
      outputPath: 'assets/packs/v2/library_index.json',
      audience: _audience,
      tags: _tags.toList(),
    );
    if (!mounted) return;
    setState(() => _jsonLibraryLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Готово')));
  }

  Future<void> _importPacks() async {
    if (_importLoading || !kDebugMode) return;
    setState(() => _importLoading = true);
    final res = await const PackLibraryImportService().importFromExternalDir();
    if (!mounted) return;
    setState(() => _importLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Импортировано: ${res.success}, ошибок: ${res.failed}'),
      ),
    );
  }

  Future<void> _exportCoverage() async {
    if (!kDebugMode) return;
    final ok = await compute(_coverageTask, '');
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(ok ? 'Готово' : 'Ошибка')));
  }

  Future<void> _validateYaml() async {
    if (!kDebugMode) return;
    final errors = await compute(_validateYamlTask, '');
    if (!mounted) return;
    if (errors.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ошибок нет')));
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Экспортировано: $count')));
  }

  Future<void> _cleanDuplicates() async {
    if (_cleanLoading || !kDebugMode) return;
    setState(() => _cleanLoading = true);
    final count = await const PackLibraryDuplicateCleaner().removeDuplicates();
    if (!mounted) return;
    setState(() => _cleanLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Удалено: $count')));
  }

  Future<void> _removeYamlDuplicates() async {
    if (_yamlDupeLoading || !kDebugMode) return;
    setState(() => _yamlDupeLoading = true);
    final list =
        await const YamlPackDuplicateCleanerService().removeDuplicates();
    if (!mounted) return;
    setState(() => _yamlDupeLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Удалено: ${list.length}')));
  }

  Future<void> _cleanYamlPackAssets() async {
    if (_yamlAssetsDupeLoading || !kDebugMode) return;
    setState(() => _yamlAssetsDupeLoading = true);
    final count = await const PackLibraryDuplicateCleaner().clean(
      'assets/packs',
    );
    if (!mounted) return;
    setState(() => _yamlAssetsDupeLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Удалено: $count')));
  }

  Future<void> _mergeLibraries() async {
    if (_mergeLoading || !kDebugMode) return;
    setState(() => _mergeLoading = true);
    final res = await const PackLibraryMergeService().mergeAll([
      '/import_a',
      '/import_b',
    ]);
    if (!mounted) return;
    setState(() => _mergeLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Объединено: ${res.success}, ошибок: ${res.failed}'),
      ),
    );
  }

  Future<void> _mergeYamlPacks() async {
    if (_yamlMergeLoading || !kDebugMode) return;
    setState(() => _yamlMergeLoading = true);
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
    );
    final packs = <TrainingPackTemplateV2>[];
    if (result != null && result.files.isNotEmpty) {
      const reader = YamlReader();
      for (final f in result.files) {
        final path = f.path;
        if (path == null) continue;
        try {
          final map = reader.read(await File(path).readAsString());
          packs.add(
            TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map)),
          );
        } catch (_) {}
      }
    }
    if (!mounted) return;
    setState(() => _yamlMergeLoading = false);
    if (packs.isEmpty) return;
    final merged = const YamlPackMergeEngine().merge(packs);
    await showTrainingPackYamlPreviewer(context, merged);
    if (!mounted) return;
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save YAML',
      fileName: '${merged.id}.yaml',
      type: FileType.custom,
      allowedExtensions: ['yaml'],
    );
    if (savePath == null) return;
    await const YamlWriter().write(merged.toJson(), savePath);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Шаблон сохранён')));
  }

  Future<void> _refactorLibrary() async {
    if (_refactorLoading || !kDebugMode) return;
    setState(() => _refactorLoading = true);
    final count = await const PackLibraryRefactorService().refactorAll();
    if (!mounted) return;
    setState(() => _refactorLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Отрефакторено: $count')));
  }

  Future<void> _normalizeYamlLibrary() async {
    if (_normalizeYamlLoading || !kDebugMode) return;
    setState(() => _normalizeYamlLoading = true);
    await const PackLibraryRefactorEngine().refactorAll(
      'training_packs/library',
    );
    if (!mounted) return;
    setState(() => _normalizeYamlLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Готово')));
  }

  Future<void> _recalcRating() async {
    if (_ratingLoading || !kDebugMode) return;
    setState(() => _ratingLoading = true);
    final count = await compute(_ratingTask, '');
    if (!mounted) return;
    setState(() => _ratingLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Пересчитано: $count')));
  }

  Future<void> _rateLibrary() async {
    if (_libraryRatingLoading || !kDebugMode) return;
    setState(() => _libraryRatingLoading = true);
    await PackLibraryLoaderService.instance.loadLibrary();
    final packs = PackLibraryLoaderService.instance.library;
    final report = await const PackLibraryRatingEngine().rateLibrary(packs);
    if (!mounted) return;
    setState(() => _libraryRatingLoading = false);
    final text = report.topRatedPacks.map((e) => '${e.$1}: ${e.$2}').join('\n');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Рейтинг библиотеки'),
        content: SingleChildScrollView(child: Text(text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _validateLibrary() async {
    if (_libraryValidateLoading || !kDebugMode) return;
    setState(() => _libraryValidateLoading = true);
    final data = await compute(_validateLibraryTask, _audience);
    if (!mounted) return;
    setState(() => _libraryValidateLoading = false);
    if (data.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ошибок нет')));
      return;
    }
    final text = data.map((e) => '${e.$1}: ${e.$2}').join('\n');
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

  Future<void> _generateWeaknessYamlPack() async {
    if (_weaknessYamlLoading || !kDebugMode) return;
    setState(() => _weaknessYamlLoading = true);
    final logs = context.read<SessionLogService>();
    await logs.load();
    final attempts = [
      for (final log in logs.logs)
        TrainingAttempt(
          packId: log.templateId,
          spotId: log.templateId,
          timestamp: log.completedAt,
          accuracy: (log.correctCount + log.mistakeCount) == 0
              ? 0
              : log.correctCount / (log.correctCount + log.mistakeCount),
          ev: 0,
          icm: 0,
        )
    ];
    await PackLibraryLoaderService.instance.loadLibrary();
    final packs = PackLibraryLoaderService.instance.library;
    final clusters = const WeaknessClusterEngine()
        .computeClusters(attempts: attempts, allPacks: packs);
    if (clusters.isEmpty) {
      if (mounted) setState(() => _weaknessYamlLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No weakness detected')),
        );
      }
      return;
    }
    final mastery = await context.read<TagMasteryService>().computeMastery();
    final generator = TrainingPackGeneratorV2();
    final pack = await generator.generateFromWeakness(
      cluster: clusters.first,
      mastery: mastery,
    );
    if (!mounted) return;
    setState(() => _weaknessYamlLoading = false);
    await showTrainingPackYamlPreviewer(context, pack);
  }

  Future<void> _checkTagHealth() async {
    if (_tagHealthLoading || !kDebugMode) return;
    setState(() => _tagHealthLoading = true);
    final ok = await compute(_tagHealthTask, '');
    if (!mounted) return;
    setState(() => _tagHealthLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(ok ? 'Готово' : 'Ошибка')));
  }

  Future<void> _buildTagIndex() async {
    if (_tagIndexLoading || !kDebugMode) return;
    setState(() => _tagIndexLoading = true);
    final count = await compute(_tagIndexTask, '');
    if (!mounted) return;
    setState(() => _tagIndexLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Индекс: $count')));
  }

  Future<void> _suggestTags() async {
    if (_tagSuggestLoading || !kDebugMode) return;
    setState(() => _tagSuggestLoading = true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
    );
    List<String> tags = [];
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null) tags = await compute(_suggestTagsTask, path);
    }
    if (!mounted) return;
    setState(() => _tagSuggestLoading = false);
    if (tags.isEmpty) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Рекомендованные теги'),
        content: Text(tags.join(', ')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _suggestYamlPackTags() async {
    if (_yamlTagSuggestLoading || !kDebugMode) return;
    setState(() => _yamlTagSuggestLoading = true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
    );
    List<String> tags = [];
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null) tags = await compute(_yamlTagSuggestionTask, path);
    }
    if (!mounted) return;
    setState(() => _yamlTagSuggestLoading = false);
    if (tags.isEmpty) return;
    final ctr = TextEditingController(text: tags.join(', '));
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Рекомендованные теги'),
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

  Future<void> _suggestTemplateTags() async {
    if (_templateTagSuggestLoading || !kDebugMode) return;
    setState(() => _templateTagSuggestLoading = true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
    );
    List<(String, double)> tags = [];
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null) {
        tags = await compute(_templateTagSuggestionTask, path);
      }
    }
    if (!mounted) return;
    setState(() => _templateTagSuggestLoading = false);
    if (tags.isEmpty) return;
    final text = tags.map((e) => '${e.\$1}: ${e.\$2.toStringAsFixed(2)}').join('\n');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Рекомендации тегов'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeBalance() async {
    if (_balanceLoading || !kDebugMode) return;
    setState(() => _balanceLoading = true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
    );
    List<PackBalanceIssue> items = [];
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null) {
        final data = await compute(_balanceTask, path);
        items = [for (final j in data) PackBalanceIssue.fromJson(j)];
      }
    }
    if (!mounted) return;
    setState(() => _balanceLoading = false);
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Баланс OK')));
      return;
    }
    final text = items.map((e) => '${e.type}: ${e.description}').join('\n');
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

  Future<void> _validateYamlPack() async {
    if (_validatePackLoading || !kDebugMode) return;
    setState(() => _validatePackLoading = true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
    );
    YamlPackValidationReport? report;
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null) {
        final data = await compute(_validatePackTask, path);
        report = YamlPackValidationReport.fromJson(data);
      }
    }
    if (!mounted) return;
    setState(() => _validatePackLoading = false);
    if (report == null) return;
    final text = [
      if (report.errors.isNotEmpty) 'Errors:\n${report.errors.join('\n')}',
      if (report.warnings.isNotEmpty)
        'Warnings:\n${report.warnings.join('\n')}',
    ].join('\n\n');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        content: SingleChildScrollView(
          child: Text(
            text.isEmpty ? 'OK' : text,
            style: const TextStyle(color: Colors.white),
          ),
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

  Future<void> _checkYamlPack() async {
    if (_yamlCheckLoading || !kDebugMode) return;
    setState(() => _yamlCheckLoading = true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
    );
    YamlPackValidationReport? report;
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null) {
        final data = await compute(_checkPackTask, path);
        report = YamlPackValidationReport.fromJson(data);
      }
    }
    if (!mounted) return;
    setState(() => _yamlCheckLoading = false);
    if (report == null) return;
    final text = [
      if (report.errors.isNotEmpty) 'Errors:\n${report.errors.join('\n')}',
      if (report.warnings.isNotEmpty)
        'Warnings:\n${report.warnings.join('\n')}',
    ].join('\n\n');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        content: SingleChildScrollView(
          child: Text(
            text.isEmpty ? 'OK' : text,
            style: const TextStyle(color: Colors.white),
          ),
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

  Future<void> _validateYamlTemplate() async {
    if (_templateValidateLoading || !kDebugMode) return;
    setState(() => _templateValidateLoading = true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
    );
    List<ValidationIssue> items = [];
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null) {
        final data = await compute(_validateTemplateTask, path);
        items = [for (final j in data) ValidationIssue.fromJson(j)];
      }
    }
    if (!mounted) return;
    setState(() => _templateValidateLoading = false);
    final text = items.isEmpty
        ? 'OK'
        : items.map((e) => '${e.type}: ${e.message}').join('\n');
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

  Future<void> _reviewYamlPack() async {
    if (_reviewLoading || !kDebugMode) return;
    setState(() => _reviewLoading = true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
    );
    YamlPackReviewReport? report;
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null) {
        final data = await compute(_reviewTask, path);
        report = YamlPackReviewReport.fromJson(data);
      }
    }
    if (!mounted) return;
    setState(() => _reviewLoading = false);
    if (report == null) return;
    final text = [
      if (report.warnings.isNotEmpty)
        'Warnings:\n${report.warnings.join('\n')}',
      if (report.suggestions.isNotEmpty)
        'Suggestions:\n${report.suggestions.join('\n')}',
    ].join('\n\n');
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

  Future<void> _autoFixYamlPack() async {
    if (_autoFixLoading || !kDebugMode) return;
    setState(() => _autoFixLoading = true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
    );
    Map<String, dynamic>? json;
    String? path;
    if (result != null && result.files.isNotEmpty) {
      path = result.files.single.path;
      if (path != null) {
        final raw = await File(path).readAsString();
        final map = const YamlReader().read(raw);
        final tpl = TrainingPackTemplateV2.fromJson(
          Map<String, dynamic>.from(map),
        );
        await const YamlPackHistoryService().saveSnapshot(tpl, 'fix');
        json = await compute(_autoFixTask, path);
      }
    }
    if (!mounted) return;
    setState(() => _autoFixLoading = false);
    if (json == null || json.isEmpty || path == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ошибка')));
      return;
    }
    final pack = TrainingPackTemplateV2.fromJson(json);
    await showTrainingPackYamlPreviewer(context, pack);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Сохранить?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Да'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await const YamlWriter().write(json, path);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Готово')));
    }
  }

  Future<void> _refactorYamlPack() async {
    if (_refactorYamlPackLoading || !kDebugMode) return;
    setState(() => _refactorYamlPackLoading = true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
    );
    Map<String, dynamic>? json;
    String? path;
    if (result != null && result.files.isNotEmpty) {
      path = result.files.single.path;
      if (path != null) json = await compute(_refactorYamlPackTask, path);
    }
    if (!mounted) return;
    setState(() => _refactorYamlPackLoading = false);
    if (json == null || json.isEmpty || path == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ошибка')));
      return;
    }
    final pack = TrainingPackTemplateV2.fromJson(json);
    await showTrainingPackYamlPreviewer(context, pack);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Сохранить?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Да'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await const YamlWriter().write(json, path);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Шаблон сохранён')));
    }
  }

  Future<void> _rateYamlPack() async {
    if (_ratePackLoading || !kDebugMode) return;
    setState(() => _ratePackLoading = true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
    );
    PackRatingReport? report;
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null) {
        final data = await compute(_ratePackTask, path);
        report = PackRatingReport.fromJson(data);
      }
    }
    if (!mounted) return;
    setState(() => _ratePackLoading = false);
    if (report == null) return;
    final text = [
      'Score: ${report.score}',
      if (report.warnings.isNotEmpty)
        'Warnings:\n${report.warnings.join('\n')}',
      if (report.insights.isNotEmpty)
        'Insights:\n${report.insights.join('\n')}',
    ].join('\n\n');
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

  Future<void> _smartValidateYamlPack() async {
    if (_smartValidateLoading || !kDebugMode) return;
    setState(() => _smartValidateLoading = true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
    );
    SmartValidationResult? report;
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null) {
        final data = await compute(_smartValidateTask, path);
        report = SmartValidationResult.fromJson(data);
      }
    }
    if (!mounted) return;
    setState(() => _smartValidateLoading = false);
    if (report == null) return;
    const text =
        'Errors: \${report.before.errors.length}->\${report.after.errors.length}\n'
        'Warnings: \${report.before.warnings.length}->\${report.after.warnings.length}\n'
        'Fixed: \${report.fixed.length}';
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(text)));
  }

  Future<void> _selectBestPacks() async {
    if (_bestLoading || !kDebugMode) return;
    setState(() => _bestLoading = true);
    final list = await const TrainingPackFilterEngine().filter(minRating: 80);
    if (!mounted) return;
    setState(() => _bestLoading = false);
    if (list.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Нет паков')));
      return;
    }
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Лучшие паки'),
        content: SingleChildScrollView(
          child: Text(list.map((e) => e.name).join('\n')),
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

  Future<void> _recommendPacks() async {
    if (_recommendPacksLoading || !kDebugMode) return;
    setState(() => _recommendPacksLoading = true);
    await PackLibraryLoaderService.instance.loadLibrary();
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs
        .getKeys()
        .where(
          (k) => k.startsWith('completed_tpl_') && prefs.getBool(k) == true,
        )
        .map((k) => k.substring('completed_tpl_'.length))
        .toSet();
    final profile = UserProfile(
      completedPackIds: completed,
      tags: _tags.toList(),
    );
    final list = const SmartPackRecommendationEngine().recommend(
      profile,
      PackLibraryLoaderService.instance.library,
    );
    if (!mounted) return;
    setState(() => _recommendPacksLoading = false);
    if (list.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Нет рекомендаций')));
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PackSuggestionPreviewScreen(packs: list),
      ),
    );
  }

  Future<void> _suggestNext() async {
    if (_historyLoading || !kDebugMode) return;
    setState(() => _historyLoading = true);
    final service = context.read<TrainingPackSuggestionService>();
    final list = await service.suggestNext(userId: 'local');
    if (!mounted) return;
    setState(() => _historyLoading = false);
    if (list.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Нет рекомендаций')));
      return;
    }
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Следующие паки'),
        content: SingleChildScrollView(
          child: Text(list.map((e) => e.name).join('\n')),
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

  Future<void> _smartSuggestNext() async {
    if (_smartHistoryLoading || !kDebugMode) return;
    setState(() => _smartHistoryLoading = true);
    final engine = context.read<SmartSuggestionEngine>();
    final list = await engine.suggestNextPacks();
    if (!mounted) return;
    setState(() => _smartHistoryLoading = false);
    if (list.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Нет рекомендаций')));
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PackSuggestionPreviewScreen(packs: list),
      ),
    );
  }

  Future<void> _suggestGoals() async {
    if (_goalLoading || !kDebugMode) return;
    setState(() => _goalLoading = true);
    await PackLibraryLoaderService.instance.loadLibrary();
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs
        .getKeys()
        .where(
          (k) => k.startsWith('completed_tpl_') && prefs.getBool(k) == true,
        )
        .map((k) => k.substring('completed_tpl_'.length))
        .toSet();
    final profile = UserProfile(
      completedPackIds: completed,
      tags: _tags.toList(),
    );
    final packs = PackLibraryLoaderService.instance.library;
    final goals = const TrainingGoalSuggestionEngine().suggest(profile, packs);
    if (!mounted) return;
    setState(() => _goalLoading = false);
    if (goals.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Нет целей')));
      return;
    }
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Цели'),
        content: SingleChildScrollView(
          child: Text(goals.map((e) => e.title).join('\n')),
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

  Future<void> _generateSmartGoals() async {
    if (_smartGoalLoading || !kDebugMode) return;
    setState(() => _smartGoalLoading = true);
    await PackLibraryIndexLoader.instance.load();
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs
        .getKeys()
        .where(
          (k) => k.startsWith('completed_tpl_') && prefs.getBool(k) == true,
        )
        .map((k) => k.substring('completed_tpl_'.length))
        .toSet();
    final profile = UserProfile(
      completedPackIds: completed,
      tags: _tags.toList(),
    );
    final service = SmartGoalRecommenderService(
      mastery: context.read<TagMasteryService>(),
      logs: context.read<SessionLogService>(),
    );
    final goals = await service.recommendGoals(profile);
    if (!mounted) return;
    setState(() => _smartGoalLoading = false);
    if (goals.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Нет целей')));
      return;
    }
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Умные цели'),
        content: SingleChildScrollView(
          child: Text(goals.map((e) => e.title).join('\n')),
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

  Future<void> _testTemplateStorage() async {
    if (_templateStorageTestLoading || !kDebugMode) return;
    setState(() => _templateStorageTestLoading = true);
    final storage = TrainingPackTemplateStorage();
    final tpl = TrainingPackTemplateV2(
      id: 'test_tpl',
      name: 'Test Template',
      trainingType: TrainingType.pushFold,
    );
    await storage.saveLocal(tpl);
    await storage.saveRemote(tpl);
    final local = await storage.loadLocal(tpl.id);
    final remote = await storage.loadRemote(tpl.id);
    if (!mounted) return;
    setState(() => _templateStorageTestLoading = false);
    final ok = local != null && remote != null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Template roundtrip OK' : 'Storage failed')),
    );
  }

  Future<void> _testPackSearchEngine() async {
    if (_packSearchLoading || !kDebugMode) return;
    setState(() => _packSearchLoading = true);
    await PackLibraryIndexLoader.instance.load();
    final ctr = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Search query'),
        content: TextField(controller: ctr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctr.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    const engine = PackSearchEngine();
    final results = engine.search(query ?? '');
    setState(() => _packSearchLoading = false);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Results'),
        content: SingleChildScrollView(
          child: Text(results.isEmpty
              ? 'No results'
              : results.map((e) => e.name).join('\n')),
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

  Future<void> _checkTrainingReminder() async {
    if (_reminderLoading || !kDebugMode) return;
    setState(() => _reminderLoading = true);
    final engine = TrainingReminderEngine(
      logs: context.read<SessionLogService>(),
    );
    final remind = await engine.shouldRemind(const UserProfile());
    if (!mounted) return;
    setState(() => _reminderLoading = false);
    final text = remind ? 'Пора потренироваться!' : 'Напоминание не требуется';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _sendTestLessonPathReminder() async {
    await LessonPathReminderScheduler.instance.sendTestReminder();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder sent')),
      );
    }
  }

  Future<void> _exportLearningProgress() async {
    if (_progressExportLoading || !kDebugMode) return;
    setState(() => _progressExportLoading = true);
    final data = await LearningPathProgressService.instance.exportProgress();
    await Clipboard.setData(ClipboardData(text: jsonEncode(data)));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Прогресс скопирован в буфер')),
      );
    }
    setState(() => _progressExportLoading = false);
  }

  Future<void> _importLearningProgress() async {
    if (_progressImportLoading || !kDebugMode) return;
    setState(() => _progressImportLoading = true);
    try {
      final raw = await Clipboard.getData('text/plain');
      final text = raw?.text;
      if (text != null && text.isNotEmpty) {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) {
          await LearningPathProgressService.instance.importProgress(decoded);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Прогресс импортирован')),
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Import failed: $e');
    }
    if (mounted) setState(() => _progressImportLoading = false);
  }

  Future<void> _exportTrainingStreak() async {
    if (_trainingStreakExportLoading || !kDebugMode) return;
    setState(() => _trainingStreakExportLoading = true);
    final data = await TrainingStreakTrackerService.instance.exportData();
    await Clipboard.setData(ClipboardData(text: jsonEncode(data)));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Training streak copied to clipboard')),
      );
    }
    setState(() => _trainingStreakExportLoading = false);
  }

  Future<void> _autoAdvancePack() async {
    if (_autoAdvanceLoading || !kDebugMode) return;
    setState(() => _autoAdvanceLoading = true);
    final tpl = await AutoAdvancePackEngine.instance.getNextRecommendedPack();
    if (!mounted) return;
    setState(() => _autoAdvanceLoading = false);
    if (tpl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Путь завершен')),
      );
      return;
    }
    await context.read<TrainingSessionService>().startSession(tpl);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }

  Future<void> _forceCheckAchievements() async {
    if (_achievementsCheckLoading || !kDebugMode) return;
    setState(() => _achievementsCheckLoading = true);
    await AchievementTriggerEngine.instance.checkAndTriggerAchievements();
    if (!mounted) return;
    setState(() => _achievementsCheckLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Achievements checked')),
    );
  }

  Future<void> _seedBeginnerPath() async {
    if (_seedBeginnerLoading || !kDebugMode) return;
    setState(() => _seedBeginnerLoading = true);
    try {
      final raw = await rootBundle
          .loadString('assets/learning_paths/beginner_path.yaml');
      final map = const YamlReader().read(raw);
      final paths = [for (final p in (map['packs'] as List? ?? [])) p.toString()];
      await const LearningPathStageSeeder().seedStages(
        paths,
        audience: 'Beginner',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beginner path seeded')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seed failed')),
        );
      }
    }
    if (mounted) setState(() => _seedBeginnerLoading = false);
  }

  Future<void> _seedFullPathFromConfig() async {
    if (_seedFullPathLoading || !kDebugMode) return;
    setState(() => _seedFullPathLoading = true);
    try {
      await const LearningPathStageSeeder()
          .seedFromConfig(audience: _audience);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Full path seeded')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seed failed')),
        );
      }
    }
    if (mounted) setState(() => _seedFullPathLoading = false);
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
                title: const Text('📦 Сгенерировать библиотеку паков'),
                onTap: _jsonLibraryLoading ? null : _generateJsonLibrary,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📊 Покрытие тем (coverage_report.json)'),
                onTap: _exportCoverage,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📊 Покрытие YAML'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const YamlCoverageStatsScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📊 Pack Coverage Stats'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PackCoverageStatsScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🔧 Generate weakness-based YAML pack'),
                onTap:
                    _weaknessYamlLoading ? null : _generateWeaknessYamlPack,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('Проверка YAML'),
                onTap: _validateYaml,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('✅ Проверить YAML пак'),
                onTap: _validatePackLoading ? null : _validateYamlPack,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🔍 Проверка YAML пака'),
                onTap: _yamlCheckLoading ? null : _checkYamlPack,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('✅ Валидация YAML пака'),
                onTap: _templateValidateLoading ? null : _validateYamlTemplate,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('✅ Smart Validation YAML пака'),
                onTap: _smartValidateLoading ? null : _smartValidateYamlPack,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📋 Проверить YAML пак'),
                onTap: _reviewLoading ? null : _reviewYamlPack,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🛠 Автоисправление YAML пака'),
                onTap: _autoFixLoading ? null : _autoFixYamlPack,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🧹 Рефакторинг YAML пака'),
                onTap: _refactorYamlPackLoading ? null : _refactorYamlPack,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📈 Оценить YAML пак'),
                onTap: _ratePackLoading ? null : _rateYamlPack,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🔍 Анализ пака на баланс'),
                onTap: _balanceLoading ? null : _analyzeBalance,
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
                title: const Text('🧹 Удалить дубликаты паков'),
                onTap: _yamlDupeLoading ? null : _removeYamlDuplicates,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🧽 Удалить дубликаты YAML паков'),
                onTap: _yamlAssetsDupeLoading ? null : _cleanYamlPackAssets,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🧹 Рефакторинг библиотеки'),
                onTap: _refactorLoading ? null : _refactorLibrary,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🧹 Нормализовать YAML библиотеку'),
                onTap: _normalizeYamlLoading ? null : _normalizeYamlLibrary,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🏅 Пересчитать рейтинг паков'),
                onTap: _ratingLoading ? null : _recalcRating,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('⭐️ Рейтинг библиотеки'),
                onTap: _libraryRatingLoading ? null : _rateLibrary,
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
                title: const Text('🔍 Validate Pack Library'),
                onTap: _libraryValidateLoading ? null : _validateLibrary,
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
                title: const Text('👁 Предпросмотр YAML пака'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const YamlPackPreviewerScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📦 Быстрый просмотр YAML'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const YamlPackQuickPreviewScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📂 История паков'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const YamlPackHistoryScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🗄️ Архив паков'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const YamlPackArchiveScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🧹 Очистить архив паков'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const YamlPackArchiveCleanupScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📊 Статистика архива YAML-паков'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const YamlPackArchiveStatsScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📁 Дубликаты архивов'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const YamlPackArchiveDuplicatesScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🧪 Валидатор YAML-паков'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const YamlPackArchiveValidatorScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🧪 YAML Pack Validator'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const YamlPackValidatorScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📝 Редактор YAML пака'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const YamlPackEditorScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📦 Pack Library Diff Viewer'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PackLibraryDiffScreen(),
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
                title: const Text('📇 Построить индекс тегов'),
                onTap: _tagIndexLoading ? null : _buildTagIndex,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📦 Pack Tag Analyzer'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PackTagAnalyzerScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🎯 Редактор матрицы тегов'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PackMatrixConfigEditorScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🕵️ Tag Matrix Coverage'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TagMatrixCoverageScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🧪 Открыть Skill Map'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SkillMapScreen()),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📎 Предложить теги'),
                onTap: _tagSuggestLoading ? null : _suggestTags,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('💡 Предложить теги для YAML пака'),
                onTap: _yamlTagSuggestLoading ? null : _suggestYamlPackTags,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🧠 Suggest Tags for Template'),
                onTap:
                    _templateTagSuggestLoading ? null : _suggestTemplateTags,
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
            if (kDebugMode)
              ListTile(
                title: const Text('🧩 Анализ конфликтов'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PackConflictAnalysisScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📂 Pack Merge Explorer'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PackMergeExplorerScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🗂 Spot Duplication Wizard'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SpotDuplicationWizard(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🧬 Объединение дубликатов'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PackMergeDuplicatesScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🧬 Объединить YAML паки'),
                onTap: _yamlMergeLoading ? null : _mergeYamlPacks,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🧪 QA библиотеки'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PackLibraryQAScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🔎 Фильтр паков'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PackFilterDebugScreen(),
                    ),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🏆 Отбор лучших паков'),
                onTap: _bestLoading ? null : _selectBestPacks,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🔮 Рекомендовать паки'),
                onTap: _recommendPacksLoading ? null : _recommendPacks,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📦 Рекомендованные паки'),
                onTap: _recommendPacksLoading ? null : _recommendPacks,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📈 Следующие паки по истории'),
                onTap: _historyLoading ? null : _suggestNext,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🧠 Следующее по истории'),
                onTap: _smartHistoryLoading ? null : _smartSuggestNext,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📌 Цели по истории'),
                onTap: _goalLoading ? null : _suggestGoals,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🎯 Сгенерировать умные цели'),
                onTap: _smartGoalLoading ? null : _generateSmartGoals,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🎯 Цели'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GoalScreen()),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🎯 Goal Center'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GoalCenterScreen()),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🧪 Тест выгрузки/загрузки шаблона'),
                onTap:
                    _templateStorageTestLoading ? null : _testTemplateStorage,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📚 Lesson Path'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LessonPathScreen()),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📚 Путь обучения'),
                onTap: () async {
                  final seen =
                      await LearningPathProgressService.instance.hasSeenIntro();
                  final screen = seen
                      ? const LearningPathScreen()
                      : const LearningPathIntroScreen();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => screen),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🎯 Следующий обучающий пак'),
                onTap: _autoAdvanceLoading ? null : _autoAdvancePack,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📚 Learning Path Demo (mock)'),
                onTap: () async {
                  final service = LearningPathProgressService.instance;
                  service.mock = true;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LearningPathScreen()),
                  );
                  service.mock = false;
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🏆 Achievement Dashboard'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AchievementDashboardScreen()),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🎖 Basic Achievements'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AchievementsScreen()),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🏅 История достижений'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AchievementsDashboardScreen()),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📈 Статистика целей'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const GoalInsightsScreen()),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🎖 Принудительно проверить достижения'),
                onTap:
                    _achievementsCheckLoading ? null : _forceCheckAchievements,
              ),
            if (kDebugMode)
              CheckboxListTile(
                title: const Text('🔓 Unlock all stages (for dev)'),
                value: _unlockStages,
                activeColor: Colors.greenAccent,
                onChanged: (v) {
                  setState(() => _unlockStages = v ?? false);
                  LearningPathProgressService.instance.unlockAllStages =
                      _unlockStages;
                },
              ),
            if (kDebugMode)
              CheckboxListTile(
                title: const Text('🤖 Smart Mode'),
                value: _smartMode,
                activeColor: Colors.greenAccent,
                onChanged: (v) {
                  setState(() => _smartMode = v ?? false);
                  LearningPathService.instance.smartMode = _smartMode;
                },
              ),
            if (kDebugMode)
              CheckboxListTile(
                title:
                    const Text('Inject weakness spots at start of training'),
                value: _injectWeakSpots,
                activeColor: Colors.greenAccent,
                onChanged: (v) {
                  setState(() => _injectWeakSpots = v ?? false);
                  SmartSpotInjector.instance.enabled = _injectWeakSpots;
                },
              ),
            if (kDebugMode)
              CheckboxListTile(
                title: const Text('🧠 Enable smart recovery stage'),
                value: _smartRecoveryStage,
                activeColor: Colors.greenAccent,
                onChanged: (v) {
                  setState(() => _smartRecoveryStage = v ?? false);
                  LearningPathEngine.smartRecoveryEnabled = _smartRecoveryStage;
                },
              ),
            if (kDebugMode)
              CheckboxListTile(
                title: const Text('🎯 Show completed goals'),
                value: _showCompletedGoals,
                activeColor: Colors.greenAccent,
                onChanged: (v) {
                  setState(() => _showCompletedGoals = v ?? false);
                  GoalCompletionEngine.instance.showCompletedGoals =
                      _showCompletedGoals;
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🔓 Принудительно открыть следующую стадию'),
                onTap: () async {
                  await SmartStageUnlockEngine.instance.forceUnlockNextStage();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Next stage unlocked')),
                    );
                  }
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🧹 Сбросить интро обучения'),
                onTap: () async {
                  await LearningPathProgressService.instance.resetIntroSeen();
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🧹 Сбросить кастомный путь'),
                onTap: () async {
                  await LearningPathProgressService.instance.resetCustomPath();
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('⚙️ Seed Beginner Path'),
                onTap: _seedBeginnerLoading ? null : _seedBeginnerPath,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('⚙️ Seed Full Path from Config'),
                onTap: _seedFullPathLoading ? null : _seedFullPathFromConfig,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📤 Экспорт прогресса'),
                onTap: _progressExportLoading ? null : _exportLearningProgress,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📥 Импорт прогресса из буфера'),
                onTap: _progressImportLoading ? null : _importLearningProgress,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📊 Export Training Streak'),
                onTap: _trainingStreakExportLoading ? null : _exportTrainingStreak,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🔄 Пересчитать доступные паки'),
                onTap: () async {
                  await PackDependencyMap.instance.recalc();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Паки пересчитаны')));
                  }
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🔔 Проверить напоминание'),
                onTap: _reminderLoading ? null : _checkTrainingReminder,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('Send test reminder now'),
                onTap: _sendTestLessonPathReminder,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🔎 Test Pack Search Engine'),
                onTap: _packSearchLoading ? null : _testPackSearchEngine,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🔥 Стрик уроков: \$_lessonStreak'),
                onTap: _loadStreak,
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🧹 Сбросить streak уроков'),
                onTap: () async {
                  await LessonStreakEngine.instance.resetStreak();
                  await _loadStreak();
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('🔁 Повтор ошибок'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MistakeReviewScreen()),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📊 Аналитика ошибок'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MistakeInsightScreen()),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                title: const Text('📈 Cluster Mistakes Dashboard'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ClusterMistakeDashboardScreen()),
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

Future<int> _ratingTask(String _) async {
  return const TrainingPackRatingEngine().rateAll();
}

Future<bool> _tagHealthTask(String _) async {
  try {
    await const TagHealthCheckService().runChecks();
    return true;
  } catch (_) {
    return false;
  }
}

Future<int> _tagIndexTask(String _) async {
  return const PackTagIndexService().buildIndex();
}

Future<List<String>> _suggestTagsTask(String path) async {
  final file = File(path);
  if (!file.existsSync()) return [];
  final yaml = await file.readAsString();
  final map = const YamlReader().read(yaml);
  final tpl = TrainingPackTemplate.fromJson(map);
  return const AutoTagGeneratorService().generateTags(tpl);
}

Future<List<String>> _yamlTagSuggestionTask(String path) async {
  final file = File(path);
  if (!file.existsSync()) return [];
  final yaml = await file.readAsString();
  final map = const YamlReader().read(yaml);
  final tpl = TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
  return const TagSuggestionEngine().suggestTags(tpl);
}

Future<List<(String, double)>> _templateTagSuggestionTask(String path) async {
  final file = File(path);
  if (!file.existsSync()) return [];
  final yaml = await file.readAsString();
  final map = const YamlReader().read(yaml);
  final tpl = TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
  return const SmartTagSuggestor().suggestTags(tpl);
}

Future<List<Map<String, dynamic>>> _balanceTask(String path) async {
  final file = File(path);
  if (!file.existsSync()) return [];
  final yaml = await file.readAsString();
  final map = const YamlReader().read(yaml);
  final tpl = TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
  final issues = const YamlPackBalanceAnalyzer().analyze(tpl);
  return [for (final i in issues) i.toJson()];
}

Future<Map<String, dynamic>> _validatePackTask(String path) async {
  final file = File(path);
  if (!file.existsSync()) return const YamlPackValidationReport().toJson();
  final yaml = await file.readAsString();
  final map = const YamlReader().read(yaml);
  final tpl = TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
  final report = const PackValidationEngine().validate(tpl);
  return report.toJson();
}

Future<Map<String, dynamic>> _checkPackTask(String path) async {
  final file = File(path);
  if (!file.existsSync()) return const YamlPackValidationReport().toJson();
  final yaml = await file.readAsString();
  final map = const YamlReader().read(yaml);
  final tpl = TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
  final report = const YamlPackValidatorService().validate(tpl);
  return report.toJson();
}

Future<Map<String, dynamic>> _reviewTask(String path) async {
  final file = File(path);
  if (!file.existsSync()) return const YamlPackReviewReport().toJson();
  final yaml = await file.readAsString();
  final map = const YamlReader().read(yaml);
  final tpl = TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
  final report = const PackLibraryReviewEngine().review(tpl);
  return report.toJson();
}

Future<Map<String, dynamic>> _autoFixTask(String path) async {
  final file = File(path);
  if (!file.existsSync()) return {};
  final yaml = await file.readAsString();
  final map = const YamlReader().read(yaml);
  final tpl = TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
  final fixed = const YamlPackAutoFixEngine().autoFix(tpl);
  return fixed.toJson();
}

Future<Map<String, dynamic>> _refactorYamlPackTask(String path) async {
  final file = File(path);
  if (!file.existsSync()) return {};
  final yaml = await file.readAsString();
  final map = const YamlReader().read(yaml);
  final tpl = TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
  const engine = PackTemplateRefactorEngine();
  engine.refactor(tpl);
  return engine.orderedJson(tpl);
}

Future<Map<String, dynamic>> _ratePackTask(String path) async {
  final file = File(path);
  if (!file.existsSync()) return const PackRatingReport().toJson();
  final yaml = await file.readAsString();
  final map = const YamlReader().read(yaml);
  final tpl = TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
  final report = const TrainingPackRatingEngine().rate(tpl);
  return report.toJson();
}

Future<List<Map<String, dynamic>>> _validateTemplateTask(String path) async {
  final file = File(path);
  if (!file.existsSync()) return [];
  final yaml = await file.readAsString();
  final map = const YamlReader().read(yaml);
  final tpl = TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
  final issues = const TrainingPackTemplateValidator().validate(tpl);
  return [for (final i in issues) i.toJson()];
}

Future<Map<String, dynamic>> _smartValidateTask(String path) async {
  final result = await const PackLibrarySmartValidator().validateAndFix(path);
  return result.toJson();
}

Future<List<(String, String)>> _validateLibraryTask(String audience) async {
  return const PackLibraryValidatorService().validateAll(audience: audience);
}
