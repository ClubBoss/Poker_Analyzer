import 'package:flutter/material.dart';

import '../models/error_entry.dart';
import 'retry_training_screen.dart';
import '../widgets/sync_status_widget.dart';

const _filterOptions = ['All', 'Aggressive', 'Passive', 'Sizing', 'Other'];

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
    final children = <Widget>[
      Text(
        'Total: ${widget.errors.length}',
        style: const TextStyle(color: Colors.white),
      ),
    ];
    for (final type in _filterOptions.skip(1)) {
      final count = counts[type] ?? 0;
      final isActive = _selectedType == type;
      children.add(
        TextButton(
          onPressed: () {
            setState(() {
              _selectedType = type;
            });
          },
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: Text(
            '$type: $count',
            style: TextStyle(color: isActive ? Colors.amber : Colors.white),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(spacing: 8, runSpacing: 4, children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedType == 'All'
        ? widget.errors
        : widget.errors.where((e) => e.errorType == _selectedType).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ошибки сессии'),
        centerTitle: true,
        actions: [
          SyncStatusIcon.of(context),
          PopupMenuButton<String>(
            onSelected: (v) {
              setState(() {
                _selectedType = v;
              });
            },
            icon: const Icon(Icons.filter_list),
            itemBuilder: (_) => [
              for (final option in _filterOptions)
                PopupMenuItem(value: option, child: Text(option)),
            ],
          ),
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
                if (filtered.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RetryTrainingScreen(errors: filtered),
                          ),
                        );
                      },
                      child: const Text('Retry Mistakes'),
                    ),
                  ),
                Expanded(child: _buildGroupedList(filtered)),
              ],
            ),
    );
  }

  Widget _buildGroupedList(List<ErrorEntry> entries) {
    const streets = ['Preflop', 'Flop', 'Turn', 'River'];
    final Map<String, List<ErrorEntry>> grouped = {
      for (final s in streets) s: [],
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
            title: Text(street, style: const TextStyle(color: Colors.white)),
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
                    ),
                  ]
                : [
                    for (final e in grouped[street]!)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2B2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                24,
                                12,
                                12,
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
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
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
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  e.errorType,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
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
