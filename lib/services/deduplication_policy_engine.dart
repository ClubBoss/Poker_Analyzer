import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'autogen_status_dashboard_service.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'spot_fingerprint_generator.dart';

enum DeduplicationAction { block, merge, rename, flag }

class DeduplicationPolicy {
  final String reason; // "duplicate" or "high_similarity"
  final DeduplicationAction action;
  final double threshold; // similarity cutoff

  const DeduplicationPolicy({
    required this.reason,
    required this.action,
    required this.threshold,
  });

  factory DeduplicationPolicy.fromJson(Map<String, dynamic> json) {
    return DeduplicationPolicy(
      reason: json['reason'] as String,
      action: DeduplicationAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => DeduplicationAction.flag,
      ),
      threshold: (json['threshold'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'reason': reason,
        'action': action.name,
        'threshold': threshold,
      };
}

class DeduplicationPolicyEngine {
  static const _prefsKey = 'deduplication_policies';

  final List<DeduplicationPolicy> _policies = [];
  final AutogenStatusDashboardService _status;
  String outputDir;

  DeduplicationPolicyEngine({
    AutogenStatusDashboardService? status,
    this.outputDir = 'packs/generated',
  }) : _status = status ?? AutogenStatusDashboardService.instance;

  List<DeduplicationPolicy> get policies => List.unmodifiable(_policies);

  Future<void> loadPolicies() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      final List data = jsonDecode(raw) as List;
      _policies
        ..clear()
        ..addAll(
          data.map(
            (e) => DeduplicationPolicy.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          ),
        );
    }
    if (_policies.isEmpty) {
      _policies.addAll(const [
        DeduplicationPolicy(
          reason: 'duplicate',
          action: DeduplicationAction.block,
          threshold: 1.0,
        ),
        DeduplicationPolicy(
          reason: 'high_similarity',
          action: DeduplicationAction.flag,
          threshold: 0.95,
        ),
      ]);
      await _savePolicies();
    }
  }

  Future<void> setPolicies(List<DeduplicationPolicy> policies) async {
    _policies
      ..clear()
      ..addAll(policies);
    await _savePolicies();
  }

  Future<void> _savePolicies() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_policies.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, data);
  }

  Future<void> applyPolicies(List<DuplicatePackInfo> duplicates) async {
    for (final d in duplicates) {
      for (final policy in _policies) {
        if (d.reason == policy.reason && d.similarity >= policy.threshold) {
          switch (policy.action) {
            case DeduplicationAction.block:
              final file = File('$outputDir/${d.candidateId}.yaml');
              if (await file.exists()) {
                await file.delete();
              }
              _status.flagDuplicate(
                d.candidateId,
                d.existingId,
                'blocked by policy',
                d.similarity,
              );
              break;
            case DeduplicationAction.merge:
              final candidateFile = File('$outputDir/${d.candidateId}.yaml');
              final existingFile = File('$outputDir/${d.existingId}.yaml');
              if (await candidateFile.exists() && await existingFile.exists()) {
                final candidate = TrainingPackTemplateV2.fromYaml(
                  await candidateFile.readAsString(),
                );
                final existing = TrainingPackTemplateV2.fromYaml(
                  await existingFile.readAsString(),
                );
                final gen = const SpotFingerprintGenerator();
                final keys = <String>{
                  for (final s in existing.spots) gen.generate(s),
                };
                for (final s in candidate.spots) {
                  if (keys.add(gen.generate(s))) existing.spots.add(s);
                }
                existing.spotCount = existing.spots.length;
                final merged = <String>{
                  ...((existing.meta['mergedIds'] as List?)?.map(
                        (e) => e.toString(),
                      ) ??
                      []),
                  ...((candidate.meta['mergedIds'] as List?)?.map(
                        (e) => e.toString(),
                      ) ??
                      []),
                  candidate.id,
                };
                existing.meta['mergedIds'] = merged.toList();
                await existingFile.writeAsString(existing.toYamlString());
                await candidateFile.delete();
                _status.flagDuplicate(
                  d.candidateId,
                  d.existingId,
                  'merged by policy',
                  d.similarity,
                );
              }
              break;
            case DeduplicationAction.rename:
              final candidateFile = File('$outputDir/${d.candidateId}.yaml');
              if (await candidateFile.exists()) {
                final candidate = TrainingPackTemplateV2.fromYaml(
                  await candidateFile.readAsString(),
                );
                var counter = 2;
                var newId = '${candidate.id}_v$counter';
                while (File('$outputDir/$newId.yaml').existsSync()) {
                  counter++;
                  newId = '${candidate.id}_v$counter';
                }
                final map = candidate.toJson();
                final meta = Map<String, dynamic>.from(map['meta'] ?? {});
                meta['renamedFrom'] = candidate.id;
                map
                  ..['id'] = newId
                  ..['meta'] = meta;
                final renamed = TrainingPackTemplateV2.fromJson(map);
                final newFile = File('$outputDir/$newId.yaml');
                await newFile.writeAsString(renamed.toYamlString());
                await candidateFile.delete();
                _status.flagDuplicate(
                  newId,
                  d.existingId,
                  'renamed by policy',
                  d.similarity,
                );
              }
              break;
            case DeduplicationAction.flag:
              _status.flagDuplicate(
                d.candidateId,
                d.existingId,
                'flagged by policy',
                d.similarity,
              );
              break;
          }
          break;
        }
      }
    }
  }
}
