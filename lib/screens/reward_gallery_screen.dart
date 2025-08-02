import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/skill_tree_library_service.dart';

class RewardGalleryScreen extends StatefulWidget {
  static const route = '/rewards';
  const RewardGalleryScreen({super.key});

  @override
  State<RewardGalleryScreen> createState() => _RewardGalleryScreenState();
}

class _RewardGalleryScreenState extends State<RewardGalleryScreen> {
  late Future<List<_RewardItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadRewards();
  }

  Future<List<_RewardItem>> _loadRewards() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final library = SkillTreeLibraryService.instance;
    if (library.getAllTracks().isEmpty) {
      await library.reload();
    }
    final rewards = <_RewardItem>[];
    const prefix = 'reward_granted_';
    for (final k in keys) {
      if (k.startsWith(prefix) && (prefs.getBool(k) ?? false)) {
        final id = k.substring(prefix.length);
        final title = _resolveTrackTitle(library, id);
        rewards.add(_RewardItem(id: id, title: title));
      }
    }
    rewards.sort((a, b) => a.title.compareTo(b.title));
    return rewards;
  }

  String _resolveTrackTitle(SkillTreeLibraryService library, String trackId) {
    final track = library.getTrack(trackId)?.tree;
    if (track == null) return trackId;
    if (track.roots.isNotEmpty) return track.roots.first.title;
    if (track.nodes.isNotEmpty) return track.nodes.values.first.title;
    return trackId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Награды')),
      body: FutureBuilder<List<_RewardItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text('Вы ещё не получили наград'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final r = items[index];
              return ListTile(
                leading: const Icon(Icons.card_giftcard, color: Colors.orange),
                title: Text(r.title),
              );
            },
          );
        },
      ),
    );
  }
}

class _RewardItem {
  final String id;
  final String title;
  const _RewardItem({required this.id, required this.title});
}

