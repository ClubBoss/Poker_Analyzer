import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

import '../models/saved_hand.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/action_entry.dart';
import '../services/saved_hand_manager_service.dart';
import 'saved_hand_storage_service.dart';
import '../helpers/training_pack_storage.dart';
import '../helpers/mistake_category_translations.dart';
import 'pack_generator_service.dart';
import '../main.dart';
import 'cloud_retry_policy.dart';
import 'cloud_sync_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'template_storage_service.dart';
import 'training_pack_stats_service.dart';

class TrainingPackService {
  const TrainingPackService._();

  static TrainingPackSpot _spotFromHand(SavedHand h) {
    final hero = h.playerCards[h.heroIndex]
        .map((c) => '${c.rank}${c.suit}')
        .join(' ');
    final board = [for (final c in h.boardCards) '${c.rank}${c.suit}'];
    final actions = <int, List<ActionEntry>>{};
    for (final a in h.actions) {
      actions
          .putIfAbsent(a.street, () => [])
          .add(
            ActionEntry(
              a.street,
              a.playerIndex,
              a.action,
              amount: a.amount,
              generated: a.generated,
              manualEvaluation: a.manualEvaluation,
              customLabel: a.customLabel,
            ),
          );
    }
    final stacks = <String, double>{
      for (final e in h.stackSizes.entries) '${e.key}': e.value.toDouble(),
    };
    final tags = List<String>.from(h.tags);
    final cat = h.category;
    if (cat != null && cat.isNotEmpty) tags.add('cat:$cat');
    return TrainingPackSpot(
      id: const Uuid().v4(),
      title: h.name,
      hand: HandData(
        heroCards: hero,
        position: parseHeroPosition(h.heroPosition),
        heroIndex: h.heroIndex,
        playerCount: h.numberOfPlayers,
        board: board,
        actions: actions,
        stacks: stacks,
        anteBb: h.anteBb,
      ),
      tags: tags,
    );
  }

