import 'package:uuid/uuid.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hero_position.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import 'tag_mastery_service.dart';

class TrainingPackTemplateBuilder {
  const TrainingPackTemplateBuilder();

  Future<TrainingPackTemplateV2> buildSimplifiedPack(
    List<TrainingPackSpot> mistakes,
    TagMasteryService mastery,
  ) async {
    await TrainingPackLibraryV2.instance.reload();
    final library = TrainingPackLibraryV2.instance.packs;

    final base = mistakes.take(3).toList();
    final spots = <TrainingPackSpot>[...base];
    final weakTags = await mastery.topWeakTags(2);
    for (final m in base) {
      TrainingPackSpot? added;
      for (final tpl in library) {
        for (final s in tpl.spots) {
          if (s.hand.position == m.hand.position && s.street == m.street) {
            final tags = [for (final t in s.tags) t.toLowerCase()];
            final hasWeak = weakTags.any((t) => tags.contains(t));
            if (hasWeak) {
              added = TrainingPackSpot.fromJson(s.toJson());
              break;
            }
            added ??= TrainingPackSpot.fromJson(s.toJson());
          }
        }
        if (added != null) break;
      }
      if (added != null && !spots.any((e) => e.id == added.id)) {
        spots.add(added);
      }
      if (spots.length >= base.length + 3) break;
    }

    final positions = <HeroPosition>{for (final s in spots) s.hand.position};
    final tagLabel = weakTags.isNotEmpty ? weakTags.first : 'основ';
    final tpl = TrainingPackTemplateV2(
      id: const Uuid().v4(),
      name: 'Закрепление: $tagLabel',
      description: weakTags.isNotEmpty
          ? 'Подборка для отработки слабого места: $tagLabel'
          : '',
      trainingType: TrainingType.pushFold,
      tags: List<String>.from(weakTags),
      spots: spots,
      spotCount: spots.length,
      created: DateTime.now(),
      gameType: GameType.tournament,
      bb: 0,
      positions: [for (final p in positions) p.name],
    );
    tpl.trainingType = const TrainingTypeEngine().detectTrainingType(tpl);
    return tpl;
  }

  Future<TrainingPackTemplateV2> buildAdvancedPack(
    TagMasteryService mastery,
  ) async {
    await TrainingPackLibraryV2.instance.reload();
    final library = TrainingPackLibraryV2.instance.packs;

    final strong = await mastery.topStrongTags(3);
    const advTags = {'advanced', 'deepstack', 'multiway', 'vs reg'};
    final spots = <TrainingPackSpot>[];

    for (final tpl in library) {
      final tplTags = [for (final t in tpl.tags) t.toLowerCase()];
      if (!tplTags.any((t) => advTags.contains(t))) continue;
      if (!tplTags.any((t) => strong.contains(t))) continue;
      for (final s in tpl.spots) {
        final tags = [for (final t in s.tags) t.toLowerCase()];
        if (tags.any((t) => advTags.contains(t)) &&
            tags.any((t) => strong.contains(t))) {
          final spot = TrainingPackSpot.fromJson(s.toJson())..isNew = true;
          if (!spots.any((e) => e.id == spot.id)) spots.add(spot);
        }
        if (spots.length >= 6) break;
      }
      if (spots.length >= 6) break;
    }

    if (spots.isEmpty) {
      // Fallback: any advanced spots
      for (final tpl in library) {
        final tplTags = [for (final t in tpl.tags) t.toLowerCase()];
        if (!tplTags.any((t) => advTags.contains(t))) continue;
        for (final s in tpl.spots) {
          final tags = [for (final t in s.tags) t.toLowerCase()];
          if (tags.any((t) => advTags.contains(t))) {
            final spot = TrainingPackSpot.fromJson(s.toJson())..isNew = true;
            if (!spots.any((e) => e.id == spot.id)) spots.add(spot);
          }
          if (spots.length >= 6) break;
        }
        if (spots.length >= 6) break;
      }
    }

    final positions = <HeroPosition>{for (final s in spots) s.hand.position};
    final tpl = TrainingPackTemplateV2(
      id: const Uuid().v4(),
      name: 'Новый уровень: 3bet defense',
      description:
          'Подборка сложных ситуаций в вашей сильной категории: 3bet defense',
      trainingType: TrainingType.pushFold,
      tags: List<String>.from(strong),
      spots: spots,
      spotCount: spots.length,
      created: DateTime.now(),
      gameType: GameType.tournament,
      bb: 0,
      positions: [for (final p in positions) p.name],
    );
    tpl.trainingType = const TrainingTypeEngine().detectTrainingType(tpl);
    return tpl;
  }

  /// Builds a temporary pack targeting weakest categories.
  Future<TrainingPackTemplateV2> buildWeaknessPack(
    TagMasteryService mastery,
  ) async {
    await TrainingPackLibraryV2.instance.reload();
    final library = TrainingPackLibraryV2.instance.packs;

    final weak = await mastery.bottomWeakTags(3);
    final spots = <TrainingPackSpot>[];
    final used = <String>{};

    for (final tpl in library) {
      for (final s in tpl.spots) {
        final tags = [for (final t in s.tags) t.toLowerCase()];
        final count = weak.where((t) => tags.contains(t)).length;
        if (count >= 2 && !used.contains(s.id)) {
          spots.add(TrainingPackSpot.fromJson(s.toJson())..isNew = true);
          used.add(s.id);
        }
        if (spots.length >= 6) break;
      }
      if (spots.length >= 6) break;
    }

    if (spots.length < 6) {
      for (final tpl in library) {
        for (final s in tpl.spots) {
          final tags = [for (final t in s.tags) t.toLowerCase()];
          if (tags.any((t) => weak.contains(t)) && !used.contains(s.id)) {
            spots.add(TrainingPackSpot.fromJson(s.toJson())..isNew = true);
            used.add(s.id);
          }
          if (spots.length >= 6) break;
        }
        if (spots.length >= 6) break;
      }
    }

    final positions = <HeroPosition>{for (final s in spots) s.hand.position};
    final tagLabel = weak.isNotEmpty ? weak.first : 'разное';
    final tpl = TrainingPackTemplateV2(
      id: const Uuid().v4(),
      name: 'Уязвимость: $tagLabel',
      description: 'Ситуации, где вы чаще ошибались. Работайте точечно.',
      trainingType: TrainingType.pushFold,
      tags: List<String>.from(weak),
      spots: spots,
      spotCount: spots.length,
      created: DateTime.now(),
      gameType: GameType.tournament,
      bb: 0,
      positions: [for (final p in positions) p.name],
    );
    tpl.trainingType = const TrainingTypeEngine().detectTrainingType(tpl);
    return tpl;
  }
}
