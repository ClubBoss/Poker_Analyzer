import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_template.dart';
import '../screens/training_session_screen.dart';
import 'training_session_service.dart';

class BoosterPreviewLauncher {
  const BoosterPreviewLauncher();

  Future<void> launch(BuildContext context, TrainingPackTemplateV2 pack) async {
    final template = TrainingPackTemplate.fromJson(pack.toJson());
    await context.read<TrainingSessionService>().startSession(
      template,
      persist: false,
    );
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }
}
