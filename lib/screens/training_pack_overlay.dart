import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/training_pack.dart';

class TrainingPackOverlay extends StatelessWidget {
  final TrainingPack pack;

  const TrainingPackOverlay({super.key, required this.pack});

  Widget _buildFab(String heroTag, IconData icon, VoidCallback onPressed) {
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onPressed,
      child: Icon(icon),
    );
  }

  Future<void> _export(BuildContext context) async {
    // TODO: implement export logic
  }

  Future<void> _share(BuildContext context) async {
    await Share.share('Training pack: ${pack.name}');
  }

  Future<void> _print(BuildContext context) async {
    // TODO: implement print logic
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFab('export', Icons.save, () => _export(context)),
        const SizedBox(height: 8),
        _buildFab('share', Icons.share, () => _share(context)),
        const SizedBox(height: 8),
        _buildFab('print', Icons.print, () => _print(context)),
      ],
    );
  }
}

