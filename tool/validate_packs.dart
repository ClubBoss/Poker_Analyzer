import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:poker_analyzer/helpers/training_pack_validator.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';

class _Result {
  final String name;
  final String icon;
  final String status;
  final double ev;
  final double icm;
  final int issues;
  _Result(this.name, this.icon, this.status, this.ev, this.icm, this.issues);
}

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/validate_packs.dart <inputDir> [--md]');
    exit(1);
  }
  final dir = Directory(args.first);
  if (!dir.existsSync()) {
    stderr.writeln('Directory not found: ${args.first}');
    exit(1);
  }
  final md = args.contains('--md');
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) {
        final l = f.path.toLowerCase();
        return l.endsWith('.json') || l.endsWith('.pka');
      })
      .toList();
  final start = DateTime.now();
  final results = <_Result>[];
  var ready = 0;
  var partial = 0;
  var invalid = 0;
  for (final file in files) {
    TrainingPackTemplate? tpl;
    try {
      if (file.path.toLowerCase().endsWith('.json')) {
        final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        tpl = TrainingPackTemplate.fromJson(map);
      } else {
        final bytes = file.readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);
        final tplFile = archive.files.firstWhere((e) => e.name == 'template.json');
        final jsonMap =
            jsonDecode(utf8.decode(tplFile.content)) as Map<String, dynamic>;
        tpl = TrainingPackTemplate.fromJson(jsonMap);
      }
    } catch (_) {}
    if (tpl == null) {
      results.add(_Result(p.basename(file.path), '❌', 'Invalid', 0, 0, 1));
      invalid++;
      continue;
    }
    final issues = validateTrainingPackTemplate(tpl);
    final total = tpl.spots.length;
    final ev = total == 0
        ? 0.0
        : tpl.spots.where((s) => s.heroEv != null).length / total;
    final icm = total == 0
        ? 0.0
        : tpl.spots.where((s) => s.heroIcmEv != null).length / total;
    String status;
    String icon;
    if (issues.isEmpty && ev >= 0.9 && icm >= 0.9) {
      status = 'Ready';
      icon = '✅';
      ready++;
    } else if (issues.isEmpty) {
      status = 'Partial';
      icon = '⚠️';
      partial++;
    } else {
      status = 'Invalid';
      icon = '❌';
      invalid++;
    }
    results.add(_Result(p.basename(file.path), icon, status, ev, icm, issues.length));
  }
  final elapsed = DateTime.now().difference(start).inMilliseconds / 1000;
  if (md) {
    stdout.writeln('| file | status | ev | icm | issues |');
    stdout.writeln('|---|---|---|---|---|');
    for (final r in results) {
      final ev = r.status == 'Invalid' ? '' : '${(r.ev * 100).round()} %';
      final icm = r.status == 'Invalid' ? '' : '${(r.icm * 100).round()} %';
      final issues = r.issues > 0 ? r.issues.toString() : '';
      stdout.writeln('| ${r.name} | ${r.icon} ${r.status} | $ev | $icm | $issues |');
    }
    stdout.writeln('');
    stdout.writeln('Total: ${results.length} files  |  Ready $ready  |  Partial $partial  |  Invalid $invalid');
    stdout.writeln('Time: ${elapsed.toStringAsFixed(1)} s');
  } else {
    final nameWidth = results.fold<int>(0, (p, e) => e.name.length > p ? e.name.length : p) + 2;
    for (final r in results) {
      final name = r.name.padRight(nameWidth);
      final status = '${r.icon} ${r.status}'.padRight(10);
      final ev = r.status == 'Invalid' ? ''.padRight(8) : 'EV ${(r.ev * 100).round()} %'.padRight(8);
      final icm = r.status == 'Invalid' ? ''.padRight(8) : 'ICM ${(r.icm * 100).round()} %'.padRight(8);
      final issues = r.status == 'Invalid' ? '${r.issues} issues' : '';
      stdout.writeln('$name$status  $ev  $icm$issues');
    }
    stdout.writeln('----');
    stdout.writeln('Total: ${results.length} files  |  Ready $ready  |  Partial $partial  |  Invalid $invalid');
    stdout.writeln('Time: ${elapsed.toStringAsFixed(1)} s');
  }
}
