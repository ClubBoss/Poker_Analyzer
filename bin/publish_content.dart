import 'dart:io';
import 'package:args/args.dart';
import 'package:poker_analyzer/services/pack_library_auto_publisher.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('dry-run', negatable: false)
    ..addFlag('only-packs', negatable: false)
    ..addFlag('only-paths', negatable: false);
  final results = parser.parse(args);
  final dry = results['dry-run'] as bool;
  final onlyPacks = results['only-packs'] as bool;
  final onlyPaths = results['only-paths'] as bool;

  final publisher = const PackLibraryAutoPublisher();
  final report = await publisher.publish(
    dryRun: dry,
    onlyPacks: onlyPacks,
    onlyPaths: onlyPaths,
  );

  stdout.writeln('Packs published: ${report.packs.length}');
  stdout.writeln('Paths compiled: ${report.paths.length}');
  if (report.packsSkipped.isNotEmpty) {
    stdout.writeln('Skipped packs: ${report.packsSkipped.join(', ')}');
  }
  if (report.pathsSkipped.isNotEmpty) {
    stdout.writeln('Skipped paths: ${report.pathsSkipped.join(', ')}');
  }
}
