import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'autogen_status_dashboard_service.dart';

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
              _status.flagDuplicate(
                d.candidateId,
                d.existingId,
                'merge by policy pending',
                d.similarity,
              );
              // TODO: implement merge logic
              break;
            case DeduplicationAction.rename:
              _status.flagDuplicate(
                d.candidateId,
                d.existingId,
                'rename by policy pending',
                d.similarity,
              );
              // TODO: implement rename logic
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

