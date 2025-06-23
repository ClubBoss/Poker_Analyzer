import 'package:flutter/material.dart';

import '../models/saved_hand.dart';
import '../theme/app_colors.dart';

/// Wrapper for a completed spot with correctness flag.
class CompletedSpot {
  final SavedHand hand;
  final bool correct;

  CompletedSpot({required this.hand, required this.correct});
}

enum _SortOrder { newest, oldest, correctFirst, mistakesFirst }

class TrainingPackReviewScreen extends StatefulWidget {
  final List<CompletedSpot> spots;
  const TrainingPackReviewScreen({super.key, required this.spots});

  @override
  State<TrainingPackReviewScreen> createState() =>
      _TrainingPackReviewScreenState();
}

class _TrainingPackReviewScreenState extends State<TrainingPackReviewScreen> {
  bool _filtersExpanded = false;
  int _ratingFilter = 0; // 0 = any
  final Set<String> _tagFilter = {};
  _SortOrder _sortOrder = _SortOrder.newest;

  Set<String> get _availableTags => {
        for (final s in widget.spots) ...s.hand.tags,
      };

  List<CompletedSpot> get _filteredSpots {
    List<CompletedSpot> list = [
      for (final s in widget.spots)
        if ((_ratingFilter == 0 || s.hand.rating >= _ratingFilter) &&
            (_tagFilter.isEmpty || _tagFilter.every((t) => s.hand.tags.contains(t))))
          s
    ];

    switch (_sortOrder) {
      case _SortOrder.newest:
        list.sort((a, b) => b.hand.date.compareTo(a.hand.date));
        break;
      case _SortOrder.oldest:
        list.sort((a, b) => a.hand.date.compareTo(b.hand.date));
        break;
      case _SortOrder.correctFirst:
        list.sort((a, b) => a.correct == b.correct
            ? 0
            : (a.correct ? -1 : 1));
        break;
      case _SortOrder.mistakesFirst:
        list.sort((a, b) => a.correct == b.correct
            ? 0
            : (a.correct ? 1 : -1));
        break;
    }
    return list;
  }

  void _clearFilters() {
    setState(() {
      _ratingFilter = 0;
      _tagFilter.clear();
      _sortOrder = _SortOrder.newest;
    });
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 1; i <= 5; i++)
                IconButton(
                  icon: Icon(
                    i <= _ratingFilter ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() {
                    _ratingFilter = _ratingFilter == i ? 0 : i;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: [
              for (final tag in _availableTags)
                FilterChip(
                  label: Text(tag),
                  selected: _tagFilter.contains(tag),
                  onSelected: (v) => setState(() {
                    if (v) {
                      _tagFilter.add(tag);
                    } else {
                      _tagFilter.remove(tag);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButton<_SortOrder>(
            value: _sortOrder,
            dropdownColor: AppColors.cardBackground,
            onChanged: (v) => setState(() => _sortOrder = v ?? _sortOrder),
            items: const [
              DropdownMenuItem(
                value: _SortOrder.newest,
                child: Text('Newest'),
              ),
              DropdownMenuItem(
                value: _SortOrder.oldest,
                child: Text('Oldest'),
              ),
              DropdownMenuItem(
                value: _SortOrder.correctFirst,
                child: Text('Correct first'),
              ),
              DropdownMenuItem(
                value: _SortOrder.mistakesFirst,
                child: Text('Mistakes first'),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotTile(CompletedSpot spot) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(spot.hand.name,
            style: const TextStyle(color: Colors.white)),
        subtitle: Wrap(
          spacing: 4,
          children: [for (final t in spot.hand.tags) Chip(label: Text(t))],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              spot.correct ? Icons.check : Icons.close,
              color: spot.correct ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            for (int i = 0; i < 5; i++)
              Icon(
                i < spot.hand.rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filteredSpots;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pack Review'),
        centerTitle: true,
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ListTile(
            title: const Text('Filters'),
            trailing: IconButton(
              icon: Icon(
                _filtersExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              onPressed: () => setState(() {
                _filtersExpanded = !_filtersExpanded;
              }),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildFilters(),
            crossFadeState: _filtersExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: visible.isEmpty
                ? const Center(
                    child: Text('No spots',
                        style: TextStyle(color: Colors.white54)),
                  )
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) =>
                        _buildSpotTile(visible[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
