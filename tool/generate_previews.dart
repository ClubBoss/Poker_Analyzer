import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/services/png_exporter.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
        'Usage: dart run tool/generate_previews.dart <inputDir> [outputDir]');
    exit(1);
  }
  final src = Directory(args[0]);
  if (!src.existsSync()) {
    stderr.writeln('Directory not found: ${args[0]}');
    exit(1);
  }
  final out = Directory(args.length > 1 ? args[1] : './previews')
    ..createSync(recursive: true);
  final files = src.listSync(recursive: true).whereType<File>().where((f) {
    final l = f.path.toLowerCase();
    return l.endsWith('.json') || l.endsWith('.pka');
  }).toList();
  stdout.writeln('Generating ${files.length} previews…');
  final start = DateTime.now();
  var done = 0;
  for (var i = 0; i < files.length; i += 4) {
    final batch = files.skip(i).take(4).toList();
    await Future.wait(
      batch.map((file) async {
        try {
          TrainingPackTemplate tpl;
          if (file.path.toLowerCase().endsWith('.json')) {
            final map =
                jsonDecode(await file.readAsString()) as Map<String, dynamic>;
            tpl = TrainingPackTemplate.fromJson(map);
          } else {
            final bytes = await file.readAsBytes();
            final archive = ZipDecoder().decodeBytes(bytes);
            final tplFile =
                archive.files.firstWhere((e) => e.name == 'template.json');
            final jsonMap = jsonDecode(utf8.decode(tplFile.content))
                as Map<String, dynamic>;
            tpl = TrainingPackTemplate.fromJson(jsonMap);
          }
          final bytes = await PngExporter.exportTemplatePreview(tpl);
          if (bytes == null) throw 'failed';
          final path = p.join(out.path, '${tpl.id}.png');
          await File(path).writeAsBytes(bytes);
          stdout.writeln(
              '[${++done}/${files.length}] ${p.basename(path)}  –  OK');
        } catch (_) {
          stdout.writeln(
              '[${++done}/${files.length}] ${p.basename(file.path)}  –  [ERROR]');
        }
      }),
    );
  }
  final elapsed = DateTime.now().difference(start).inMilliseconds / 1000;
  stdout.writeln('Done in ${elapsed.toStringAsFixed(1)} s');
}
