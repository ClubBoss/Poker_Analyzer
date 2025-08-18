import 'package:flutter/material.dart';

import '../screens/learning_path_screen_v2.dart';
import 'learning_path_library.dart';

/// Opens a staged learning path by [id] for preview.
class LearningPathPreviewLauncher {
  const LearningPathPreviewLauncher();

  Future<void> launch(BuildContext context, String id) async {
    final template = LearningPathLibrary.staging.getById(id);
    if (template == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Path not found: $id')));
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LearningPathScreen(template: template)),
    );
  }
}
