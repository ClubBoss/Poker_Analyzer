import 'dart:io';

import '../core/training/export/training_pack_exporter_v2.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'autogen_pipeline_debug_stats_service.dart';
import 'autogen_pipeline_event_logger_service.dart';

/// Exports training packs to YAML files.
class YamlPackExporter {
  final TrainingPackExporterV2 _delegate;

  YamlPackExporter({TrainingPackExporterV2? delegate})
    : _delegate = delegate ?? const TrainingPackExporterV2();

  /// Writes [pack] to disk as a YAML file and returns the created [File].
  Future<File> export(TrainingPackTemplateV2 pack) async {
    final file = await _delegate.exportToFile(pack);
    AutogenPipelineDebugStatsService.incrementPublished();
    AutogenPipelineEventLoggerService.log(
      'published',
      'Published pack ${pack.id} to ${file.path}',
    );
    return file;
  }

  /// Converts [pack] to a YAML string.
  String exportYaml(TrainingPackTemplateV2 pack) {
    return _delegate.exportYaml(pack);
  }
}
