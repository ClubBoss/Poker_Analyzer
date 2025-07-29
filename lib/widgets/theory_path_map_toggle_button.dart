import 'package:flutter/material.dart';

import '../models/player_profile.dart';
import '../models/theory_lesson_cluster.dart';
import '../models/theory_mini_lesson_node.dart';
import '../services/theory_lesson_tag_clusterer.dart';
import '../services/theory_mini_map_renderer.dart';
import 'theory_cluster_map_overlay.dart';

/// Floating button that toggles the cluster map overlay.
class TheoryPathMapToggleButton extends StatefulWidget {
  final TheoryMiniLessonNode lesson;
  final PlayerProfile? profile;

  const TheoryPathMapToggleButton({
    super.key,
    required this.lesson,
    this.profile,
  });

  @override
  State<TheoryPathMapToggleButton> createState() =>
      _TheoryPathMapToggleButtonState();
}

class _TheoryPathMapToggleButtonState extends State<TheoryPathMapToggleButton> {
  OverlayEntry? _entry;
  bool _open = false;
  TheoryLessonCluster? _cluster;

  Future<void> _ensureCluster() async {
    if (_cluster != null) return;
    final clusterer = TheoryLessonTagClusterer();
    final clusters = await clusterer.clusterLessons();
    for (final c in clusters) {
      if (c.lessons.any((l) => l.id == widget.lesson.id)) {
        _cluster = c;
        break;
      }
    }
  }

  Future<void> _openOverlay() async {
    await _ensureCluster();
    final cluster = _cluster;
    if (cluster == null) return;
    final graph = TheoryMiniMapRenderer(cluster).build(widget.lesson.id);
    final overlay = OverlayEntry(
      builder: (_) => TheoryClusterMapOverlay(
        graph: graph,
        profile: widget.profile ?? PlayerProfile(),
        lessons: cluster.lessons,
      ),
    );
    Overlay.of(context).insert(overlay);
    _entry = overlay;
    setState(() => _open = true);
  }

  void _closeOverlay() {
    _entry?.remove();
    _entry = null;
    setState(() => _open = false);
  }

  void _toggle() {
    if (_open) {
      _closeOverlay();
    } else {
      _openOverlay();
    }
  }

  @override
  void dispose() {
    _closeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton(
        mini: true,
        onPressed: _toggle,
        tooltip: 'Карта уроков',
        child: Text(_open ? '❌' : '🗺'),
      ),
    );
  }
}