  static Future<TrainingPackTemplate?> createDrillFromCategory(
    BuildContext context,
    String category,
  ) async {
    final hands = context.read<SavedHandManagerService>().hands;
    final mistakes = [
      for (final h in hands)
        if (h.category == category &&
            h.expectedAction != null &&
            h.gtoAction != null &&
            h.expectedAction!.trim().toLowerCase() !=
                h.gtoAction!.trim().toLowerCase())
          h,
    ];
    if (mistakes.isEmpty) return null;
    mistakes.sort((a, b) => (b.evLoss ?? 0).compareTo(a.evLoss ?? 0));
    final selected = mistakes.take(10).toList();
    final spots = [for (final h in selected) _spotFromHand(h)];
    return TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Авто Drill: $category',
      spots: spots,
    );
  }

  static Future<TrainingPackTemplate?> createDrillForCategory(
    BuildContext context,
    String category,
  ) {
    return createDrillFromCategory(context, category);
  }

  static Future<TrainingPackTemplate?> createDrillFromTop3Categories(
    BuildContext context,
  ) async {
    final hands = context.read<SavedHandManagerService>().hands;
    final byCat = <String, List<SavedHand>>{};
    for (final h in hands) {
      final cat = h.category;
      final exp = h.expectedAction;
      final gto = h.gtoAction;
      if (cat == null || cat.isEmpty) continue;
      if (exp == null || gto == null) continue;
      if (exp.trim().toLowerCase() == gto.trim().toLowerCase()) continue;
      if (h.corrected) continue;
      byCat.putIfAbsent(cat, () => []).add(h);
    }
    if (byCat.length < 3) return null;
    final rng = Random();
    final cats = byCat.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final spots = <TrainingPackSpot>[];
    for (final e in cats.take(3)) {
      final list = e.value
        ..sort((a, b) => (b.evLoss ?? 0).compareTo(a.evLoss ?? 0));
      final count = min(list.length, 2 + rng.nextInt(2));
      for (final h in list.take(count)) {
        spots.add(_spotFromHand(h));
      }
    }
    if (spots.isEmpty) return null;
    return TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Top Mistake Drill',
      spots: spots,
    );
  }

  static Future<TrainingPackTemplate?> createDrillFromTopCategories(
    BuildContext context,
  ) async {
    final hands = context.read<SavedHandManagerService>().hands;
    final byCat = <String, List<SavedHand>>{};
    final evMap = <String, double>{};
    for (final h in hands) {
      final cat = h.category;
      final exp = h.expectedAction;
      final gto = h.gtoAction;
      if (cat == null || cat.isEmpty) continue;
      if (exp == null || gto == null) continue;
      if (exp.trim().toLowerCase() == gto.trim().toLowerCase()) continue;
      if (h.corrected) continue;
      byCat.putIfAbsent(cat, () => []).add(h);
      evMap[cat] = (evMap[cat] ?? 0) + (h.evLoss ?? 0);
    }
    if (evMap.length < 3) return null;
    final topCats = evMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final all = <SavedHand>[];
    for (final e in topCats.take(3)) {
      all.addAll(byCat[e.key]!);
    }
    if (all.isEmpty) return null;
    all.sort((a, b) => (b.evLoss ?? 0).compareTo(a.evLoss ?? 0));
    final rng = Random();
    final count = min(all.length, 10 + rng.nextInt(6));
    final spots = [for (final h in all.take(count)) _spotFromHand(h)];
    return TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Top 3 Mistakes',
      spots: spots,
    );
  }

  static Future<TrainingPackTemplate?> createDrillFromWeakestCategory(
    BuildContext context,
  ) async {
    final hands = context.read<SavedHandManagerService>().hands;
    final byCat = <String, List<SavedHand>>{};
    final evMap = <String, double>{};
    for (final h in hands) {
      final cat = h.category;
      final exp = h.expectedAction;
      final gto = h.gtoAction;
      if (cat == null || cat.isEmpty) continue;
      if (exp == null || gto == null) continue;
      if (exp.trim().toLowerCase() == gto.trim().toLowerCase()) continue;
      if (h.corrected) continue;
      byCat.putIfAbsent(cat, () => []).add(h);
      evMap[cat] = (evMap[cat] ?? 0) + (h.evLoss ?? 0);
    }
    if (evMap.isEmpty) return null;
    final cat = evMap.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final list = byCat[cat]!
      ..sort((a, b) => (b.evLoss ?? 0).compareTo(a.evLoss ?? 0));
    final rng = Random();
    final count = min(list.length, 5 + rng.nextInt(4));
    final spots = [for (final h in list.take(count)) _spotFromHand(h)];
    return TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Weakest Category Drill',
      spots: spots,
    );
  }

  static Future<TrainingPackTemplate?> createDrillFromWeakCategories(
    BuildContext context,
  ) async {
    final stats = await TrainingPackStatsService.getCategoryStats();
    if (stats.isEmpty) return null;
    final cats = stats.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final selected = [for (final e in cats.take(3)) e.key];
    final templates = context.read<TemplateStorageService>().templates;
    final spots = <TrainingPackSpot>[];
    final seen = <String>{};
    final rng = Random();
    for (final cat in selected) {
      final list = <TrainingPackSpot>[];
      for (final t in templates) {
        for (final s in t.spots) {
          final tag = 'cat:$cat';
          if ((s.tags.contains(tag) || s.categories.contains(tag)) &&
              seen.add(s.id)) {
            list.add(s);
          }
        }
      }
      if (list.isEmpty) continue;
      list.sort((a, b) {
        final r = (b.heroEv ?? 0).compareTo(a.heroEv ?? 0);
        return r == 0 ? b.createdAt.compareTo(a.createdAt) : r;
      });
      final maxCount = min(list.length, 5);
      final count = maxCount < 3 ? maxCount : 3 + rng.nextInt(maxCount - 2);
      spots.addAll([
        for (final s in list.take(count)) s.copyWith(id: const Uuid().v4()),
      ]);
    }
    if (spots.isEmpty) return null;
    return TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Weak Categories Drill',
      spots: spots,
    );
  }

  static Future<TrainingPackTemplate?> createDrillFromWorstCategory(
    BuildContext context,
  ) async {
    final hands = context.read<SavedHandManagerService>().hands;
    final byCat = <String, List<SavedHand>>{};
    for (final h in hands) {
      final cat = h.category;
      final exp = h.expectedAction;
      final gto = h.gtoAction;
      if (cat == null || cat.isEmpty) continue;
      if (exp == null || gto == null) continue;
      if (exp.trim().toLowerCase() == gto.trim().toLowerCase()) continue;
      if (h.corrected) continue;
      byCat.putIfAbsent(cat, () => []).add(h);
    }
    if (byCat.isEmpty) return null;
    final entries = byCat.entries.toList()
      ..sort((a, b) {
        final c = b.value.length.compareTo(a.value.length);
        if (c != 0) return c;
        final evA = a.value.fold<double>(0, (s, h) => s + (h.evLoss ?? 0));
        final evB = b.value.fold<double>(0, (s, h) => s + (h.evLoss ?? 0));
        return evB.compareTo(evA);
      });
    final entry = entries.first;
    final list = entry.value
      ..sort((a, b) => (b.evLoss ?? 0).compareTo(a.evLoss ?? 0));
    final rng = Random();
    final count = min(list.length, 5 + rng.nextInt(4));
    final spots = [for (final h in list.take(count)) _spotFromHand(h)];
    final title = 'Тренировка: ${translateMistakeCategory(entry.key)}';
    return TrainingPackTemplate(
      id: const Uuid().v4(),
      name: title,
      spots: spots,
    );
  }

  static Future<TrainingPackTemplate?> createTopMistakeDrill(
    BuildContext context,
  ) async {
    return createDrillFromTop3Categories(context);
  }

  static Future<TrainingPackTemplate?> createRepeatForCorrected(
    BuildContext context,
  ) async {
    final hands = context.read<SavedHandManagerService>().hands;
    final hand = hands.reversed.firstWhereOrNull((h) => h.corrected);
    if (hand == null) return null;
    final spot = _spotFromHand(hand);
    return TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Repeat Corrected',
      spots: [spot],
    );
  }

  static Future<TrainingPackTemplate?> createRepeatDrillForCorrected(
    BuildContext context,
  ) async {
    final hands = context.read<SavedHandManagerService>().hands;
    final list = [
      for (final h in hands)
        if (h.corrected && (h.evLoss?.abs() ?? 0) >= 1.0) h,
    ];
    if (list.isEmpty) return null;
    list.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    final spots = [for (final h in list) _spotFromHand(h)];
    return TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Повтор исправленных',
      spots: spots,
    );
  }

  static Future<TrainingPackTemplate?> createDrillFromCorrectedHands(
    BuildContext context,
  ) async {
    final hands = context.read<SavedHandManagerService>().hands;
    final list = [
      for (final h in hands)
        if (h.corrected) h,
    ];
    if (list.isEmpty) return null;
    list.sort((a, b) => (b.evLoss ?? 0).compareTo(a.evLoss ?? 0));
    final rng = Random();
    final count = min(list.length, 5 + rng.nextInt(4));
    final selected = list.take(count).toList()..shuffle();
    final spots = [for (final h in selected) _spotFromHand(h)];
    return TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Repeat Corrected Hands',
      spots: spots,
    );
  }

  static Future<TrainingPackTemplate?> createRepeatForIncorrect(
    BuildContext context,
  ) async {
    final hands = context.read<SavedHandManagerService>().hands;
    final hand = hands.reversed.firstWhereOrNull((h) {
      final ev = h.evLoss ?? 0.0;
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      return ev.abs() >= 1.0 &&
          !h.corrected &&
          exp != null &&
          gto != null &&
          exp != gto;
    });
    if (hand == null) return null;
    final spot = _spotFromHand(hand);
    return TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Repeat Incorrect',
      spots: [spot],
    );
  }

  static Future<TrainingPackTemplate?> createSingleRandomMistakeDrill(
    BuildContext context,
  ) async {
    final hands = context.read<SavedHandManagerService>().hands;
    final list = [
      for (final h in hands)
        if ((h.evLoss ?? 0) >= 1.0 &&
            h.expectedAction != null &&
            h.gtoAction != null &&
            h.expectedAction!.trim().toLowerCase() !=
                h.gtoAction!.trim().toLowerCase())
          h,
    ];
    if (list.isEmpty) return null;
    final hand = list[Random().nextInt(list.length)];
    final spot = _spotFromHand(hand);
    return TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Random Mistake',
      spots: [spot],
    );
  }

  static Future<TrainingPackTemplate?> createEvLossDrill(
    BuildContext context,
  ) async {
    final hands = context.read<SavedHandManagerService>().hands;
    final list = [
      for (final h in hands)
        if (!h.corrected &&
            h.expectedAction != null &&
            h.gtoAction != null &&
            h.expectedAction!.trim().toLowerCase() !=
                h.gtoAction!.trim().toLowerCase())
          h,
    ];
    if (list.isEmpty) return null;
    list.sort((a, b) => (b.evLoss ?? 0).compareTo(a.evLoss ?? 0));
    final rng = Random();
    final count = min(list.length, 10 + rng.nextInt(3));
    final spots = [for (final h in list.take(count)) _spotFromHand(h)];
    return TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Самые дорогие ошибки',
      spots: spots,
    );
  }

  static Future<TrainingPackTemplate?> createDrillFromAllMistakes(
    BuildContext context,
  ) async {
    final hands = context.read<SavedHandManagerService>().hands;
    final list = [
      for (final h in hands)
        if (!h.corrected &&
            (h.evLoss?.abs() ?? 0) >= 1.0 &&
            h.expectedAction != null &&
            h.gtoAction != null &&
            h.expectedAction!.trim().toLowerCase() !=
                h.gtoAction!.trim().toLowerCase())
          h,
    ];
    if (list.isEmpty) return null;
    list.shuffle();
    final rng = Random();
    final count = min(list.length, 5 + rng.nextInt(6));
    final spots = [for (final h in list.take(count)) _spotFromHand(h)];
    return TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'All Current Mistakes',
      spots: spots,
    );
  }

  static Future<TrainingPackTemplate?> createDrillFromGlobalMistakes(
    BuildContext context,
  ) async {
    final cloud = context.read<CloudSyncService>();
    if (!cloud.isEnabled) return null;
    try {
      final snap = await CloudRetryPolicy.execute(
        () => FirebaseFirestore.instance
            .collection('community_mistakes')
            .orderBy('evLoss', descending: true)
            .limit(100)
            .get(),
      );
      final map = <String, SavedHand>{};
      for (final d in snap.docs) {
        final data = d.data();
        final hand = SavedHand.fromJson(Map<String, dynamic>.from(data));
        if (hand.corrected) continue;
        final key = hand.spotId ?? hand.name;
        map[key] ??= hand;
      }
      if (map.isEmpty) return null;
      final list = map.values.toList()
        ..sort((a, b) => (b.evLoss ?? 0).compareTo(a.evLoss ?? 0));
      final rng = Random();
      final count = min(list.length, 10 + rng.nextInt(6));
      final spots = [for (final h in list.take(count)) _spotFromHand(h)];
      return TrainingPackTemplate(
        id: const Uuid().v4(),
        name: 'Community Mistakes',
        spots: spots,
      );
    } catch (_) {
      return null;
    }
  }

  static TrainingPackTemplate createDrillFromHand(SavedHand hand) {
    final spot = _spotFromHand(hand);
    return TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Drill: ${hand.name}',
      spots: [spot],
    );
  }

  static Future<TrainingPackTemplate?> createDrillFromSimilarHands(
    BuildContext context,
    SavedHand referenceHand,
  ) async {
    final hands = context.read<SavedHandManagerService>().hands;
    final cat = referenceHand.category;
    final pos = referenceHand.heroPosition;
    final stack = referenceHand.stackSizes[referenceHand.heroIndex];
    if (cat == null || stack == null) return null;
    final list = [
      for (final h in hands)
        if (h != referenceHand &&
            h.category == cat &&
            h.heroPosition == pos &&
            h.stackSizes[h.heroIndex] == stack &&
            h.expectedAction != null &&
            h.gtoAction != null &&
            h.expectedAction!.trim().toLowerCase() !=
                h.gtoAction!.trim().toLowerCase())
          h,
    ];
    if (list.isEmpty) return null;
    list.shuffle();
    final rng = Random();
    final count = min(list.length, 4 + rng.nextInt(5));
    final selected = list.take(count).toList();
    final spots = [for (final h in selected) _spotFromHand(h)];
    return TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Similar Mistakes Drill',
      spots: spots,
    );
  }

  static Future<TrainingPackTemplate?> createSimilarMistakeDrill(
    SavedHand hand,
  ) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return null;
    return createDrillFromSimilarHands(ctx, hand);
  }

  static Future<TrainingPackTemplate> saveCustomSpot(
    TrainingPackSpot spot,
  ) async {
    final hero = spot.hand.stacks['0']?.round() ?? 0;
    final players = [
      for (int i = 0; i < spot.hand.playerCount; i++)
        (spot.hand.stacks['$i'] ?? 0).round(),
    ];
    final template = TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Custom Pack',
      heroBbStack: hero,
      playerStacksBb: players,
      heroPos: spot.hand.position,
      createdAt: DateTime.now(),
      spots: [spot],
    );
    final list = await TrainingPackStorage.load();
    list.add(template);
    await TrainingPackStorage.save(list);
    return template;
  }

  static Future<TrainingPackTemplate> createRangePack({
    required String name,
    required int minBb,
    required int maxBb,
    required List<int> playerStacksBb,
    required HeroPosition heroPos,
    required List<String> heroRange,
    int bbCallPct = 20,
    int anteBb = 0,
  }) async {
    final template = PackGeneratorService.generatePushFoldRangePack(
      id: const Uuid().v4(),
      name: name,
      minBb: minBb,
      maxBb: maxBb,
      playerStacksBb: playerStacksBb,
      heroPos: heroPos,
      heroRange: heroRange,
      bbCallPct: bbCallPct,
      anteBb: anteBb,
      createdAt: DateTime.now(),
    );
    final list = await TrainingPackStorage.load();
    list.add(template);
    await TrainingPackStorage.save(list);
    return template;
  }

  static Future<TrainingPackTemplate?> generateDefaultPersonalPack({
    CloudSyncService? cloud,
  }) async {
    final storage = SavedHandStorageService(cloud: cloud);
    await storage.load();
    final hands = storage.hands
        .where((h) => (h.evLoss?.abs() ?? 0) >= 1.0)
        .toList();
    if (hands.isEmpty) return null;
    hands.sort((a, b) => (b.evLoss ?? 0).compareTo(a.evLoss ?? 0));
    final spots = [for (final h in hands.take(20)) _spotFromHand(h)];
    final template = TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Personal Pack',
      createdAt: DateTime.now(),
      spots: spots,
    );
    final list = await TrainingPackStorage.load();
    list.add(template);
    await TrainingPackStorage.save(list);
    return template;
  }

  static Future<TrainingPackTemplate?> generateFreshMistakeDrill(
    BuildContext context,
  ) async {
    final hands = context.read<SavedHandManagerService>().hands;
    final list = [
      for (final h in hands)
        if (!h.corrected &&
            (h.evLoss?.abs() ?? 0) >= 1.0 &&
            h.expectedAction != null &&
            h.gtoAction != null &&
            h.expectedAction!.trim().toLowerCase() !=
                h.gtoAction!.trim().toLowerCase())
          h,
    ];
    if (list.isEmpty) return null;
    list.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    final spots = [for (final h in list.take(20)) _spotFromHand(h)];
    final template = TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Свежие ошибки',
      createdAt: DateTime.now(),
      spots: spots,
    );
    final stored = await TrainingPackStorage.load();
    stored.add(template);
    await TrainingPackStorage.save(stored);
    return template;
  }

  static Future<TrainingPackTemplate?> createSmartReviewDrill(
    BuildContext context,
  ) async {
    final templates = context.read<TemplateStorageService>().templates;
    final rng = Random();
    final spots = <TrainingPackSpot>[];
    bool bad(TrainingPackStat? s) {
      final acc = s?.accuracy ?? 1.0;
      final ev = s == null
          ? 100.0
          : (s.postEvPct > 0 ? s.postEvPct : s.preEvPct);
      final icm = s == null
          ? 100.0
          : (s.postIcmPct > 0 ? s.postIcmPct : s.preIcmPct);
      return acc < .6 || ev < 60 || icm < 60;
    }

    final practice = <TrainingPackTemplate>[];
    for (final t in templates) {
      final stat = await TrainingPackStatsService.getStats(t.id);
      if (bad(stat)) practice.add(t);
    }
    practice.shuffle();
    for (final t in practice) {
      final list = List<TrainingPackSpot>.from(t.spots)..shuffle();
      final count = min(list.length, 1 + rng.nextInt(list.length > 1 ? 2 : 1));
      spots.addAll(
        list.take(count).map((s) => s.copyWith(id: const Uuid().v4())),
      );
      if (spots.length >= 10) break;
    }
    if (spots.length < 10) {
      final recent = await TrainingPackStatsService.recentlyPractisedTemplates(
        templates,
      );
      for (final t in recent) {
        final stat = await TrainingPackStatsService.getStats(t.id);
        if (!bad(stat)) continue;
        final list = List<TrainingPackSpot>.from(t.spots)..shuffle();
        spots.add(list.first.copyWith(id: const Uuid().v4()));
        if (spots.length >= 10) break;
      }
    }
    if (spots.length < 10) {
      final stats = await TrainingPackStatsService.getCategoryStats();
      final cats = stats.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      for (final e in cats.take(3)) {
        final tag = 'cat:${e.key}';
        final list = <TrainingPackSpot>[];
        for (final t in templates) {
          for (final s in t.spots) {
            if (s.tags.contains(tag) || s.categories.contains(tag)) {
              list.add(s);
            }
          }
        }
        list.shuffle();
        if (list.isEmpty) continue;
        final count = min(
          list.length,
          1 + rng.nextInt(list.length > 1 ? 2 : 1),
        );
        spots.addAll(
          list.take(count).map((s) => s.copyWith(id: const Uuid().v4())),
        );
        if (spots.length >= 10) break;
      }
    }
    if (spots.length < 10) {
      final hands = context.read<SavedHandManagerService>().hands;
      final corrected = [
        for (final h in hands)
          if (h.corrected) h,
      ];
      corrected.shuffle();
      final count = min(corrected.length, 2);
      spots.addAll([for (final h in corrected.take(count)) _spotFromHand(h)]);
    }
    if (spots.isEmpty) return null;
    spots.shuffle();
    return TrainingPackTemplate(
      id: const Uuid().v4(),
      name: '📚 Умный повтор',
      createdAt: DateTime.now(),
      spots: spots.length > 10 ? spots.take(10).toList() : spots,
    );
  }
}
