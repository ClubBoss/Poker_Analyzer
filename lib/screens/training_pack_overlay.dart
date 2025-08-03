import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/training_pack.dart';

class TrainingPackOverlay extends StatelessWidget {
  final TrainingPack pack;

  const TrainingPackOverlay({super.key, required this.pack});

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
        FloatingActionButton(
          heroTag: 'export',
          onPressed: () => _export(context),
          child: const Icon(Icons.save),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'share',
          onPressed: () => _share(context),
          child: const Icon(Icons.share),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'print',
          onPressed: () => _print(context),
          child: const Icon(Icons.print),
        ),
      ],
    );
  }
}

