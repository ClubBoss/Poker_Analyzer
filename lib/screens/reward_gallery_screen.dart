import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/reward_card_renderer_service.dart';
import '../services/reward_gallery_group_by_track_service.dart';

class RewardGalleryScreen extends StatefulWidget {
  static const route = '/rewards';
  const RewardGalleryScreen({super.key});

  @override
  State<RewardGalleryScreen> createState() => _RewardGalleryScreenState();
}

class _RewardGalleryScreenState extends State<RewardGalleryScreen> {
  late Future<List<TrackRewardGroup>> _future;
  late final Future<RewardCardRendererService> _rendererFuture;

  @override
  void initState() {
    super.initState();
    _future = RewardGalleryGroupByTrackService.instance.getGroupedRewards();
    _rendererFuture = RewardCardRendererService.create();
  }

  void _reload() {
    setState(() {
      _future = RewardGalleryGroupByTrackService.instance.getGroupedRewards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Награды')),
      body: FutureBuilder<List<TrackRewardGroup>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Не удалось загрузить награды'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }
          final groups = snapshot.data ?? const <TrackRewardGroup>[];
          if (groups.isEmpty) {
            return const Center(child: Text('Вы ещё не получили наград'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final g in groups) ...[
                ListTile(
                  leading: const Icon(Icons.card_giftcard, color: Colors.orange),
                  title: Text(g.trackTitle),
                  trailing: IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () async {
                      final renderer = await _rendererFuture;
                      final nav = Navigator.of(context);
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const AlertDialog(
                          content: Text('Генерация изображения...'),
                        ),
                      );
                      try {
                        final img = await renderer.exportImage(g.trackId);
                        nav.pop();
                        if (img.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Не удалось сгенерировать карточку'),
                            ),
                          );
                          return;
                        }
                        await Share.shareXFiles(
                          [XFile.fromData(img, mimeType: 'image/png')],
                          text:
                              'Я только что завершил трек «${g.trackTitle}» в Poker Analyzer! 💪 Присоединяйся!',
                        );
                      } catch (_) {
                        nav.pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Не удалось сгенерировать карточку'),
                          ),
                        );
                      }
                    },
                  ),
                ),
                for (final r in g.rewards.where((e) => e.stageIndex != null))
                  Padding(
                    padding: const EdgeInsets.only(left: 72, top: 4, bottom: 8),
                    child: Text('Этап ${r.stageIndex}'),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
