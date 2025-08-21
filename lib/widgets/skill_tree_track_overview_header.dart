import 'package:flutter/material.dart';

import '../services/skill_tree_library_service.dart';
import '../services/skill_tree_path_progress_estimator.dart';
import '../route_observer.dart';

/// Displays track title with overall completion percentage.
class SkillTreeTrackOverviewHeader extends StatefulWidget {
  final String trackId;

  const SkillTreeTrackOverviewHeader({super.key, required this.trackId});

  @override
  State<SkillTreeTrackOverviewHeader> createState() =>
      _SkillTreeTrackOverviewHeaderState();
}

class _SkillTreeTrackOverviewHeaderState
    extends State<SkillTreeTrackOverviewHeader> with RouteAware {
  String _title = '';
  int _percent = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final library = SkillTreeLibraryService.instance;
    await library.reload();
    final track = library.getTrack(widget.trackId)?.tree;
    String title;
    if (track != null && track.nodes.isNotEmpty) {
      title = track.roots.isNotEmpty
          ? track.roots.first.title
          : track.nodes.values.first.title;
    } else {
      title = widget.trackId;
    }
    final estimator = SkillTreePathProgressEstimator(library: library);
    final pct = await estimator.getProgressPercent(widget.trackId);
    if (!mounted) return;
    setState(() {
      _title = title;
      _percent = pct;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text('Прогресс: $_percent%'),
      ],
    );
  }
}
