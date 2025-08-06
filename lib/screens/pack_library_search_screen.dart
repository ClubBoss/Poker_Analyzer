import 'package:flutter/material.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';
import '../widgets/pack_card.dart';
import '../widgets/training_pack_template_tooltip_widget.dart';
import '../widgets/training_pack_library_metadata_filter_bar.dart';
import '../widgets/training_pack_library_sort_bar.dart';
import '../models/v2/pack_ux_metadata.dart';
import 'training_pack_preview_screen.dart';
import '../services/lazy_pack_loader_service.dart';

class PackLibrarySearchScreen extends StatefulWidget {
  const PackLibrarySearchScreen({super.key});

  @override
  State<PackLibrarySearchScreen> createState() => _PackLibrarySearchScreenState();
}

class _PackLibrarySearchScreenState extends State<PackLibrarySearchScreen> {
  List<TrainingPackTemplateV2> _all = [];
  List<TrainingPackTemplateV2> _results = [];
  bool _loading = true;
  TrainingPackLevel? _level;
  TrainingPackTopic? _topic;
  TrainingPackFormat? _format;
  List<TrainingPackTopic> _topics = TrainingPackTopic.values;
  TrainingPackSortOption _sort = TrainingPackSortOption.nameAsc;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await LazyPackLoaderService.instance.preloadMetadata();
    _all = LazyPackLoaderService.instance.templates;
    _topics = _availableTopics();
    _applyFilters();
    setState(() {
      _loading = false;
    });
  }

  List<TrainingPackTopic> _availableTopics([TrainingPackLevel? level]) {
    final set = <TrainingPackTopic>{};
    for (final p in _all) {
      final lvl = p.meta['level']?.toString();
      if (level != null && lvl != level.name) continue;
      final topic = p.meta['topic']?.toString();
      if (topic == null) continue;
      try {
        set.add(TrainingPackTopic.values.byName(topic));
      } catch (_) {}
    }
    final list = set.toList()..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  void _applyFilters() {
    List<TrainingPackTemplateV2> list = _all;
    if (_level != null || _topic != null || _format != null) {
      list = _all.where((p) {
        final meta = p.meta;
        final levelStr = meta['level']?.toString();
        final topicStr = meta['topic']?.toString();
        final formatStr = meta['format']?.toString();
        final levelOk = _level == null || levelStr == _level!.name;
        final topicOk = _topic == null || topicStr == _topic!.name;
        final formatOk = _format == null || formatStr == _format!.name;
        return levelOk && topicOk && formatOk;
      }).toList();
    }
    list.sort((a, b) {
      if (_sort == TrainingPackSortOption.nameAsc) {
        return a.name.compareTo(b.name);
      } else {
        return complexityRank(a) - complexityRank(b);
      }
    });
    _topics = _availableTopics(_level);
    if (_topic != null && !_topics.contains(_topic)) {
      _topic = null;
    }
    setState(() => _results = list);
  }

  void _onLevelChanged(TrainingPackLevel? value) {
    setState(() => _level = value);
    _applyFilters();
  }

  void _onTopicChanged(TrainingPackTopic? value) {
    setState(() => _topic = value);
    _applyFilters();
  }

  void _onFormatChanged(TrainingPackFormat? value) {
    setState(() => _format = value);
    _applyFilters();
  }

  void _onSortChanged(TrainingPackSortOption value) {
    setState(() => _sort = value);
    _applyFilters();
  }

  Future<void> _open(TrainingPackTemplateV2 tpl) async {
    final loader = LazyPackLoaderService.instance;
    final full = await loader.loadFullPack(tpl.id) ?? tpl;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackPreviewScreen(template: full),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Search Library')),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          TrainingPackLibraryMetadataFilterBar(
            level: _level,
            topic: _topic,
            format: _format,
            topics: _topics,
            onLevelChanged: _onLevelChanged,
            onTopicChanged: _onTopicChanged,
            onFormatChanged: _onFormatChanged,
          ),
          TrainingPackLibrarySortBar(
            sort: _sort,
            onSortChanged: _onSortChanged,
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final tpl = _results[index];
                return TrainingPackTemplateTooltipWidget(
                  template: tpl,
                  child: PackCard(
                    template: tpl,
                    onTap: () => _open(tpl),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

int complexityRank(TrainingPackTemplateV2 p) {
  final c = p.meta['complexity']?.toString();
  switch (c) {
    case 'simple':
      return 0;
    case 'intermediate':
      return 1;
    case 'advanced':
      return 2;
    default:
      return 999;
  }
}
