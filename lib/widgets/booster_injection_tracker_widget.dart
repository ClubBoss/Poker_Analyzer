import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../services/theory_reinforcement_log_service.dart';
import '../models/reinforcement_log.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../services/theory_pack_library_service.dart';
import '../services/mini_lesson_library_service.dart';

/// Widget displaying recent booster injections with timing and source info.
class BoosterInjectionTrackerWidget extends StatefulWidget {
  final int count;
  const BoosterInjectionTrackerWidget({super.key, this.count = 5});

  @override
  State<BoosterInjectionTrackerWidget> createState() =>
      _BoosterInjectionTrackerWidgetState();
}

class _BoosterInjectionTrackerWidgetState
    extends State<BoosterInjectionTrackerWidget> {
  bool _loading = true;
  List<ReinforcementLog> _logs = [];
  final Map<String, String> _titles = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final list = await TheoryReinforcementLogService.instance.getRecent();
    _logs = list.take(widget.count).toList();
    for (final l in _logs) {
      _titles[l.id] = await _fetchTitle(l.id);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<String> _fetchTitle(String id) async {
    await TrainingPackLibraryV2.instance.loadFromFolder();
    final pack = TrainingPackLibraryV2.instance.getById(id);
    if (pack != null) return pack.name;

    await TheoryPackLibraryService.instance.loadAll();
    final theory = TheoryPackLibraryService.instance.getById(id);
    if (theory != null) return theory.title;

    await MiniLessonLibraryService.instance.loadAll();
    final mini = MiniLessonLibraryService.instance.getById(id);
    if (mini != null) return mini.resolvedTitle;

    return id;
  }

  Icon _icon(String source) {
    switch (source) {
      case 'auto':
        return const Icon(Icons.flash_on, color: Colors.amberAccent, size: 16);
      case 'smart':
        return const Icon(
          Icons.lightbulb,
          color: Colors.lightBlueAccent,
          size: 16,
        );
      default:
        return const Icon(Icons.edit, color: Colors.greenAccent, size: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _logs.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: Colors.white70),
              SizedBox(width: 8),
              Text(
                'Booster History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _logs.length; i++) ...[
            Row(
              children: [
                _icon(_logs[i].source),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _titles[_logs[i].id] ?? _logs[i].id,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Text(
                  _logs[i].timestamp != null
                      ? timeago.format(_logs[i].timestamp!, allowFromNow: true)
                      : 'unknown',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            if (i != _logs.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}
