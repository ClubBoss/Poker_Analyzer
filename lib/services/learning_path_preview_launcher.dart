import 'package:flutter/material.dart';

import '../screens/learning_path_screen_v2.dart';
import 'learning_path_library.dart';
import '../utils/snackbar_util.dart';

/// Opens a staged learning path by [id] for preview.
class LearningPathPreviewLauncher {
  const LearningPathPreviewLauncher();

  Future<void> launch(BuildContext context, String id) async {
    final template = LearningPathLibrary.staging.getById(id);
    if (template == null) {
      SnackbarUtil.showMessage(context, 'Path not found: $id');
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearningPathScreen(template: template),
      ),
    );
  }
}
