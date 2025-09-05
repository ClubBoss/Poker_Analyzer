// Export a beta bundle zip with content and UI assets.
// Usage: dart run tooling/export_beta_bundle.dart [--out build/beta_bundle.zip] [--force] [--quiet]
// - Runs pre_release_check first.
// - Zips: content/, build/ui_assets/*, build/gaps.json, build/term_lint.json,
//         build/unlocks.txt, build/badges.json, build/search_index.json,
//         build/see_also.json, build/pre_release_check.txt
// Exit 0 on success; 1 on I/O/zip errors unless --force.

import 'dart:io';

Future<void> main(List<String> args) async {
  var outPath = 'build/beta_bundle.zip';
  var force = false;
  var quiet = false;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--out' && i + 1 < args.length) {
      outPath = args[++i];
    } else if (a == '--force') {
      force = true;
    } else if (a == '--quiet') {
      quiet = true;
    }
  }

  // Ensure build dir exists
  Directory('build').createSync(recursive: true);

  // Run pre-release check
  final pr = await _run(['dart', 'run', 'tooling/pre_release_check.dart']);
  final preOk = pr == 0;
  if (!preOk && !force) {
    exitCode = 1;
    return;
  }

  // Collect items that exist
  final includes = <String>[];
  if (Directory('content').existsSync()) includes.add('content');
  if (Directory('build/ui_assets').existsSync())
    includes.add('build/ui_assets');
  for (final f in [
    'build/gaps.json',
    'build/term_lint.json',
    'build/unlocks.txt',
    'build/badges.json',
    'build/search_index.json',
    'build/see_also.json',
    'build/pre_release_check.txt',
  ]) {
    if (File(f).existsSync()) includes.add(f);
  }

  // Prepare output
  final outFile = File(outPath);
  try {
    outFile.parent.createSync(recursive: true);
    if (outFile.existsSync()) outFile.deleteSync();
  } catch (e) {
    if (!quiet) stderr.writeln('error: cannot prepare output: $e');
    if (!force) exitCode = 1;
    return;
  }

  // Zip with system zip
  final zipCmd = ['zip', '-qr', outPath, ...includes];
  final zipCode = await _run(zipCmd);
  if (zipCode != 0 && !force) {
    if (!quiet) stderr.writeln('error: zip failed with code $zipCode');
    exitCode = 1;
    return;
  }

  final size = outFile.existsSync() ? outFile.lengthSync() : 0;
  if (!quiet) {
    stdout.writeln(
      'BETA-BUNDLE out=$outPath size=$size files=content,ui_assets,gaps,term,unlocks,badges,search,see_also,pre_release',
    );
  }
}

Future<int> _run(List<String> cmd) async {
  try {
    final p = await Process.run(cmd.first, cmd.sublist(1));
    return p.exitCode;
  } catch (_) {
    return 1;
  }
}
