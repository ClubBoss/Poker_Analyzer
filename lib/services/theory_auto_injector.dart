import 'dart:convert';
import 'dart:io';

import 'package:json2yaml/json2yaml.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../models/autogen_status.dart';
import 'autogen_status_dashboard_service.dart';
import 'preferences_service.dart';
import 'theory_yaml_safe_writer.dart';

class TheoryInjectReport {
  final int packsUpdated;
  final int linksAdded;
  final Map<String, String> errors;

  const TheoryInjectReport({
    this.packsUpdated = 0,
    this.linksAdded = 0,
    Map<String, String>? errors,
  }) : errors = errors ?? const {};

  Map<String, dynamic> toJson() => {
        'packsUpdated': packsUpdated,
        'linksAdded': linksAdded,
        'errors': errors,
      };

  factory TheoryInjectReport.fromJson(Map<String, dynamic> json) =>
      TheoryInjectReport(
        packsUpdated: json['packsUpdated'] ?? 0,
        linksAdded: json['linksAdded'] ?? 0,
        errors: json['errors'] == null
            ? const {}
            : Map<String, String>.from(json['errors'] as Map),
      );
}

/// Automatically injects theory links into packs based on a remediation plan.
class TheoryAutoInjector {
  TheoryAutoInjector({AutogenStatusDashboardService? dashboard})
      : _dashboard = dashboard ?? AutogenStatusDashboardService.instance;

  final AutogenStatusDashboardService _dashboard;

  Future<TheoryInjectReport> inject({
    required Map<String, List<String>> plan,
    required Map<String, List<String>> theoryIndex,
    required String libraryDir,
    int minLinksPerPack = 1,
    bool dryRun = false,
  }) async {
    var packsUpdated = 0;
    var linksAdded = 0;
    final errors = <String, String>{};

    final totalPacks = plan.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );
    var processed = 0;

    for (final entry in plan.entries) {
      final topic = entry.key;
      final packs = entry.value;
      final links = theoryIndex[topic] ?? const <String>[];
      for (final packId in packs) {
        processed++;
        _dashboard.update(
          'TheoryAutoInjector',
          AutogenStatus(
            isRunning: true,
            currentStage: 'topic:$topic',
            progress: totalPacks == 0 ? 0 : processed / totalPacks,
          ),
        );

        final file = File(p.join(libraryDir, '$packId.yaml'));
        if (!await file.exists()) {
          errors[packId] = 'pack_missing';
          continue;
        }
        final yamlStr = await file.readAsString();
        final data =
            jsonDecode(jsonEncode(loadYaml(yamlStr))) as Map<String, dynamic>;
        final meta = Map<String, dynamic>.from(data['meta'] ?? {});
        final existing =
            (meta['theoryLinks'] as List?)?.cast<String>() ?? <String>[];

        final needed = <String>[];
        for (final id in links) {
          if (existing.contains(id) || needed.contains(id)) continue;
          if (!_theoryEntryExists(id, libraryDir)) {
            errors[packId] = 'missing_theory:$id';
            continue;
          }
          needed.add(id);
          if (existing.length + needed.length >= minLinksPerPack) break;
        }
        if (needed.isEmpty) continue;
        if (!dryRun) {
          meta['theoryLinks'] = [...existing, ...needed];
          data['meta'] = meta;
          final out = json2yaml(data);
          final prevHash =
              TheoryYamlSafeWriter.extractHash(yamlStr);
          await TheoryYamlSafeWriter().write(
            path: file.path,
            yaml: out,
            schema: 'TemplateSet',
            prevHash: prevHash,
          );
        }
        packsUpdated++;
        linksAdded += needed.length;
      }
    }

    _dashboard.update(
      'TheoryAutoInjector',
      const AutogenStatus(
        isRunning: false,
        currentStage: 'complete',
        progress: 1,
      ),
    );

    final report = TheoryInjectReport(
      packsUpdated: packsUpdated,
      linksAdded: linksAdded,
      errors: errors,
    );

    final prefs = await PreferencesService.getInstance();
    await prefs.setString(
      SharedPrefsKeys.theoryInjectReport,
      jsonEncode(report.toJson()),
    );

    return report;
  }

  bool _theoryEntryExists(String id, String root) {
    final yaml = File(p.join(root, 'theory', '$id.yaml'));
    final yml = File(p.join(root, 'theory', '$id.yml'));
    return yaml.existsSync() || yml.existsSync();
  }
}
