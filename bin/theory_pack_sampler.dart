import 'dart:io';
import 'package:args/args.dart';
import 'package:poker_analyzer/core/training/generation/yaml_reader.dart';
import 'package:poker_analyzer/core/training/export/training_pack_exporter_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/services/theory_pack_sampler.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()..addFlag('help', abbr: 'h', negatable: false);
  final results = parser.parse(args);
  if (results['help'] as bool || results.rest.isEmpty) {
    stdout.writeln('Usage: dart bin/theory_pack_sampler.dart <pack.yaml>');
    return;
  }
  final path = results.rest.first;
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('File not found: $path');
    exit(1);
  }
  final yaml = await file.readAsString();
  final map = const YamlReader().read(yaml);
  final pack = TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
  final sampler = const TheoryPackSampler();
  final theoryPack = sampler.sample(pack);
  if (theoryPack == null) {
    stderr.writeln('No theory spots found');
    exit(2);
  }
  final outYaml = const TrainingPackExporterV2().exportYaml(theoryPack);
  stdout.writeln(outYaml);
}
