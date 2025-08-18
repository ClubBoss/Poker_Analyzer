import 'package:flutter/material.dart';

import '../services/theory_lesson_tag_clusterer.dart';
import '../services/theory_cluster_progress_service.dart';
import '../widgets/theory_cluster_summary_card.dart';
import 'theory_cluster_detail_screen.dart';

/// Dashboard listing all theory clusters with progress.
class TheoryClusterDashboardScreen extends StatefulWidget {
  const TheoryClusterDashboardScreen({super.key});

  @override
  State<TheoryClusterDashboardScreen> createState() =>
      _TheoryClusterDashboardScreenState();
}

class _TheoryClusterDashboardScreenState
    extends State<TheoryClusterDashboardScreen> {
  bool _loading = true;
  List<ClusterProgress> _data = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final clusterer = TheoryLessonTagClusterer();
    final clusters = await clusterer.clusterLessons();
    final progress = await const TheoryClusterProgressService().computeProgress(
      clusters,
    );
    if (!mounted) return;
    setState(() {
      _data = progress;
      _loading = false;
    });
  }

  Future<void> _openCluster(ClusterProgress c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TheoryClusterDetailScreen(cluster: c.cluster, progress: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theory Clusters')),
      backgroundColor: const Color(0xFF121212),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final c in _data)
                  TheoryClusterSummaryCard(
                    progress: c,
                    onTap: () => _openCluster(c),
                  ),
              ],
            ),
    );
  }
}
