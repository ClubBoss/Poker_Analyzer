import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tag_coverage_service.dart';
import '../utils/responsive.dart';
import '../widgets/tag_coverage_tile.dart';
import 'tag_insight_screen.dart';

class LessonTagHeatmapScreen extends StatefulWidget {
  const LessonTagHeatmapScreen({super.key});

  @override
  State<LessonTagHeatmapScreen> createState() => _LessonTagHeatmapScreenState();
}

class _LessonTagHeatmapScreenState extends State<LessonTagHeatmapScreen> {
  bool _loading = true;
  Map<String, int> _data = {};
  bool _sortByCount = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final service = context.read<TagCoverageService>();
    final map = await service.computeTagCoverage();
    final entries = map.entries.toList();
    _sort(entries);
    setState(() {
      _data = {for (final e in entries) e.key: e.value};
      _loading = false;
    });
  }

  void _sort(List<MapEntry<String, int>> list) {
    if (_sortByCount) {
      list.sort((a, b) => b.value.compareTo(a.value));
    } else {
      list.sort((a, b) => a.key.compareTo(b.key));
    }
  }

  void _toggleSort() {
    setState(() {
      _sortByCount = !_sortByCount;
      final entries = _data.entries.toList();
      _sort(entries);
      _data = {for (final e in entries) e.key: e.value};
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxCount = _data.values.fold<int>(0, (p, e) => e > p ? e : p);
    final crossAxisCount = isLandscape(context)
        ? (isCompactWidth(context) ? 6 : 8)
        : (isCompactWidth(context) ? 3 : 4);
    final tagCount = _data.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('Покрытие тем ($tagCount)'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: _toggleSort,
            icon: Icon(_sortByCount ? Icons.sort_by_alpha : Icons.bar_chart),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _data.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final entry = _data.entries.elementAt(index);
                return TagCoverageTile(
                  tag: entry.key,
                  count: entry.value,
                  max: maxCount,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TagInsightScreen(tag: entry.key),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
