import 'dart:convert';
import 'dart:io';

import '../models/v2/training_pack_spot.dart';
import 'training_pack_template_compiler.dart';

/// Generates a Dart library that embeds precompiled training pack spots.
///
/// Given a list of YAML file paths, this service compiles the templates into
/// concrete [TrainingPackSpot]s and writes them to `pack_library.g.dart` as a
/// `Map<String, List<TrainingPackSpot>>` named [packLibrary]. The generated
/// file uses JSON serialization to reconstruct each spot at runtime.
class PackLibraryGeneratorService {
  final TrainingPackTemplateCompiler _compiler;

  const PackLibraryGeneratorService({TrainingPackTemplateCompiler? compiler})
    : _compiler = compiler ?? const TrainingPackTemplateCompiler();

  /// Compiles [paths] and writes the resulting map to [outPath].
  Future<void> generate(
    List<String> paths, {
    String outPath = 'lib/generated/pack_library.g.dart',
  }) async {
    final grouped = await _compiler.compileFilesGrouped(paths);
    final keys = grouped.keys.toList()..sort();
    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln('')
      ..writeln("import 'dart:convert';")
      ..writeln(
        "import 'package:poker_analyzer/models/v2/training_pack_spot.dart';",
      )
      ..writeln('')
      ..writeln('final Map<String, List<TrainingPackSpot>> packLibrary = {');

    for (final key in keys) {
      final spots = grouped[key]!;
      buffer.writeln("  '$key': [");
      for (final spot in spots) {
        final jsonStr = jsonEncode(spot.toJson());
        buffer.writeln(
          "    TrainingPackSpot.fromJson(jsonDecode(r'''$jsonStr''') as Map<String, dynamic>),",
        );
      }
      buffer.writeln('  ],');
    }
    buffer.writeln('};');

    final file = File(outPath);
    await file.create(recursive: true);
    await file.writeAsString(buffer.toString());
  }
}
