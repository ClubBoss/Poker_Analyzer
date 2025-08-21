import 'package:collection/collection.dart';

import '../models/training_pack_model.dart';
import 'training_pack_library_exporter.dart';
import 'training_pack_library_importer.dart';

class RoundTripResult {
  final bool success;
  final List<String> errors;

  RoundTripResult({required this.success, required this.errors});
}

class PackLibraryRoundTripValidatorService {
  final TrainingPackLibraryExporter exporter;
  final TrainingPackLibraryImporter importer;

  PackLibraryRoundTripValidatorService({
    TrainingPackLibraryExporter? exporter,
    TrainingPackLibraryImporter? importer,
  })  : exporter = exporter ?? const TrainingPackLibraryExporter(),
        importer = importer ?? TrainingPackLibraryImporter();

  RoundTripResult validate(List<TrainingPackModel> packs) {
    final files = exporter.exportToMap(packs);
    final imported = importer.importFromMap(files);
    final errors = <String>[...importer.errors];

    final importedMap = {for (final p in imported) p.id: p};

    for (final original in packs) {
      final roundTripped = importedMap[original.id];
      if (roundTripped == null) {
        errors.add('Pack ${original.id} missing after import');
        continue;
      }
      if (original.title != roundTripped.title) {
        errors.add('Pack ${original.id}: title mismatch');
      }
      if (!const UnorderedIterableEquality<String>().equals(
        original.tags,
        roundTripped.tags,
      )) {
        errors.add('Pack ${original.id}: tags mismatch');
      }
      if (original.spots.length != roundTripped.spots.length) {
        errors.add('Pack ${original.id}: spot count mismatch');
      }
      final roundTrippedSpotMap = {for (final s in roundTripped.spots) s.id: s};
      for (final spot in original.spots) {
        final rtSpot = roundTrippedSpotMap[spot.id];
        if (rtSpot == null) {
          errors.add('Pack ${original.id}: spot ${spot.id} missing');
          continue;
        }
        final origMap = spot.toYaml();
        final rtMap = rtSpot.toYaml();
        if (!const DeepCollectionEquality().equals(origMap, rtMap)) {
          errors.add('Pack ${original.id}: spot ${spot.id} mismatch');
        }
      }
    }

    return RoundTripResult(success: errors.isEmpty, errors: errors);
  }
}
