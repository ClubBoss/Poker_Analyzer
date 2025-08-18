import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../core/training/library/training_pack_library_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'pack_library_service.dart';
import 'skill_map_booster_recommender.dart';
import 'tag_mastery_service.dart';
import 'training_session_launcher.dart';

class BoosterPackLauncher {
  final TagMasteryService mastery;
  final PackLibraryService library;
  final SkillMapBoosterRecommender recommender;
  final TrainingSessionLauncher launcher;

  const BoosterPackLauncher({
    required this.mastery,
    this.library = PackLibraryService.instance,
    SkillMapBoosterRecommender? recommender,
    this.launcher = const TrainingSessionLauncher(),
  }) : recommender = recommender ?? SkillMapBoosterRecommender();

  Future<void> launchBooster(BuildContext context) async {
    final weakTags = await recommender.getWeakTags(mastery: mastery);
    await TrainingPackLibraryV2.instance.loadFromFolder();
    final packs = TrainingPackLibraryV2.instance.filterBy(
      type: TrainingType.pushFold,
    );
    TrainingPackTemplateV2? pack;
    for (final tag in weakTags) {
      pack = packs.firstWhereOrNull((p) => p.tags.contains(tag));
      if (pack != null) break;
    }
    if (pack != null) {
      await launcher.launch(pack);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Нет подходящих бустеров')));
    }
  }
}
