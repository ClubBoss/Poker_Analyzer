import 'dart:io';

import '../models/training_pack_template_set.dart';
import '../models/inline_theory_entry.dart';
import '../models/v2/training_pack_spot.dart';
import 'training_pack_generator_engine_v2.dart';

/// Compiles multiple [TrainingPackTemplateSet] YAML sources into concrete
/// [TrainingPackSpot]s at build time.
///
/// Each provided YAML string or file path is parsed into a
/// [TrainingPackTemplateSet] which is then expanded by
/// [TrainingPackGeneratorEngineV2]. The resulting spots can be returned as a
/// flat list or grouped by the template's base spot id.
class TrainingPackTemplateCompiler {
  final TrainingPackGeneratorEngineV2 _engine;

  const TrainingPackTemplateCompiler({
    TrainingPackGeneratorEngineV2? engine,
  }) : _engine = engine ?? const TrainingPackGeneratorEngineV2();

  /// Compiles template sets from YAML [sources].
  ///
  /// Each entry in [sources] should be a raw YAML string. The method returns a
  /// flat list of all generated [TrainingPackSpot]s.
  List<TrainingPackSpot> compileYamls(
    List<String> sources, {
    Map<String, InlineTheoryEntry> theoryIndex = const {},
  }) {
    final result = <TrainingPackSpot>[];
    for (final yaml in sources) {
      final set = TrainingPackTemplateSet.fromYaml(yaml);
      final spots = _engine.generate(set, theoryIndex: theoryIndex);
      result.addAll(spots);
    }
    return result;
  }

  /// Compiles template sets from YAML files at the given [paths].
  ///
  /// Returns a flat list of all generated [TrainingPackSpot]s.
  Future<List<TrainingPackSpot>> compileFiles(
    List<String> paths, {
    Map<String, InlineTheoryEntry> theoryIndex = const {},
  }) async {
    final yamls = <String>[];
    for (final p in paths) {
      yamls.add(await File(p).readAsString());
    }
    return compileYamls(yamls, theoryIndex: theoryIndex);
  }

  /// Compiles template sets from YAML [sources] and groups the resulting spots
  /// by the base spot id.
  Map<String, List<TrainingPackSpot>> compileYamlsGrouped(
    List<String> sources, {
    Map<String, InlineTheoryEntry> theoryIndex = const {},
  }) {
    final result = <String, List<TrainingPackSpot>>{};
    for (final yaml in sources) {
      final set = TrainingPackTemplateSet.fromYaml(yaml);
      final spots = _engine.generate(set, theoryIndex: theoryIndex);
      result.putIfAbsent(set.baseSpot.id, () => []).addAll(spots);
    }
    return result;
  }

  /// Compiles template sets from YAML files at [paths] and groups the results
  /// by the base spot id.
  Future<Map<String, List<TrainingPackSpot>>> compileFilesGrouped(
    List<String> paths, {
    Map<String, InlineTheoryEntry> theoryIndex = const {},
  }) async {
    final yamls = <String>[];
    for (final p in paths) {
      yamls.add(await File(p).readAsString());
    }
    return compileYamlsGrouped(yamls, theoryIndex: theoryIndex);
  }
}
