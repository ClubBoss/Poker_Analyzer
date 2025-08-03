import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_spot.dart';
import 'training_spot_tile.dart';
import 'training_spot_filter_panel.dart';
import 'training_spot_overlay.dart';

/// Core implementation of the training spot list. It is intentionally much
/// lighter than the original monolithic widget and focuses on state
/// management, sorting and persistence. UI details such as tiles, filter
/// panels and drag & drop handling are delegated to specialised widgets.
class TrainingSpotList extends StatefulWidget {
  final List<TrainingSpot> spots;
  final ValueChanged<int>? onRemove;
  final ValueChanged<int>? onEdit;
  final VoidCallback? onChanged;
  final ReorderCallback? onReorder;
  final bool icmOnly;

  const TrainingSpotList({
    super.key,
    required this.spots,
    this.onRemove,
    this.onEdit,
    this.onChanged,
    this.onReorder,
    this.icmOnly = false,
  });

  @override
  TrainingSpotListState createState() => TrainingSpotListState();
}

class TrainingSpotListState extends State<TrainingSpotList> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  String _tagFilter = 'All';
  String _positionFilter = 'All';
  bool _ascending = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _search = prefs.getString('spot_search') ?? '';
      _ascending = prefs.getBool('spot_sort_asc') ?? true;
      _searchController.text = _search;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('spot_search', _search);
    await prefs.setBool('spot_sort_asc', _ascending);
  }

  List<TrainingSpot> get _visibleSpots {
    final lower = _search.toLowerCase();
    final filtered = widget.spots.where((s) {
      if (widget.icmOnly && !(s.tags.contains('ICM'))) return false;
      if (_tagFilter != 'All' && !s.tags.contains(_tagFilter)) return false;
      final pos = s.positions.isNotEmpty ? s.positions[s.heroIndex] : '';
      if (_positionFilter != 'All' && pos != _positionFilter) return false;
      final text = pos.toLowerCase();
      return lower.isEmpty || text.contains(lower);
    }).toList();
    filtered.sort((a, b) => _ascending
        ? a.createdAt.compareTo(b.createdAt)
        : b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  void _toggleSort() {
    setState(() => _ascending = !_ascending);
    _savePrefs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spots = _visibleSpots;
    final tags = <String>{for (final s in widget.spots) ...s.tags};
    final positions = <String>{
      for (final s in widget.spots)
        if (s.positions.isNotEmpty) s.positions[s.heroIndex]
    };
    return TrainingSpotOverlay(
      child: Column(
        children: [
          TrainingSpotFilterPanel(
            searchController: _searchController,
            onSearchChanged: (v) {
              setState(() => _search = v);
              _savePrefs();
            },
            tags: tags,
            positions: positions,
            positionValue: _positionFilter,
            tagValue: _tagFilter,
            onPositionChanged: (v) => setState(() {
              _positionFilter = v ?? 'All';
            }),
            onTagChanged: (v) => setState(() {
              _tagFilter = v ?? 'All';
            }),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(
                  _ascending ? Icons.arrow_upward : Icons.arrow_downward),
              onPressed: _toggleSort,
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: spots.length,
              onReorder: widget.onReorder ?? (a, b) {},
              buildDefaultDragHandles: false,
              itemBuilder: (context, index) {
                final spot = spots[index];
                return Dismissible(
                  key: ValueKey(spot.createdAt),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => widget.onRemove?.call(index),
                  child: ReorderableDragStartListener(
                    index: index,
                    child: TrainingSpotTile(
                      spot: spot,
                      index: index,
                      onEdit: widget.onEdit,
                      onRemove: widget.onRemove,
                    ),
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
