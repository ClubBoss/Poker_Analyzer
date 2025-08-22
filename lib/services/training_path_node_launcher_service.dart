import 'package:flutter/material.dart';

import '../models/training_path_node.dart';
import '../screens/v2/training_pack_play_screen.dart';
import 'pack_library_template_loader.dart';

/// Launches the first available training pack for a [TrainingPathNode].
class TrainingPathNodeLauncherService {
  TrainingPathNodeLauncherService();

  /// Finds the first pack in [node] and opens it in [TrainingPackPlayScreen].
  Future<void> launchNode(BuildContext context, TrainingPathNode node) async {
    if (node.packIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Training pack not found')));
      return;
    }

    final template = await PackLibraryTemplateLoader.load(node.packIds.first);
    if (template == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Training pack not found')));
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackPlayScreen(template: template),
      ),
    );
  }
}
