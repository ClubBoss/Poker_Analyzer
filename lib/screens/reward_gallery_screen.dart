import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/reward_gallery_group_by_track_service.dart';

class RewardGalleryScreen extends StatefulWidget {
  static const route = '/rewards';
  const RewardGalleryScreen({super.key});

  @override
  State<RewardGalleryScreen> createState() => _RewardGalleryScreenState();
}

class _RewardGalleryScreenState extends State<RewardGalleryScreen> {
  late Future<List<TrackRewardGroup>> _future;

  @override
  void initState() {
    super.initState();
    _future =
        RewardGalleryGroupByTrackService.instance.getGroupedRewards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Награды')),
      body: FutureBuilder<List<TrackRewardGroup>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = snapshot.data!;
          if (groups.isEmpty) {
            return const Center(child: Text('Вы ещё не получили наград'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final g in groups) ...[
                ListTile(
                  leading:
                      const Icon(Icons.card_giftcard, color: Colors.orange),
                  title: Text(g.trackTitle),
                  trailing: IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => Share.share(
                      'Я только что завершил трек «${g.trackTitle}» в Poker Analyzer! 💪 Присоединяйся!',
                    ),
                  ),
                ),
                for (final r in g.rewards
                    .where((e) => e.stageIndex != null))
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 72, top: 4, bottom: 8),
                    child: Text('Этап ${r.stageIndex}'),
                  ),
              ]
            ],
          );
        },
      ),
    );
  }
}

