import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/training_spot.dart';
import '../../utils/shared_prefs_keys.dart';
import 'training_spot_tile.dart';
import 'training_spot_filter_panel.dart';
import 'training_spot_overlay.dart';

class TrainingSpotList extends StatefulWidget {
  final List<TrainingSpot> spots;
  final ValueChanged<int>? onRemove;
  final ValueChanged<int>? onEdit;
  final VoidCallback? onChanged;
  final ReorderCallback? onReorder;

  const TrainingSpotList({
    super.key,
    required this.spots,
    this.onRemove,
    this.onEdit,
    this.onChanged,
    this.onReorder,
  });

  @override
  State<TrainingSpotList> createState() => _TrainingSpotListState();
}

class TrainingSpotListState extends State<TrainingSpotList> {
  late List<TrainingSpot> _filtered;
  bool _ascending = true;

  @override
  void initState() {
    super.initState();
    _filtered = [...widget.spots];
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _ascending =
        prefs.getBool(SharedPrefsKey.trainingSpotListSort.asString()) ?? true;
    _sort();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs
        .setBool(SharedPrefsKey.trainingSpotListSort.asString(), _ascending);
  }

  void _sort() {
    _filtered.sort((a, b) => _ascending
        ? a.createdAt.compareTo(b.createdAt)
        : b.createdAt.compareTo(a.createdAt));
    setState(() {});
    _savePrefs();
  }

  void _onSearch(String text) {
    final query = text.toLowerCase();
    _filtered = widget.spots
        .where((s) => s.tags.any((t) => t.toLowerCase().contains(query)))
        .toList();
    _sort();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TrainingSpotFilterPanel(onSearchChanged: _onSearch),
        Expanded(
          child: TrainingSpotOverlay(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final spot = _filtered[index];
                return TrainingSpotTile(
                  spot: spot,
                  onEdit: widget.onEdit != null
                      ? () => widget.onEdit!(index)
                      : null,
                  onRemove: widget.onRemove != null
                      ? () => widget.onRemove!(index)
                      : null,
                  onTap: widget.onChanged,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
