import 'dart:io';

import 'package:collection/collection.dart';

import 'training_pack_library_importer.dart';
import 'training_pack_library_exporter.dart';
import 'training_pack_metadata_enricher_service.dart';

class TrainingPackEnrichmentReport {
  final int enrichedCount;
  final int changedCount;
  final int skippedCount;

  TrainingPackEnrichmentReport({
    required this.enrichedCount,
    required this.changedCount,
    required this.skippedCount,
  });
}

class TrainingPackAutoEnricherBatchService {
  final TrainingPackLibraryImporter importer;
  final TrainingPackMetadataEnricherService enricher;
  final TrainingPackLibraryExporter exporter;

  TrainingPackAutoEnricherBatchService({
    TrainingPackLibraryImporter? importer,
    TrainingPackMetadataEnricherService? enricher,
    TrainingPackLibraryExporter? exporter,
  }) : importer = importer ?? TrainingPackLibraryImporter(),
       enricher = enricher ?? TrainingPackMetadataEnricherService(),
       exporter = exporter ?? const TrainingPackLibraryExporter();

  Future<TrainingPackEnrichmentReport> enrichDirectory(
    String path, {
    bool saveChanges = false,
  }) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      return TrainingPackEnrichmentReport(
        enrichedCount: 0,
        changedCount: 0,
        skippedCount: 0,
      );
    }

    var enriched = 0;
    var changed = 0;
    var skipped = 0;

    await for (final entity in dir.list()) {
      if (entity is! File ||
          !(entity.path.endsWith('.yaml') || entity.path.endsWith('.yml'))) {
        continue;
      }

      final name = entity.uri.pathSegments.last;
      final content = await entity.readAsString();
      final packs = importer.importFromMap({name: content});
      if (packs.isEmpty) {
        skipped++;
        continue;
      }
      final original = packs.first;
      final enrichedPack = await enricher.enrich(original);
      enriched++;
      final isSame = const DeepCollectionEquality().equals(
        original.metadata,
        enrichedPack.metadata,
      );
      if (!isSame) {
        changed++;
        if (saveChanges) {
          final yaml = exporter.exportToMap([enrichedPack]).values.first;
          await entity.writeAsString(yaml);
        }
      }
    }

    return TrainingPackEnrichmentReport(
      enrichedCount: enriched,
      changedCount: changed,
      skippedCount: skipped,
    );
  }
}
