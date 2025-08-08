import 'package:args/args.dart';
import 'package:poker_analyzer/services/theory_integrity_sweeper.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.first != 'sweep') {
    print('Usage: poker_analyzer sweep --dir <path> [--fix]');
    return;
  }
  final parser = ArgParser()
    ..addMultiOption('dir')
    ..addFlag('fix', negatable: false);
  final result = parser.parse(args.skip(1));
  final dirs = result['dir'] as List<String>;
  final fix = result['fix'] as bool;
  await TheoryIntegritySweeper().run(dirs: dirs, dryRun: !fix);
}
