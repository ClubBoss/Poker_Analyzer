// lib/services/theory_integrity_sweeper.dart
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import 'package:yaml/yaml.dart';

import '../models/autogen_status.dart';
import 'autogen_status_dashboard_service.dart';
import 'theory_yaml_safe_reader.dart';
import 'theory_write_scope.dart';
import 'theory_yaml_canonicalizer.dart';

class SweepEntry {
  final String file;
  final String action;
  final String? oldHash;
  final String? newHash;
  final int? headerVersion;
  final int pruned;

  const SweepEntry({
    required this.file,
    required this.action,
    this.oldHash,
    this.newHash,
    this.headerVersion,
    this.pruned = 0,
  });

  Map<String, dynamic> toJson() => {
    'file': file,
    'action': action,
    'oldHash': oldHash,
    'newHash': newHash,
    'headerVersion': headerVersion,
    'pruned': pruned,
  };
}

class SweepReport {
  final List<SweepEntry> entries;
  final Map<String, int> counters;

  SweepReport({List<SweepEntry>? entries, Map<String, int>? counters})
    : entries = entries ?? [],
      counters = counters ?? {'ok': 0, 'upgraded': 0, 'healed': 0, 'failed': 0};

  Map<String, dynamic> toJson() => {
    'entries': entries.map((e) => e.toJson()).toList(),
    'counters': counters,
  };
}

class TheoryIntegritySweeper {
  TheoryIntegritySweeper({
    AutogenStatusDashboardService? dashboard,
    TheoryYamlSafeReader? reader,
  }) : _dashboard = dashboard ?? AutogenStatusDashboardService.instance,
       _reader = reader ?? TheoryYamlSafeReader();

  final AutogenStatusDashboardService _dashboard;
  final TheoryYamlSafeReader _reader;

  Future<SweepReport> run({
    required List<String> dirs,
    bool dryRun = true,
    bool heal = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final maxParallel = prefs.getInt('theory.sweep.maxParallel') ?? 2;
    final keep = prefs.getInt('theory.backups.keep') ?? 10;

    final files = <String>[];
    for (final dir in dirs) {
      final d = Directory(dir);
      if (!d.existsSync()) continue;
      files.addAll(
        d
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.yaml'))
            .map((f) => f.path),
      );
    }
    files.sort();
    final total = files.length;

    final queue = Queue<String>.from(files);
    final report = SweepReport();
    final lock = Lock();
    var processed = 0;

    Future<void> worker() async {
      while (true) {
        String? path;
        await lock.synchronized(() {
          if (queue.isNotEmpty) {
            path = queue.removeFirst();
          }
        });
        if (path == null) break;
        final entry = await _process(
          path!,
          dryRun: dryRun,
          heal: heal,
          keep: keep,
        );
        await lock.synchronized(() {
          report.entries.add(entry);
          report.counters[entry.action] =
              (report.counters[entry.action] ?? 0) + 1;
          processed++;
          _dashboard.update(
            'TheorySweep',
            AutogenStatus(
              currentStage: 'running',
              progress: total == 0 ? 1 : processed / total,
              file: path,
              action: entry.action,
            ),
          );
        });
      }
    }

    final workers = [for (var i = 0; i < maxParallel; i++) worker()];
    await Future.wait(workers);

    await _writeReport(report);
    return report;
  }

  Future<SweepEntry> _process(
    String path, {
    required bool dryRun,
    required bool heal,
    required int keep,
  }) async {
    return TheoryWriteScope.run(() async {
      final file = File(path);
      if (!file.existsSync()) {
        return SweepEntry(file: path, action: 'failed');
      }
      final lines = await file.readAsLines();
      final headerMap = _parseHeader(lines.isEmpty ? '' : lines.first);
      final oldHash = headerMap['x-hash'];
      final oldAlgo = headerMap['x-hash-algo'];
      final version = int.tryParse(headerMap['x-ver'] ?? '');

      try {
        await _reader.read(
          path: path,
          schema: 'TemplateSet',
          autoHeal: !dryRun && heal,
        );
      } catch (_) {
        return SweepEntry(
          file: path,
          action: 'failed',
          oldHash: oldHash,
          newHash: oldHash,
          headerVersion: version,
        );
      }

      final afterLines = await file.readAsLines();
      final newHeader = _parseHeader(afterLines.first);
      var newHash = newHeader['x-hash'];
      final newAlgo = newHeader['x-hash-algo'];
      final newVersion = int.tryParse(newHeader['x-ver'] ?? '');

      var action = 'ok';
      if (oldHash != newHash) {
        if (oldAlgo != newAlgo) {
          action = 'upgraded';
        } else {
          action = 'healed';
        }
      }

      var pruned = 0;
      if (!dryRun && action != 'failed') {
        pruned = _pruneBackups(path, keep);
      }

      if (dryRun && action == 'upgraded') {
        final body = lines.skip(1).join('\n');
        final canon = const TheoryYamlCanonicalizer().canonicalize(
          jsonDecode(jsonEncode(loadYaml(body))) as Map<String, dynamic>,
        );
        newHash = sha256.convert(utf8.encode(canon)).toString();
      }

      return SweepEntry(
        file: path,
        action: action,
        oldHash: oldHash,
        newHash: newHash,
        headerVersion: newVersion,
        pruned: pruned,
      );
    });
  }

  Map<String, String> _parseHeader(String line) {
    if (!line.startsWith('#')) return {};
    final map = <String, String>{};
    final parts = line.substring(1).split('|');
    for (final part in parts) {
      final kv = part.split(':');
      if (kv.length >= 2) {
        map[kv[0].trim()] = kv.sublist(1).join(':').trim();
      }
    }
    return map;
  }

  int _pruneBackups(String path, int keep) {
    final rel = p.relative(path);
    final base = p.basename(rel);
    final dir = Directory(p.join('theory_backups', p.dirname(rel)));
    if (!dir.existsSync()) return 0;
    final backups =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => p.basename(f.path).startsWith('$base.'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final over = backups.length - keep;
    if (over > 0) {
      for (final f in backups.take(over)) {
        f.deleteSync();
      }
      return over;
    }
    return 0;
  }

  Future<void> _writeReport(SweepReport report) async {
    final jsonFile = File('theory_sweep_report.json');
    await jsonFile.writeAsString(jsonEncode(report.toJson()));
    final csvFile = File('theory_sweep_report.csv');
    final lines = [
      'file,action,oldHash,newHash,headerVersion,pruned',
      ...report.entries.map(
        (e) =>
            '${e.file},${e.action},${e.oldHash ?? ''},${e.newHash ?? ''},${e.headerVersion ?? ''},${e.pruned}',
      ),
    ];
    await csvFile.writeAsString(lines.join('\n'));
  }
}
