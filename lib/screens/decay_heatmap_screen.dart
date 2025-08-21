import 'package:flutter/material.dart';

import '../models/tag_decay_entry.dart';
import '../services/booster_path_history_service.dart';
import '../services/decay_tag_retention_tracker_service.dart';
import '../utils/responsive.dart';

class DecayHeatmapScreen extends StatefulWidget {
  static const route = '/decay_heatmap';
  const DecayHeatmapScreen({super.key});

  @override
  State<DecayHeatmapScreen> createState() => _DecayHeatmapScreenState();
}

enum _Sort { decay, alphabet, boosters }

class _DecayHeatmapScreenState extends State<DecayHeatmapScreen> {
  bool _loading = true;
  List<TagDecayEntry> _entries = [];
  _Sort _sort = _Sort.decay;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final scores = await const DecayTagRetentionTrackerService()
        .getAllDecayScores();
    final boosterStats = await BoosterPathHistoryService.instance.getTagStats();
    final list = <TagDecayEntry>[];
    scores.forEach((tag, score) {
      final boosters = boosterStats[tag]?.completedCount ?? 0;
      list.add(TagDecayEntry(tag: tag, decay: score, boosters: boosters));
    });
    _sortEntries(list);
    if (!mounted) return;
    setState(() {
      _entries = list;
      _loading = false;
    });
  }

  void _sortEntries(List<TagDecayEntry> list) {
    switch (_sort) {
      case _Sort.alphabet:
        list.sort((a, b) => a.tag.compareTo(b.tag));
        break;
      case _Sort.boosters:
        list.sort((a, b) => b.boosters.compareTo(a.boosters));
        break;
      case _Sort.decay:
      default:
        list.sort((a, b) => b.decay.compareTo(a.decay));
    }
  }

  Color _colorFor(double u) {
    if (u <= 0.5) {
      return Color.lerp(Colors.green, Colors.yellow, u * 2) ?? Colors.green;
    }
    return Color.lerp(Colors.yellow, Colors.red, (u - 0.5) * 2) ?? Colors.red;
  }

  Color _textColor(Color bg) {
    return ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  Widget _buildTile(TagDecayEntry e) {
    final color = _colorFor(e.decay);
    final textColor = _textColor(color);
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Selected ${e.tag}')));
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              e.tag,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${(e.decay * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: textColor),
            ),
            if (e.boosters > 0)
              Text(
                'x${e.boosters}',
                style: TextStyle(color: textColor, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = isLandscape(context) ? 4 : 3;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decay Heatmap'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          PopupMenuButton<_Sort>(
            icon: const Icon(Icons.sort),
            onSelected: (v) {
              setState(() {
                _sort = v;
                _sortEntries(_entries);
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _Sort.decay, child: Text('By decay')),
              PopupMenuItem(value: _Sort.alphabet, child: Text('Alphabetical')),
              PopupMenuItem(value: _Sort.boosters, child: Text('By boosters')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
          ? const Center(child: Text('No tags'))
          : GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: count,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
              children: _entries.map(_buildTile).toList(),
            ),
    );
  }
}
