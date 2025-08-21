import 'package:flutter/material.dart';

import '../services/skill_tree_library_service.dart';
import '../services/skill_tree_track_state_evaluator.dart';
import '../services/skill_tree_completion_badge_service.dart';
import '../models/skill_tree_completion_badge.dart';
import 'skill_tree_track_launcher.dart';
import '../services/skill_tree_track_completion_celebrator.dart';

class _Entry {
  final TrackStateEntry state;
  final SkillTreeCompletionBadge badge;

  const _Entry({required this.state, required this.badge});
}

/// Displays all skill tree tracks with their status and progress.
class SkillTreeTrackListScreen extends StatefulWidget {
  static const route = '/skill-tree/tracks';
  final SkillTreeTrackStateEvaluator evaluator;
  final SkillTreeCompletionBadgeService badgeService;
  final bool reloadLibrary;

  const SkillTreeTrackListScreen({
    super.key,
    SkillTreeTrackStateEvaluator? evaluator,
    SkillTreeCompletionBadgeService? badgeService,
    this.reloadLibrary = true,
  })  : evaluator = evaluator ?? SkillTreeTrackStateEvaluator(),
        badgeService = badgeService ?? const SkillTreeCompletionBadgeService();

  @override
  State<SkillTreeTrackListScreen> createState() =>
      _SkillTreeTrackListScreenState();
}

class _SkillTreeTrackListScreenState extends State<SkillTreeTrackListScreen> {
  late Future<List<_Entry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_Entry>> _load() async {
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
    final badges = await widget.badgeService.getBadges();
    final badgeMap = {for (final b in badges) b.trackId: b};
    return [
      for (final s in states)
        _Entry(
          state: s,
          badge: badgeMap[s.progress.tree.nodes.values.first.category] ??
              SkillTreeCompletionBadge(
                trackId: s.progress.tree.nodes.values.first.category,
                percentComplete: s.progress.completionRate,
                isComplete: s.progress.isCompleted,
              ),
        ),
    ];
  }

  Future<void> _open(String trackId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SkillTreeTrackLauncher(trackId: trackId),
      ),
    );
    if (!mounted) return;
    setState(() => _future = _load());
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => SkillTreeTrackCompletionCelebrator.instance.maybeCelebrate(
        context,
        trackId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_Entry>>(
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
              final tree = entry.state.progress.tree;
              final trackId = tree.nodes.values.first.category;
              final title = tree.roots.isNotEmpty
                  ? tree.roots.first.title
                  : tree.nodes.values.first.title;
              final pct = (entry.badge.percentComplete * 100).round();
              Widget trailing;
              switch (entry.state.state) {
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

              final subtitle = entry.badge.isComplete
                  ? const Text('✅ Completed')
                  : Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: entry.badge.percentComplete.clamp(0.0, 1.0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('$pct%'),
                      ],
                    );

              return ListTile(
                title: Text(title),
                subtitle: subtitle,
                trailing: trailing,
                onTap: entry.state.state == SkillTreeTrackState.locked
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
