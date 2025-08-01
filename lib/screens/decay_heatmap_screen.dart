import 'package:flutter/material.dart';

import '../services/decay_heatmap_tile_generator.dart';
import '../utils/responsive.dart';

class DecayHeatmapScreen extends StatefulWidget {
  static const route = '/decay_heatmap';
  const DecayHeatmapScreen({super.key});

  @override
  State<DecayHeatmapScreen> createState() => _DecayHeatmapScreenState();
}

class _DecayHeatmapScreenState extends State<DecayHeatmapScreen> {
  bool _loading = true;
  List<DecayHeatmapTile> _tiles = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final generator = const DecayHeatmapTileGenerator();
    final tiles = await generator.generate();
    tiles.sort((a, b) => b.urgency.compareTo(a.urgency));
    if (!mounted) return;
    setState(() {
      _tiles = tiles;
      _loading = false;
    });
  }

  Color _textColor(Color bg) {
    return ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  Widget _buildTile(DecayHeatmapTile tile) {
    final textColor = _textColor(tile.color);
    return Container(
      decoration: BoxDecoration(
        color: tile.color,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            tile.tag,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${(tile.urgency * 100).toStringAsFixed(0)}%',
            style: TextStyle(color: textColor),
          ),
        ],
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
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tiles.isEmpty
              ? const Center(child: Text('No tags'))
              : GridView.count(
                  padding: const EdgeInsets.all(16),
                  crossAxisCount: count,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                  children: _tiles.map(_buildTile).toList(),
                ),
    );
  }
}
