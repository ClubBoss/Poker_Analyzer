import 'package:flutter/material.dart';

import '../models/error_entry.dart';

const _filterOptions = [
  'All',
  'Aggressive',
  'Passive',
  'Sizing',
  'Other'
];
class SessionReviewScreen extends StatefulWidget {
  final List<ErrorEntry> errors;

  const SessionReviewScreen({super.key, required this.errors});

  @override
  State<SessionReviewScreen> createState() => _SessionReviewScreenState();
}

class _SessionReviewScreenState extends State<SessionReviewScreen> {
  String _selectedType = 'All';

  Widget _buildSummary() {
    final counts = <String, int>{};
    for (final e in widget.errors) {
      counts[e.errorType] = (counts[e.errorType] ?? 0) + 1;
    }
    final parts = <String>[];
    for (final type in _filterOptions.skip(1)) {
      final count = counts[type] ?? 0;
      var label = type;
      if (_selectedType == type) label = '$label (active)';
      parts.add('$label: $count');
    }
    final text = 'Total: ${widget.errors.length} — ${parts.join(', ')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedType == 'All'
        ? widget.errors
        : widget.errors
            .where((e) => e.errorType == _selectedType)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ошибки сессии'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              setState(() {
                _selectedType = v;
              });
            },
            icon: const Icon(Icons.filter_list),
            itemBuilder: (_) => [
              for (final option in _filterOptions)
                PopupMenuItem(value: option, child: Text(option))
            ],
          )
        ],
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: filtered.isEmpty
          ? const Center(
              child: Text(
                'Ошибок нет',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildSummary(),
                ),
                Expanded(child: _buildGroupedList(filtered)),
              ],
            ),
    );
  }

  Widget _buildGroupedList(List<ErrorEntry> entries) {
    const streets = ['Preflop', 'Flop', 'Turn', 'River'];
    final Map<String, List<ErrorEntry>> grouped = {
      for (final s in streets) s: []
    };
    for (final e in entries) {
      if (grouped.containsKey(e.street)) {
        grouped[e.street]!.add(e);
      } else {
        grouped[e.street] = [e];
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final street in streets)
          ExpansionTile(
            title: Text(
              street,
              style: const TextStyle(color: Colors.white),
            ),
            collapsedIconColor: Colors.white,
            iconColor: Colors.white,
            textColor: Colors.white,
            children: grouped[street]!.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'No mistakes on this street',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  ]
                : [
                    for (final e in grouped[street]!)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2B2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.spotTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              e.situationDescription,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ваше действие: ${e.userAction}',
                              style: const TextStyle(color: Colors.red),
                            ),
                            Text(
                              'Правильное действие: ${e.correctAction}',
                              style: const TextStyle(color: Colors.green),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              e.aiExplanation,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                  ],
          ),
      ],
    );
  }
}
