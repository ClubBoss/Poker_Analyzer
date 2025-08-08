import 'package:args/args.dart';
import 'package:poker_analyzer/services/config_source.dart';
import 'package:poker_analyzer/services/theory_integrity_sweeper.dart';
import 'package:poker_analyzer/services/theory_yaml_safe_reader.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.first != 'sweep') {
    print('Usage: poker_analyzer sweep --dir <path> [--fix] [--config <file>]');
    return;
  }
  final parser = ArgParser()
    ..addOption('config')
    ..addMultiOption('dir')
    ..addFlag('fix', negatable: false)
    ..addOption('max-parallel')
    ..addOption('keep')
    ..addFlag('strict', defaultsTo: true)
    ..addFlag('auto-heal', defaultsTo: true);
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
  await sweeper.run(dirs: dirs, dryRun: !fix);
}
