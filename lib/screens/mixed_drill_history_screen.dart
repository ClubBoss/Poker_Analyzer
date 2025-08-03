import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/date_utils.dart';
import '../models/mixed_drill_stat.dart';
import '../services/mixed_drill_history_service.dart';
import '../theme/app_colors.dart';

class DrillHistoryScreen extends StatefulWidget {
  const DrillHistoryScreen({super.key});

  @override
  State<DrillHistoryScreen> createState() => _DrillHistoryScreenState();
}

class _DrillHistoryScreenState extends State<DrillHistoryScreen> {
  static const _prefsKey = 'drill_history_filter';
  String _street = 'any';
  String? _tag;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final m = jsonDecode(raw);
        _street = m['street'] as String? ?? 'any';
        _tag = m['tag'] as String?;
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({'street': _street, 'tag': _tag}),
    );
  }

  List<MixedDrillStat> _filter(List<MixedDrillStat> list) {
    return [
      for (final s in list)
        if ((_street == 'any' || s.street == _street) &&
            (_tag == null || s.tags.contains(_tag)))
          s
    ];
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<MixedDrillHistoryService>().stats;
    final tags = <String>{for (final s in stats) ...s.tags};
    final filtered = _filter(stats);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drill History'),
      ),
      body: stats.isEmpty
          ? const Center(
              child: Text('Empty', style: TextStyle(color: Colors.white70)),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButton<String>(
                    value: _street,
                    underline: const SizedBox.shrink(),
                    onChanged: (v) {
                      setState(() => _street = v ?? 'any');
                      _save();
                    },
                    items: const [
                      DropdownMenuItem(value: 'any', child: Text('All')),
                      DropdownMenuItem(value: 'preflop', child: Text('Preflop')),
                      DropdownMenuItem(value: 'flop', child: Text('Flop')),
                      DropdownMenuItem(value: 'turn', child: Text('Turn')),
                      DropdownMenuItem(value: 'river', child: Text('River')),
                    ],
                  ),
                ),
                if (tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _tag == null,
                          onSelected: (_) {
                            setState(() => _tag = null);
                            _save();
                          },
                        ),
                        for (final t in tags)
                          ChoiceChip(
                            label: Text(t),
                            selected: _tag == t,
                            onSelected: (_) {
                              setState(() => _tag = _tag == t ? null : t);
                              _save();
                            },
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text('No results',
                              style: TextStyle(color: Colors.white70)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final s = filtered[index];
                            final pct = s.accuracy.toStringAsFixed(1);
                            final sub = [
                              s.street,
                              if (s.tags.isNotEmpty) s.tags.join(', ')
                            ].join(' • ');
                            return Card(
                              color: AppColors.cardBackground,
                              child: ListTile(
                                title: Text(formatDate(s.date),
                                    style:
                                        const TextStyle(color: Colors.white)),
                                subtitle: Text(sub,
                                    style: const TextStyle(color: Colors.white70)),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('$pct%',
                                        style: const TextStyle(color: Colors.white)),
                                    Text('${s.total}',
                                        style:
                                            const TextStyle(color: Colors.white70)),
                                  ],
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
