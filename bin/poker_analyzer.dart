import 'dart:io';

import 'package:args/args.dart';
import 'package:poker_analyzer/services/config_source.dart';
import 'package:poker_analyzer/services/theory_integrity_sweeper.dart';
import 'package:poker_analyzer/services/theory_manifest_service.dart';
import 'package:poker_analyzer/services/theory_yaml_safe_reader.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: poker_analyzer <sweep|verify|manifest> ...');
    return;
  }
  final cmd = args.first;
  if (cmd == 'sweep') {
    final parser = ArgParser()
      ..addOption('config')
      ..addMultiOption('dir')
      ..addFlag('fix', negatable: false)
      ..addOption('max-parallel')
      ..addOption('keep')
      ..addFlag('strict', defaultsTo: true)
      ..addFlag('auto-heal', defaultsTo: true)
      ..addOption('manifest');
    final result = parser.parse(args.skip(1));
    final dirs = result['dir'] as List<String>;
    final fix = result['fix'] as bool;
    final cli = <String, dynamic>{};
    if (result['max-parallel'] != null) {
      cli['theory.sweep.maxParallel'] = int.parse(result['max-parallel']);
    }
    if (result['keep'] != null) {
      cli['theory.backups.keep'] = int.parse(result['keep']);
    }
    if (result.wasParsed('strict')) {
      cli['theory.reader.strict'] = result['strict'] as bool;
    }
    if (result.wasParsed('auto-heal')) {
      cli['theory.reader.autoHeal'] = result['auto-heal'] as bool;
    }
    final config = await ConfigSource.from(
      cli: cli,
      configFile: result['config'] as String?,
    );
    final reader = TheoryYamlSafeReader(config: config);
    final sweeper = TheoryIntegritySweeper(config: config, reader: reader);
    await sweeper.run(
      dirs: dirs,
      dryRun: !fix,
      manifestPath: result['manifest'] as String?,
    );
  } else if (cmd == 'verify') {
    final parser = ArgParser()
      ..addOption('config')
      ..addMultiOption('dir')
      ..addOption('manifest', defaultsTo: 'theory_manifest.json')
      ..addFlag('ci', negatable: false)
      ..addFlag('strict', defaultsTo: true);
    final result = parser.parse(args.skip(1));
    final cli = <String, dynamic>{};
    if (result.wasParsed('strict')) {
      cli['theory.reader.strict'] = result['strict'] as bool;
    }
    final config = await ConfigSource.from(
      cli: cli,
      configFile: result['config'] as String?,
    );
    final reader = TheoryYamlSafeReader(config: config);
    final sweeper = TheoryIntegritySweeper(config: config, reader: reader);
    final report = await sweeper.run(
      dirs: (result['dir'] as List<String>),
      dryRun: true,
      heal: false,
      manifestPath: result['manifest'] as String?,
      check: true,
    );
    final bad =
        (report.counters['needs_upgrade'] ?? 0) +
        (report.counters['needs_heal'] ?? 0) +
        (report.counters['failed'] ?? 0);
    if (result['ci'] as bool && bad > 0) {
      exit(1);
    }
  } else if (cmd == 'manifest' && args.length >= 2) {
    final sub = args[1];
    final parser = ArgParser()
      ..addMultiOption('dir')
      ..addOption('out', defaultsTo: 'theory_manifest.json');
    final result = parser.parse(args.skip(2));
    final service = TheoryManifestService(path: result['out'] as String);
    if (sub == 'generate') {
      await service.generate(result['dir'] as List<String>);
    } else if (sub == 'update') {
      await service.load();
      await service.update(result['dir'] as List<String>);
    } else {
      print('Usage: poker_analyzer manifest <generate|update> --dir <path>');
      return;
    }
    await service.save();
  } else {
    print('Usage: poker_analyzer <sweep|verify|manifest> ...');
  }
}
