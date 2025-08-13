import 'package:flutter/material.dart';

import '../models/decay_retention_summary.dart';
import '../services/decay_retention_summary_service.dart';

/// Banner displaying a compact summary of current memory decay state.
class DecayMemoryHealthBanner extends StatefulWidget {
  final DecayRetentionSummaryService? service;

  const DecayMemoryHealthBanner({super.key, this.service});

  @override
  State<DecayMemoryHealthBanner> createState() =>
      _DecayMemoryHealthBannerState();
}

class _DecayMemoryHealthBannerState extends State<DecayMemoryHealthBanner> {
  DecayRetentionSummary? _summary;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = widget.service ?? DecayRetentionSummaryService();
    final summary = await service.getSummary();
    if (mounted) {
      setState(() => _summary = summary);
    }
  }

  Color _colorFor(double decay) {
    if (decay < 0.3) return Colors.green.shade700;
    if (decay < 0.6) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || _summary == null) return const SizedBox.shrink();
    final sum = _summary!;
    final memoryPct = (sum.averageDecay * 100).round();
    final tagsText = sum.topForgotten.join(', ');
    final color = _colorFor(sum.averageDecay);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🧠 ',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Expanded(
                child: Text(
                  'Память: $memoryPct% забывания',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _visible = false),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${sum.decayedTags} из ${sum.totalTags} тем нуждаются в повторении',
            style: const TextStyle(color: Colors.white),
          ),
          if (tagsText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Темы: $tagsText',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}
