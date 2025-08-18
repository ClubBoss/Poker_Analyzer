import 'dart:io';
import 'package:poker_analyzer/services/pack_library_generator.dart';

Future<void> main(List<String> args) async {
  final start = DateTime.now();
  final generator = PackLibraryGenerator();
  await generator.generateFromYaml('pack_templates.yaml');
  await generator.saveToJson(
    'assets/training_packs/training_pack_library.json',
  );
  final count = generator.packs.length;
  final elapsed = DateTime.now().difference(start).inMilliseconds / 1000;
  stdout.writeln('Generated $count packs in ${elapsed.toStringAsFixed(1)} s');
}
