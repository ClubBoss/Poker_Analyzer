import 'dart:io';

import '../core/training/export/training_pack_exporter_v2.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'autogen_pipeline_debug_stats_service.dart';

/// Exports training packs to YAML files.
class YamlPackExporter {
  final TrainingPackExporterV2 _delegate;

  const YamlPackExporter({TrainingPackExporterV2? delegate})
      : _delegate = delegate ?? const TrainingPackExporterV2();

  /// Writes [pack] to disk as a YAML file and returns the created [File].
  Future<File> export(TrainingPackTemplateV2 pack) async {
    final file = await _delegate.exportToFile(pack);
    AutogenPipelineDebugStatsService.incrementPublished();
    return file;
  }

  /// Converts [pack] to a YAML string.
  String exportYaml(TrainingPackTemplateV2 pack) {
    return _delegate.exportYaml(pack);
  }
}
