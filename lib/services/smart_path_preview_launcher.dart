import 'package:flutter/material.dart';

import '../models/learning_path_template_v2.dart';
import '../screens/smart_path_preview_screen.dart';

/// Launches a lightweight preview of the given [LearningPathTemplateV2].
class SmartPathPreviewLauncher {
  const SmartPathPreviewLauncher();

  Future<void> launch(BuildContext context, LearningPathTemplateV2 path) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SmartPathPreviewScreen(path: path),
      ),
    );
  }
}
