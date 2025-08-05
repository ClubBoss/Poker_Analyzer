import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:poker_analyzer/services/training_pack_library_differ.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/pack_library_diff.dart <oldDir> <newDir>',
    );
    exit(64);
  }

  final differ = TrainingPackLibraryDiffer();
  final result = await differ.diff(args[0], args[1]);

  stdout.writeln(
    'Comparing ${p.normalize(args[0])} to ${p.normalize(args[1])}:',
  );
  stdout.writeln('Added:   ${result.added}');
  stdout.writeln('Removed: ${result.removed}');
  stdout.writeln('Changed: ${result.changed}');
}
