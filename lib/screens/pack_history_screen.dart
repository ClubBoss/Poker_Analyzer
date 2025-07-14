import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/training_session_service.dart';
import '../services/training_pack_template_service.dart';
import '../models/v2/training_pack_template.dart';
import 'training_session_screen.dart';
import '../widgets/training_pack_card.dart';
import '../helpers/date_utils.dart';

class PackHistoryScreen extends StatefulWidget {
  const PackHistoryScreen({super.key});

  @override
  State<PackHistoryScreen> createState() => _PackHistoryScreenState();
}

class _PackHistoryScreenState extends State<PackHistoryScreen> {
  final Map<DateTime, List<TrainingPackTemplate>> _groups = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final map = await _fetchTemplates();
    if (!mounted) return;
    setState(() {
      _groups
        ..clear()
        ..addAll(map);
      _loading = false;
    });
  }

  Future<Map<DateTime, List<TrainingPackTemplate>>> _fetchTemplates() async {
    final templates = TrainingPackTemplateService.getAllTemplates(context);
    final prefs = await SharedPreferences.getInstance();
    final list = <MapEntry<TrainingPackTemplate, DateTime>>[];
    for (final t in templates) {
      if (prefs.getBool('completed_tpl_${t.id}') ?? false) {
        final ts = DateTime.tryParse(
                prefs.getString('completed_at_tpl_${t.id}') ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        t.lastTrainedAt = ts;
        list.add(MapEntry(t, ts));
      }
    }
    list.sort((a, b) => b.value.compareTo(a.value));
    final map = <DateTime, List<TrainingPackTemplate>>{};
    for (final e in list) {
      final day = DateTime(e.value.year, e.value.month, e.value.day);
      map.putIfAbsent(day, () => []).add(e.key);
    }
    return map;
  }

  Future<void> _refreshAfterReset() async {
    final map = await _fetchTemplates();
    if (!mounted) return;
    setState(() {
      _groups
        ..clear()
        ..addAll(map);
    });
  }

  Future<void> _start(TrainingPackTemplate tpl) async {
    await context.read<TrainingSessionService>().startSession(tpl);
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('История паков')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? const Center(
                  child: Text('История пуста',
                      style: TextStyle(color: Colors.white70)),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: Builder(builder: (context) {
                    final dates = _groups.keys.toList()
                      ..sort((a, b) => b.compareTo(a));
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (int i = 0; i < dates.length; i++) ...[
                          Padding(
                            padding:
                                EdgeInsets.fromLTRB(0, i == 0 ? 0 : 16, 0, 8),
                            child: Text(
                              formatLongDate(dates[i]),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          for (final t in _groups[dates[i]]!)
                            TrainingPackCard(
                              template: t,
                              onTap: () => _start(t),
                              onRefresh: _refreshAfterReset,
                            ),
                        ]
                      ],
                    );
                  }),
                ),
    );
  }
}
