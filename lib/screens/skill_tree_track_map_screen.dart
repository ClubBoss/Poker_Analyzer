import 'package:flutter/material.dart';
import '../services/skill_tree_learning_map_layout_service.dart';
import '../services/skill_tree_track_progress_service.dart';
import 'skill_tree_screen.dart';
import '../utils/responsive.dart';

/// Displays all skill tree tracks in a scrollable grid layout.
class SkillTreeTrackMapScreen extends StatefulWidget {
  static const route = '/learning-map';
  const SkillTreeTrackMapScreen({super.key});

  @override
  State<SkillTreeTrackMapScreen> createState() =>
      _SkillTreeTrackMapScreenState();
}

class _SkillTreeTrackMapScreenState extends State<SkillTreeTrackMapScreen> {
  late Future<List<List<TrackProgressEntry>>> _future;
  late int _columns;

  @override
  void initState() {
    super.initState();
    // columns computed later in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _columns = isLandscape(context)
        ? (isCompactWidth(context) ? 2 : 3)
        : (isCompactWidth(context) ? 1 : 2);
    _future = SkillTreeLearningMapLayoutService().buildLayout(
      columns: _columns,
    );
  }

  void _openTrack(TrackProgressEntry entry) {
    final category = entry.tree.nodes.values.first.category;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SkillTreeScreen(category: category)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<List<List<TrackProgressEntry>>>(
      future: _future,
      builder: (context, snapshot) {
        final grid = snapshot.data ?? const <List<TrackProgressEntry>>[];
        final list = [for (final row in grid) ...row];
        return Scaffold(
          appBar: AppBar(title: const Text('Карта обучения')),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : list.isEmpty
              ? const Center(child: Text('Нет треков'))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final entry = list[index];
                    final title = entry.tree.roots.isNotEmpty
                        ? entry.tree.roots.first.title
                        : entry.tree.nodes.values.first.title;
                    final pct = entry.completionRate.clamp(0.0, 1.0);
                    return GestureDetector(
                      onTap: () => _openTrack(entry),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: Colors.white24,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    accent,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${(pct * 100).round()}%',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (entry.isCompleted)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
