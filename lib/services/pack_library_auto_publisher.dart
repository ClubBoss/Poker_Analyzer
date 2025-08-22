import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

import '../core/training/generation/smart_path_compiler.dart';
import '../core/training/generation/learning_path_pack_validator.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'yaml_pack_validator_service.dart';

class PublishReport {
  final List<String> packs;
  final List<String> packsSkipped;
  final List<String> paths;
  final List<String> pathsSkipped;

  PublishReport({
    List<String>? packs,
    List<String>? packsSkipped,
    List<String>? paths,
    List<String>? pathsSkipped,
  }) : packs = packs ?? <String>[],
       packsSkipped = packsSkipped ?? <String>[],
       paths = paths ?? <String>[],
       pathsSkipped = pathsSkipped ?? <String>[];

  Map<String, dynamic> toJson() => {
    'packs': packs,
    'packsSkipped': packsSkipped,
    'paths': paths,
    'pathsSkipped': pathsSkipped,
  };
}

class PackLibraryAutoPublisher {
  PackLibraryAutoPublisher();

  Future<PublishReport> publish({
    String packsSrc = 'assets/packs',
    String pathsSrc = 'assets/paths',
    String outDir = 'public',
    bool dryRun = false,
    bool onlyPacks = false,
    bool onlyPaths = false,
  }) async {
    final report = PublishReport();
    if (!onlyPaths) {
      await _publishPacks(
        report,
        packsSrc: packsSrc,
        outDir: p.join(outDir, 'packs'),
        dryRun: dryRun,
      );
    }
    if (!onlyPacks) {
      await _publishPaths(
        report,
        pathsSrc: pathsSrc,
        packsOut: p.join(outDir, 'packs'),
        outDir: p.join(outDir, 'paths'),
        dryRun: dryRun,
      );
    }
    if (!dryRun) {
      final indexFile = File(p.join(outDir, 'index.json'));
      await indexFile.create(recursive: true);
      await indexFile.writeAsString(jsonEncode(report.toJson()), flush: true);
    }
    return report;
  }

  Future<void> _publishPacks(
    PublishReport report, {
    required String packsSrc,
    required String outDir,
    required bool dryRun,
  }) async {
    final srcDir = Directory(packsSrc);
    if (!srcDir.existsSync()) return;
    final files = srcDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));
    const validator = YamlPackValidatorService();
    for (final file in files) {
      final rel = p.relative(file.path, from: packsSrc);
      try {
        final yaml = await file.readAsString();
        final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
        final reportV = validator.validate(tpl);
        if (!reportV.isValid) {
          stderr.writeln('Invalid pack $rel: ${reportV.errors.join(', ')}');
          report.packsSkipped.add(rel);
          continue;
        }
        if (!dryRun) {
          final dest = File(p.join(outDir, rel));
          await dest.create(recursive: true);
          await dest.writeAsString(yaml, flush: true);
        }
        report.packs.add(rel);
      } catch (e) {
        stderr.writeln('Error processing $rel: $e');
        report.packsSkipped.add(rel);
      }
    }
  }

  Future<void> _publishPaths(
    PublishReport report, {
    required String pathsSrc,
    required String packsOut,
    required String outDir,
    required bool dryRun,
  }) async {
    final srcDir = Directory(pathsSrc);
    if (!srcDir.existsSync()) return;
    final files = srcDir.listSync().whereType<File>().where(
      (f) => f.path.toLowerCase().endsWith('.txt'),
    );
    final compiler = SmartPathCompiler(
      validator: const LearningPathPackValidator(),
    );
    for (final file in files) {
      final name = p.basenameWithoutExtension(file.path);
      final destPath = p.join(outDir, name, 'path.yaml');
      final rel = p.join(name, 'path.yaml');
      try {
        final lines = await file.readAsLines();
        final yaml = compiler.compile(lines, Directory(packsOut));
        if (!dryRun) {
          final dest = File(destPath);
          await dest.create(recursive: true);
          await dest.writeAsString('$yaml\n', flush: true);
        }
        report.paths.add(rel);
      } catch (e) {
        stderr.writeln('Failed to compile ${file.path}: $e');
        report.pathsSkipped.add(rel);
      }
    }
  }
}
