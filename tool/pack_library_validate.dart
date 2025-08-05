import 'dart:io';

import 'package:poker_analyzer/services/pack_library_round_trip_validator_service.dart';
import 'package:poker_analyzer/services/training_pack_library_importer.dart';

Future<void> main(List<String> args) async {
  String? dir;
  for (final a in args) {
    if (a.startsWith('--dir=')) {
      dir = a.substring(6);
    }
  }
  if (dir == null) {
    stderr.writeln(
      'Usage: dart run tool/pack_library_validate.dart --dir=<packsDir>',
    );
    exit(64);
  }

  final importer = TrainingPackLibraryImporter();
  final packs = await importer.loadFromDirectory(dir);
  if (importer.errors.isNotEmpty) {
    stderr.writeln('Import errors:');
    for (final e in importer.errors) {
      stderr.writeln('  $e');
    }
    exit(1);
  }

  final service = PackLibraryRoundTripValidatorService();
  final result = service.validate(packs);
  if (result.success) {
    stdout.writeln('Validated ${packs.length} packs successfully.');
  } else {
    stderr.writeln('Validation failed for ${packs.length} packs:');
    for (final e in result.errors) {
      stderr.writeln('  $e');
    }
    exit(1);
  }
}
