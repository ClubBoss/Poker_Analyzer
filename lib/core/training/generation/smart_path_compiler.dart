import 'dart:io';

import 'learning_path_auto_pack_assigner.dart';
import 'learning_path_library_generator.dart';
import 'learning_path_pack_validator.dart';
import 'smart_path_seed_generator.dart';

/// Compiles a simple string description of a learning path into YAML.
class SmartPathCompiler {
  final SmartPathSeedGenerator seedGenerator;
  final LearningPathAutoPackAssigner packAssigner;
  final LearningPathPackValidator validator;
  final LearningPathLibraryGenerator libraryGenerator;

  const SmartPathCompiler({
    SmartPathSeedGenerator? seedGenerator,
    LearningPathAutoPackAssigner? packAssigner,
    LearningPathPackValidator? validator,
    LearningPathLibraryGenerator? libraryGenerator,
  }) : seedGenerator = seedGenerator ?? const SmartPathSeedGenerator(),
       packAssigner = packAssigner ?? const LearningPathAutoPackAssigner(),
       validator = validator ?? const LearningPathPackValidator(),
       libraryGenerator =
           libraryGenerator ?? const LearningPathLibraryGenerator();

  /// Compiles [lines] into a YAML learning path using packs from [packsDir].
  /// Throws [Exception] if any referenced packs are missing.
  String compile(List<String> lines, Directory packsDir) {
    final stages = seedGenerator.generateFromStringList(lines);

    final mapping = <String, String>{
      for (final s in stages) '${s.id}_': s.packId,
    };

    final withPacks = packAssigner.assignPackIds(
      stages,
      ManualMapStrategy(mapping),
    );

    final errors = validator.validate(withPacks, packsDir);
    if (errors.isNotEmpty) {
      throw Exception(errors.join(', '));
    }

    return libraryGenerator.generatePathYaml(withPacks);
  }
}
