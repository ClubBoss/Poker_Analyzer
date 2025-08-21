import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tag_mastery_service.dart';
import '../services/learning_path_registry_service.dart';
import '../services/booster_thematic_descriptions.dart';
import '../models/learning_path_template_v2.dart';
import '../utils/responsive.dart';
import 'learning_path_screen_v2.dart';

/// Visual map of thematic learning blocks.
class PathMapScreen extends StatefulWidget {
  const PathMapScreen({super.key});

  @override
  State<PathMapScreen> createState() => _PathMapScreenState();
}

enum _SortOption { completion, weakness }

class _TagInfo {
  final String tag;
  final LearningPathTemplateV2? path;
  final String? stageId;
  double progress;

  _TagInfo({
    required this.tag,
    required this.path,
    required this.stageId,
    required this.progress,
  });
}

class _PathMapScreenState extends State<PathMapScreen> {
  bool _loading = true;
  _SortOption _sort = _SortOption.weakness;
  final List<_TagInfo> _tags = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final registry = LearningPathRegistryService.instance;
    final mastery = context.read<TagMasteryService>();
    final templates = await registry.loadAll();

    final tagToPath = <String, LearningPathTemplateV2>{};
    final tagToStage = <String, String?>{};
    for (final tpl in templates) {
      for (final stage in tpl.stages) {
        for (final tag in stage.tags) {
          final key = tag.trim();
          if (key.isEmpty) continue;
          tagToPath.putIfAbsent(key, () => tpl);
          tagToStage.putIfAbsent(key, () => stage.id);
        }
      }
      for (final tag in tpl.tags) {
        final key = tag.trim();
        if (key.isEmpty) continue;
        tagToPath.putIfAbsent(key, () => tpl);
      }
    }

    final masteryMap = await mastery.computeMastery();
    final tags = <String>{}
      ..addAll(tagToPath.keys)
      ..addAll(BoosterThematicDescriptions.tags);

    final list = <_TagInfo>[];
    for (final t in tags) {
      final prog = masteryMap[t.toLowerCase()] ?? 0.0;
      list.add(
        _TagInfo(
          tag: t,
          path: tagToPath[t],
          stageId: tagToStage[t],
          progress: prog,
        ),
      );
    }
    setState(() {
      _tags
        ..clear()
        ..addAll(list);
      _sortTags();
      _loading = false;
    });
  }

  void _sortTags() {
    _tags.sort((a, b) {
      switch (_sort) {
        case _SortOption.completion:
          return b.progress.compareTo(a.progress);
        case _SortOption.weakness:
        default:
          return a.progress.compareTo(b.progress);
      }
    });
  }

  void _changeSort(_SortOption option) {
    setState(() {
      _sort = option;
      _sortTags();
    });
  }

  void _openTag(_TagInfo info) {
    final path = info.path;
    if (path == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearningPathScreen(
          template: path,
          highlightedStageId: info.stageId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isLandscape(context)
        ? (isCompactWidth(context) ? 2 : 3)
        : (isCompactWidth(context) ? 1 : 2);
    return Scaffold(
      appBar: AppBar(
        title: const Text('🗺 Карта обучения'),
        actions: [
          PopupMenuButton<_SortOption>(
            onSelected: _changeSort,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _SortOption.weakness,
                child: Text('По слабости'),
              ),
              PopupMenuItem(
                value: _SortOption.completion,
                child: Text('По прогрессу'),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: _tags.length,
                itemBuilder: (context, index) {
                  final info = _tags[index];
                  final value = info.progress.clamp(0.0, 1.0);
                  final pct = (value * 100).round();
                  final title = BoosterThematicDescriptions.get(info.tag) ??
                      info.tag.replaceAll('_', ' ');
                  return Card(
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
                          LinearProgressIndicator(value: value),
                          const SizedBox(height: 4),
                          Text('$pct%', style: const TextStyle(fontSize: 12)),
                          const Spacer(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: info.path == null
                                  ? null
                                  : () => _openTag(info),
                              child: const Text('Перейти'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
