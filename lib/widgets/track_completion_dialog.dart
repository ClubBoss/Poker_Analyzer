import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/reward_card_renderer_service.dart';

class TrackCompletionDialog extends StatefulWidget {
  final String trackId;
  const TrackCompletionDialog({super.key, required this.trackId});

  static Future<void> show(BuildContext context, String trackId) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TrackCompletionDialog(trackId: trackId),
    );
  }

  @override
  State<TrackCompletionDialog> createState() => _TrackCompletionDialogState();
}

class _TrackCompletionDialogState extends State<TrackCompletionDialog> {
  late final Future<RewardCardRendererService> _rendererFuture;

  @override
  void initState() {
    super.initState();
    _rendererFuture = RewardCardRendererService.create();
  }

  Future<void> _share(RewardCardRendererService renderer) async {
    final bytes = await renderer.exportImage(widget.trackId);
    if (bytes.isEmpty) return;
    final file = XFile.fromData(
      bytes,
      mimeType: 'image/png',
      name: 'reward.png',
    );
    await Share.shareXFiles([file]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RewardCardRendererService>(
      future: _rendererFuture,
      builder: (context, snapshot) {
        final renderer = snapshot.data;
        return AlertDialog(
          content: SizedBox(
            width: 320,
            child:
                snapshot.connectionState == ConnectionState.done &&
                    renderer != null
                ? renderer.buildCard(widget.trackId)
                : const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: renderer == null ? null : () => _share(renderer),
              child: const Text('Поделиться'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }
}
