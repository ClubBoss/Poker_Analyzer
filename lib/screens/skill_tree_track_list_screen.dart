import 'package:flutter/material.dart';

import '../services/skill_tree_library_service.dart';
import '../services/skill_tree_track_state_evaluator.dart';
import 'skill_tree_track_launcher.dart';

/// Displays all skill tree tracks with their status and progress.
class SkillTreeTrackListScreen extends StatefulWidget {
  static const route = '/skill-tree/tracks';
  final SkillTreeTrackStateEvaluator evaluator;
  final bool reloadLibrary;

  const SkillTreeTrackListScreen({
    super.key,
    SkillTreeTrackStateEvaluator? evaluator,
    this.reloadLibrary = true,
  }) : evaluator = evaluator ?? SkillTreeTrackStateEvaluator();

  @override
  State<SkillTreeTrackListScreen> createState() => _SkillTreeTrackListScreenState();
}

class _SkillTreeTrackListScreenState extends State<SkillTreeTrackListScreen> {
  late Future<List<TrackStateEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<TrackStateEntry>> _load() async {
    if (widget.reloadLibrary) {
      await SkillTreeLibraryService.instance.reload();
    }
    final states = await widget.evaluator.evaluateStates();
    states.sort((a, b) {
      int order(SkillTreeTrackState s) {
        switch (s) {
          case SkillTreeTrackState.unlocked:
            return 0;
          case SkillTreeTrackState.inProgress:
            return 1;
          case SkillTreeTrackState.completed:
            return 2;
          case SkillTreeTrackState.locked:
            return 3;
        }
      }

      final cmp = order(a.state).compareTo(order(b.state));
      if (cmp != 0) return cmp;
      final catA = a.progress.tree.nodes.values.first.category;
      final catB = b.progress.tree.nodes.values.first.category;
      return catA.compareTo(catB);
    });
    return states;
  }

  void _open(String trackId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SkillTreeTrackLauncher(trackId: trackId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TrackStateEntry>>(
      future: _future,
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (list.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Треки')),
            body: const Center(child: Text('Нет треков')),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Треки')),
          body: ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = list[index];
              final tree = entry.progress.tree;
              final trackId = tree.nodes.values.first.category;
              final title = tree.roots.isNotEmpty
                  ? tree.roots.first.title
                  : tree.nodes.values.first.title;
              final pct = (entry.progress.completionRate * 100).round();
              Widget trailing;
              switch (entry.state) {
                case SkillTreeTrackState.locked:
                  trailing = const Icon(Icons.lock);
                  break;
                case SkillTreeTrackState.completed:
                  trailing = ElevatedButton(
                    onPressed: () => _open(trackId),
                    child: const Text('Открыть'),
                  );
                  break;
                case SkillTreeTrackState.inProgress:
                  trailing = ElevatedButton(
                    onPressed: () => _open(trackId),
                    child: const Text('Продолжить'),
                  );
                  break;
                case SkillTreeTrackState.unlocked:
                  trailing = ElevatedButton(
                    onPressed: () => _open(trackId),
                    child: const Text('Начать'),
                  );
                  break;
              }

              return ListTile(
                title: Text(title),
                subtitle: Text('$pct%'),
                trailing: trailing,
                onTap: entry.state == SkillTreeTrackState.locked
                    ? null
                    : () => _open(trackId),
              );
            },
          ),
        );
      },
    );
  }
}
