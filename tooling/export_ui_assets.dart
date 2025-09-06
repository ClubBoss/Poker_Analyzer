// Export compact UI assets bundle from build artifacts (or recompute if missing).
// Usage:
//   dart run tooling/export_ui_assets.dart [--out build/ui_assets] [--recompute] [--quiet]
// ASCII-only. No external deps. Exit 0 on success, 1 on I/O/parse error.

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  var outDir = 'build/ui_assets';
  var recompute = false;
  var quiet = false;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--out' && i + 1 < args.length) {
      outDir = args[++i];
    } else if (a == '--recompute') {
      recompute = true;
    } else if (a == '--quiet') {
      quiet = true;
    }
  }

  final out = Directory(outDir);
  try {
    out.createSync(recursive: true);
  } catch (e) {
    stderr.writeln('error: cannot create $outDir: $e');
    exitCode = 1;
    return;
  }

  // Ensure sources exist (recompute missing if needed or requested)
  final sources = <String, Future<bool> Function()>{
    'build/badges.json': () async =>
        await _run([
          'dart',
          'run',
          'tooling/export_progression_badges.dart',
          '--json',
          'build/badges.json',
        ]) ==
        0,
    'build/search_index.json': () async =>
        await _run([
          'dart',
          'run',
          'tooling/build_search_index.dart',
          '--json',
          'build/search_index.json',
        ]) ==
        0,
    'build/see_also.json': () async =>
        await _run([
          'dart',
          'run',
          'tooling/build_see_also.dart',
          '--json',
          'build/see_also.json',
        ]) ==
        0,
    'build/lesson_flow.json': () async =>
        await _run([
          'dart',
          'run',
          'tooling/export_lesson_flow.dart',
        ]) ==
        0,
    'build/review_plan.json': () async =>
        await _run([
          'dart',
          'run',
          'tooling/export_review_plan.dart',
        ]) ==
        0,
    'build/i18n/en.json': () async =>
        await _run([
          'dart',
          'run',
          'tooling/export_i18n_strings.dart',
          '--out',
          'build/i18n',
        ]) ==
        0,
    'build/i18n/ru.json': () async =>
        await _run([
          'dart',
          'run',
          'tooling/export_i18n_strings.dart',
          '--out',
          'build/i18n',
        ]) ==
        0,
    'build/telemetry_schema.json': () async =>
        await _run([
          'dart',
          'run',
          'tooling/export_telemetry_schema.dart',
        ]) ==
        0,
  };

  for (final path in sources.keys) {
    final f = File(path);
    if (recompute || !f.existsSync()) {
      final ok = await sources[path]!();
      if (!ok) {
        stderr.writeln('error: failed to build $path');
        exitCode = 1;
        return;
      }
    }
  }

  // Copy files to outDir (deterministic order)
  final filesList = <String>[
    'badges.json',
    'search_index.json',
    'see_also.json',
    'lesson_flow.json',
    'review_plan.json',
    'i18n/en.json',
    'i18n/ru.json',
    'telemetry_schema.json',
  ];
  try {
    // Ensure i18n subdirectory exists
    Directory('$outDir/i18n').createSync(recursive: true);
    for (final name in filesList) {
      File('build/' + name).copySync('$outDir/' + name);
    }
  } catch (e) {
    stderr.writeln('error: copying files: $e');
    exitCode = 1;
    return;
  }

  // Parse counts
  int modules = 0;
  int tokens = 0;
  int spots = 0;
  int i18nKeys = 0;
  const telemetryEvents = 4;
  try {
    final badges = jsonDecode(File('$outDir/badges.json').readAsStringSync());
    if (badges is Map && badges['rows'] is List) {
      modules = (badges['rows'] as List).length;
    }
    final index = jsonDecode(File('$outDir/search_index.json').readAsStringSync());
    if (index is Map && index['summary'] is Map) {
      final s = index['summary'] as Map;
      tokens = (s['unique_tokens'] is int) ? s['unique_tokens'] as int : 0;
      spots = (s['unique_spot_kinds'] is int)
          ? s['unique_spot_kinds'] as int
          : 0;
    }
    final enI18n = jsonDecode(File('$outDir/i18n/en.json').readAsStringSync());
    if (enI18n is Map) {
      i18nKeys = enI18n.length;
    }
  } catch (e) {
    stderr.writeln('error: parsing counts: $e');
    exitCode = 1;
    return;
  }

  // Write manifest
  final manifest = <String, dynamic>{
    'generated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'files': filesList,
    'counts': {
      'modules': modules,
      'tokens': tokens,
      'spot_kinds': spots,
      'i18n_keys': i18nKeys,
      'telemetry_events': telemetryEvents,
    },
  };
  try {
    File('$outDir/manifest.json').writeAsStringSync(jsonEncode(manifest));
  } catch (e) {
    stderr.writeln('error: writing manifest: $e');
    exitCode = 1;
    return;
  }

  if (!quiet) {
    stdout.writeln(
      'UIASSETS out=$outDir files=' +
          manifest['files'].length.toString() +
          ' modules=$modules tokens=$tokens spot_kinds=$spots',
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
