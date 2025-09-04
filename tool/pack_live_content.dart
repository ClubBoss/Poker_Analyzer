// ASCII-only; pure Dart packer for Live modules.

import 'dart:convert';
import 'dart:io';

import 'package:poker_analyzer/live/live_ids.dart';
import 'package:poker_analyzer/content/jsonl_loader.dart';

Future<void> main(List<String> args) async {
  final modulesArg = args.firstWhere(
    (a) => a.startsWith('--modules='),
    orElse: () => '',
  );
  final pretty = args.contains('--pretty');
  final only = modulesArg.isEmpty
      ? null
      : modulesArg
            .substring('--modules='.length)
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toSet();

  final ids = only == null
      ? kLiveModuleIds
      : kLiveModuleIds.where((id) => only.contains(id)).toList();

  final encoder = pretty
      ? const JsonEncoder.withIndent('  ')
      : const JsonEncoder();

  final index = <Map<String, Object?>>[];
  var anyFail = false;

  for (final id in ids) {
    final res = await _packOne(id, encoder);
    if (res.ok) {
      stdout.writeln('PACK OK ' + id + ' -> ' + res.outPath);
      index.add(<String, Object?>{
        'moduleId': id,
        'version': 'v1',
        'demos': res.demosCount,
        'drills': res.drillsCount,
      });
    } else {
      anyFail = true;
      stdout.writeln('PACK FAIL ' + id + ': ' + res.reason);
    }
  }

  // Write index.json only if at least one OK
  if (index.isNotEmpty) {
    final idxPath = 'build/live/index.json';
    _ensureDir('build/live');
    File(idxPath).writeAsStringSync(encoder.convert(index) + '\n', flush: true);
  }

  if (anyFail) exit(1);
}

class _PackResult {
  final bool ok;
  final String reason;
  final String outPath;
  final int demosCount;
  final int drillsCount;
  _PackResult.ok(this.outPath, this.demosCount, this.drillsCount)
    : ok = true,
      reason = '';
  _PackResult.fail(this.reason)
    : ok = false,
      outPath = '',
      demosCount = 0,
      drillsCount = 0;
}

Future<_PackResult> _packOne(String id, JsonEncoder encoder) async {
  try {
    final root = 'content/' + id + '/v1';
    final theoryPath = root + '/theory.md';
    final demosPath = root + '/demos.jsonl';
    final drillsPath = root + '/drills.jsonl';

    final theory = _readText(theoryPath);
    final demosSrc = _readText(demosPath);
    final drillsSrc = _readText(drillsPath);

    // Validate and parse JSONL
    final demos = parseJsonl(demosSrc);
    final drills = parseJsonl(drillsSrc);

    final obj = <String, Object?>{
      'moduleId': id,
      'version': 'v1',
      'theory': theory,
      'demos': demos,
      'drills': drills,
    };

    final outDir = 'build/live/' + id + '/v1';
    _ensureDir(outDir);
    final outPath = outDir + '/module.json';
    File(outPath).writeAsStringSync(encoder.convert(obj) + '\n', flush: true);
    return _PackResult.ok(outPath, demos.length, drills.length);
  } catch (e) {
    return _PackResult.fail(e.toString());
  }
}

String _readText(String path) {
  try {
    return File(path).readAsStringSync();
  } catch (e) {
    throw Exception('read error: ' + path + ': ' + e.toString());
  }
}

void _ensureDir(String path) {
  final d = Directory(path);
  if (!d.existsSync()) {
    d.createSync(recursive: true);
  }
}
