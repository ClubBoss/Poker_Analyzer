import 'package:flutter/material.dart';

import '../../models/training_spot.dart';
import '../../theme/app_colors.dart';

class TrainingSpotList extends StatefulWidget {
  final List<TrainingSpot> spots;
  final ValueChanged<int>? onRemove;

  const TrainingSpotList({super.key, required this.spots, this.onRemove});

  @override
  State<TrainingSpotList> createState() => _TrainingSpotListState();
}

class _TrainingSpotListState extends State<TrainingSpotList> {
  final TextEditingController _searchController = TextEditingController();
  static const List<String> _availableTags = [
    '3бет пот',
    'Фиш',
    'Рег',
    'ICM',
    'vs агро',
  ];

  final Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final filtered = widget.spots.where((spot) {
      final id = spot.tournamentId?.toLowerCase() ?? '';
      final game = spot.gameType?.toLowerCase() ?? '';
      final buyIn = spot.buyIn?.toString() ?? '';
      final matchesQuery = query.isEmpty ||
          id.contains(query) ||
          game.contains(query) ||
          buyIn.contains(query);
      final matchesTags =
          _selectedTags.isEmpty || _selectedTags.every(spot.tags.contains);
      return matchesQuery && matchesTags;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchField(),
        const SizedBox(height: 8),
        _buildTagFilters(),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          const Text(
            'Нет импортированных спотов',
            style: TextStyle(color: Colors.white54),
          )
        else
          SizedBox(
            height: 150,
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final spot = filtered[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (spot.tournamentId != null && spot.tournamentId!.isNotEmpty)
                              Text('ID: ${spot.tournamentId}',
                                  style: const TextStyle(color: Colors.white)),
                            if (spot.buyIn != null)
                              Text('Buy-In: ${spot.buyIn}',
                                  style: const TextStyle(color: Colors.white)),
                            if (spot.gameType != null && spot.gameType!.isNotEmpty)
                              Text('Game: ${spot.gameType}',
                                  style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              children: [
                                for (final tag in _availableTags)
                                  FilterChip(
                                    label: Text(tag),
                                    selected: spot.tags.contains(tag),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          if (!spot.tags.contains(tag)) {
                                            spot.tags.add(tag);
                                          }
                                        } else {
                                          spot.tags.remove(tag);
                                        }
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (widget.onRemove != null)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => widget.onRemove!(widget.spots.indexOf(spot)),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Поиск...',
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildTagFilters() {
    return Wrap(
      spacing: 4,
      children: [
        for (final tag in _availableTags)
          FilterChip(
            label: Text(tag),
            selected: _selectedTags.contains(tag),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedTags.add(tag);
                } else {
                  _selectedTags.remove(tag);
                }
              });
            },
          ),
      ],
    );
  }
}
