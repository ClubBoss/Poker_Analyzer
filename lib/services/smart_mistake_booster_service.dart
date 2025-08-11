import 'package:flutter/material.dart';

import '../models/mistake_tag_history_entry.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/theory_yaml_importer.dart';
import 'training_session_service.dart';
import '../screens/training_session_screen.dart';
import 'package:provider/provider.dart';

class SmartMistakeBoosterService {
  const SmartMistakeBoosterService();

  Future<void> launchBoosterIfAvailable(
    MistakeTagHistoryEntry mistake,
    BuildContext context, {
    String dir = 'yaml_out/boosters',
  }) async {
    const importer = TheoryYamlImporter();
    final packs = await importer.importFromDirectory(dir);
    if (packs.isEmpty) return;

    final tags = {for (final t in mistake.tags) t.label.toLowerCase()};
    TrainingPackTemplateV2? booster;
    for (final p in packs) {
      final meta = p.meta;
      if (meta['generatedBy'] != 'BoosterPackLibraryBuilder v1') continue;
      final packTags = {for (final t in p.tags) t.toLowerCase()};
      if (packTags.intersection(tags).isNotEmpty) {
        booster = p;
        break;
      }
    }

    if (booster != null) {
      await context.read<TrainingSessionService>().startSession(booster);
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
      );
    }
  }
}

