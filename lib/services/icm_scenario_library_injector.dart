import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaml/yaml.dart';

import '../models/training_pack_model.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/training_pack.dart' show TrainingType;
import '../models/game_type.dart';
import 'pack_novelty_guard_service.dart';

/// Represents a single ICM scenario loaded from the library.
class ICMScenario {
  final String scenarioId;
  final String stage;
  final int players;
  final List<num> stacksBB;
  final int heroSeat;
  final List<num> payouts;
  final num effectiveBB;
  final List<String> positions;
  final List<String> tags;
  final TrainingPackSpot spot;
  final double weight;

  ICMScenario({
    required this.scenarioId,
    required this.stage,
    required this.players,
    required this.stacksBB,
    required this.heroSeat,
    required this.payouts,
    required this.effectiveBB,
    required this.positions,
    required this.tags,
    required this.spot,
    required this.weight,
  });

  factory ICMScenario.fromJson(Map<String, dynamic> j) {
    void require(String key, bool cond) {
      if (!cond) throw FormatException('Invalid scenario: missing $key');
    }

    require('scenarioId', j['scenarioId'] is String);
    require('stage', j['stage'] is String);
    require('players', j['players'] is int || j['players'] is num);
    require('stacksBB', j['stacksBB'] is List);
    require('heroSeat', j['heroSeat'] is int || j['heroSeat'] is num);
    require('payouts', j['payouts'] is List);
    require('effectiveBB', j['effectiveBB'] is int || j['effectiveBB'] is num);
    require('positions', j['positions'] is List);
    require('tags', j['tags'] is List);
    require('spot', j['spot'] is Map);

    return ICMScenario(
      scenarioId: j['scenarioId'].toString(),
      stage: j['stage'].toString(),
      players: (j['players'] as num).toInt(),
      stacksBB: [for (final v in (j['stacksBB'] as List)) (v as num)],
      heroSeat: (j['heroSeat'] as num).toInt(),
      payouts: [for (final v in (j['payouts'] as List)) (v as num)],
      effectiveBB: j['effectiveBB'] as num,
      positions: [for (final v in (j['positions'] as List)) v.toString()],
      tags: [for (final v in (j['tags'] as List)) v.toString()],
      spot: TrainingPackSpot.fromJson(
        Map<String, dynamic>.from(j['spot'] as Map),
      ),
      weight: (j['weight'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Injects ICM scenarios into auto-generated packs based on policy rules.
class ICMScenarioLibraryInjector {
  final List<ICMScenario> _library;
  final PackNoveltyGuardService? _noveltyGuard;

  ICMScenarioLibraryInjector({
    List<ICMScenario>? scenarios,
    String libraryPath = 'assets/icm_scenarios',
    PackNoveltyGuardService? noveltyGuard,
  }) : _library = scenarios ?? _loadLibrary(libraryPath),
       _noveltyGuard = noveltyGuard;

  /// Loads scenario files from [path]. Supports JSON and YAML formats.
  static List<ICMScenario> _loadLibrary(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) return [];
    final scenarios = <ICMScenario>[];
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final content = entity.readAsStringSync();
      dynamic raw;
      if (entity.path.endsWith('.yaml') || entity.path.endsWith('.yml')) {
        raw = loadYaml(content);
      } else {
        raw = jsonDecode(content);
      }
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            scenarios.add(
              ICMScenario.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      } else if (raw is Map) {
        scenarios.add(ICMScenario.fromJson(Map<String, dynamic>.from(raw)));
      }
    }
    return scenarios;
  }

  /// Inject scenarios into [input] according to policy rules.
  Future<TrainingPackModel> inject(TrainingPackModel input) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('icm.inject.enabled') ?? true;
    if (!enabled || _library.isEmpty) return input;

    final requireTags =
        prefs.getStringList('icm.inject.requireTags') ?? ['icm', 'mtt'];
    final packTags = {for (final t in input.tags) t.toLowerCase()};
    if (!requireTags.every((t) => packTags.contains(t.toLowerCase()))) {
      return input;
    }

    final ratio = prefs.getDouble('icm.inject.ratio') ?? 0.15;
    final minSpots = prefs.getInt('icm.inject.minSpots') ?? 2;
    final maxPerPack = prefs.getInt('icm.inject.maxPerPack') ?? 6;

    var desired = (input.spots.length * ratio).round();
    if (desired < minSpots) desired = minSpots;
    if (desired > maxPerPack) desired = maxPerPack;
    if (desired <= 0) return input;

    final selected = _selectScenarios(input, desired);
    if (selected.isEmpty) return input;

    var model = _applyScenarios(input, selected);

    // Novelty guard evaluation and fallback
    if (_noveltyGuard != null) {
      var tpl = _toTemplate(model);
      final res = await _noveltyGuard.evaluate(tpl);
      if (res.isDuplicate && selected.length > 1) {
        final reduced = selected.sublist(0, selected.length - 1);
        model = _applyScenarios(input, reduced);
        tpl = _toTemplate(model);
        final res2 = await _noveltyGuard.evaluate(tpl);
        if (res2.isDuplicate) {
          return input; // skip injection
        }
      }
    }

    return model;
  }

  List<ICMScenario> _selectScenarios(TrainingPackModel model, int desired) {
    final packTags = {for (final t in model.tags) t.toLowerCase()};
    var candidates = _library
        .where((s) => s.tags.any((t) => packTags.contains(t.toLowerCase())))
        .toList();
    if (candidates.isEmpty) {
      candidates = List<ICMScenario>.from(_library);
      candidates.sort((a, b) => b.weight.compareTo(a.weight));
    }
    final rand = Random(model.id.hashCode);
    candidates.shuffle(rand);
    final usedStages = <String>{};
    final selected = <ICMScenario>[];
    for (final s in candidates) {
      if (selected.length >= desired) break;
      if (usedStages.contains(s.stage)) continue;
      selected.add(s);
      usedStages.add(s.stage);
    }
    return selected;
  }

  TrainingPackModel _applyScenarios(
    TrainingPackModel base,
    List<ICMScenario> scenarios,
  ) {
    if (scenarios.isEmpty) return base;
    final additions = <TrainingPackSpot>[];
    for (final sc in scenarios) {
      final clone = TrainingPackSpot.fromJson(sc.spot.toJson());
      clone.isInjected = true;
      final stageTag = sc.stage.toLowerCase();
      if (!clone.tags.contains('icm')) clone.tags.add('icm');
      if (!clone.tags.contains(stageTag)) clone.tags.add(stageTag);
      clone.meta['icm'] = {
        'scenarioId': sc.scenarioId,
        'stage': sc.stage,
        'payouts': sc.payouts,
        'stacksBB': sc.stacksBB,
        'heroSeat': sc.heroSeat,
        'effectiveBB': sc.effectiveBB,
        'icmWeight': sc.weight,
        'source': 'ICMScenarioLibraryInjector',
      };
      additions.add(clone);
    }
    final spots = <TrainingPackSpot>[...additions, ...base.spots];
    final meta = Map<String, dynamic>.from(base.metadata);
    meta['icmInjected'] = true;
    meta['icmScenarioCount'] = additions.length;
    return TrainingPackModel(
      id: base.id,
      title: base.title,
      spots: spots,
      tags: List<String>.from(base.tags),
      metadata: meta,
    );
  }

  TrainingPackTemplateV2 _toTemplate(TrainingPackModel m) {
    return TrainingPackTemplateV2(
      id: m.id,
      name: m.title,
      trainingType: TrainingType.custom,
      spots: List<TrainingPackSpot>.from(m.spots),
      spotCount: m.spots.length,
      tags: List<String>.from(m.tags),
      gameType: GameType.cash,
      bb: m.spots.isNotEmpty ? m.spots.first.hand.stacks['0']?.toInt() ?? 0 : 0,
      positions: [],
      meta: Map<String, dynamic>.from(m.metadata),
    );
  }
}
