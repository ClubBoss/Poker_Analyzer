import 'dart:io';
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/helpers/training_pack_validator.dart';
import 'package:poker_analyzer/services/pack_export_service.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
        'Usage: dart run tool/bundle_packs.dart <templatesDir> [outputDir] [--keep-original] [--index]');
    exit(1);
  }
  final srcPath = args[0];
  var outPath = './bundles';
  var keep = false;
  var buildIndex = false;
  var i = 1;
  if (i < args.length && !args[i].startsWith('--')) {
    outPath = args[i];
    i++;
  }
  for (; i < args.length; i++) {
    final a = args[i];
    if (a == '--keep-original') keep = true;
    if (a == '--index') buildIndex = true;
  }
  final srcDir = Directory(srcPath);
  if (!srcDir.existsSync()) {
    stderr.writeln('Source not found: $srcPath');
    exit(1);
  }
  final outDir = Directory(outPath)..createSync(recursive: true);
  final files = srcDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.json'))
      .toList();
  stdout.writeln('Bundling ${files.length} templates…');
  final start = DateTime.now();
  final indexRows = <List<dynamic>>[];
  for (var j = 0; j < files.length; j++) {
    final file = files[j];
    try {
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final tpl = TrainingPackTemplate.fromJson(map);
      final issues = validateTrainingPackTemplate(tpl);
      if (issues.isNotEmpty) throw issues.join('; ');
      final bundle = await PackExportService.exportBundle(tpl);
      final dest = File(p.join(outDir.path, '${tpl.id}.pka'));
      if (dest.existsSync()) dest.deleteSync();
      bundle.copySync(dest.path);
      if (!keep) {
        try {
          bundle.deleteSync();
        } catch (_) {}
      }
      stdout.writeln(
          '[${j + 1}/${files.length}] ${p.basename(dest.path)}  –  OK');
      if (buildIndex) {
        indexRows.add([
          tpl.id,
          tpl.name,
          tpl.spots.length,
          tpl.evCovered,
          tpl.icmCovered,
          tpl.createdAt.toIso8601String(),
          tpl.lastGeneratedAt?.toIso8601String() ?? ''
        ]);
      }
    } catch (e) {
      stdout.writeln(
          '[${j + 1}/${files.length}] ${p.basename(file.path)}  –  [ERROR]');
    }
  }
  if (buildIndex) {
    final rows = <List<dynamic>>[
      [
        'id',
        'name',
        'spots',
        'evCovered',
        'icmCovered',
        'createdAt',
        'lastGeneratedAt'
      ],
      ...indexRows
    ];
    final csvStr = const ListToCsvConverter().convert(rows);
    File(p.join(outDir.path, 'index.csv')).writeAsStringSync(csvStr);
  }
  final elapsed = DateTime.now().difference(start).inMilliseconds / 1000;
  stdout.writeln('Done in ${elapsed.toStringAsFixed(1)} s');
}
