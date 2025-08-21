import 'dart:convert';
import 'dart:io';

import '../utils/app_logger.dart';
import 'training_pack_auto_generator.dart';
import 'training_pack_template_registry_service.dart';

/// Represents a scheduled autogeneration job.
class ScheduledAutogenJob {
  final String templateId;
  final String target;
  DateTime? lastRun;

  ScheduledAutogenJob({
    required this.templateId,
    required this.target,
    this.lastRun,
  });

  factory ScheduledAutogenJob.fromJson(Map<String, dynamic> json) =>
      ScheduledAutogenJob(
        templateId: json['templateId']?.toString() ?? '',
        target: json['target']?.toString() ?? 'custom_schedule',
        lastRun: json['lastRun'] != null
            ? DateTime.tryParse(json['lastRun'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'target': target,
        'lastRun': lastRun?.toUtc().toIso8601String(),
      };
}

/// Service that schedules automatic training pack generation jobs.
class AutoPackGenerationSchedulerService {
  final String _filePath;
  final TrainingPackAutoGenerator _generator;
  final TrainingPackTemplateRegistryService _registry;

  AutoPackGenerationSchedulerService({
    String filePath = 'scheduledJobs.json',
    TrainingPackAutoGenerator? generator,
    TrainingPackTemplateRegistryService? registry,
  })  : _filePath = filePath,
        _generator = generator ?? TrainingPackAutoGenerator(),
        _registry = registry ?? TrainingPackTemplateRegistryService();

  Future<List<ScheduledAutogenJob>> _loadJobs() async {
    final file = File(_filePath);
    if (!await file.exists()) return [];
    try {
      final raw = await file.readAsString();
      final data = jsonDecode(raw);
      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (e) => ScheduledAutogenJob.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _saveJobs(List<ScheduledAutogenJob> jobs) async {
    final file = File(_filePath);
    await file.writeAsString(
      jsonEncode([for (final j in jobs) j.toJson()]),
      flush: true,
    );
  }

  /// Runs all scheduled autogeneration jobs.
  Future<void> runScheduler() async {
    final jobs = await _loadJobs();
    var completed = 0;
    var errors = 0;
    final templates = <String>[];
    for (final job in jobs) {
      try {
        final templateSet = await _registry.loadTemplateById(job.templateId);
        await _generator.generate(templateSet);
        job.lastRun = DateTime.now().toUtc();
        completed++;
        templates.add(job.templateId);
      } catch (e, st) {
        errors++;
        AppLogger.error('Failed to generate ${job.templateId}', e, st);
      }
    }
    await _saveJobs(jobs);
    AppLogger.log(
      'AutoPackGenerationSchedulerService: executed $completed jobs, errors: $errors, templates: ${templates.join(', ')}',
    );
  }

  /// Adds a new scheduled job.
  Future<void> addScheduledJob(ScheduledAutogenJob job) async {
    final jobs = await _loadJobs();
    jobs.add(job);
    await _saveJobs(jobs);
  }

  /// Removes jobs that have already run.
  Future<void> clearCompletedJobs() async {
    final jobs = await _loadJobs();
    final pending = jobs.where((j) => j.lastRun == null).toList();
    await _saveJobs(pending);
  }
}
