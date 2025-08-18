import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/theory_recap_review_entry.dart';
import '../services/theory_booster_recap_delay_manager.dart';
import '../services/theory_recap_review_tracker.dart';
import '../services/theory_recap_suppression_engine.dart';
import '../theme/app_colors.dart';

class TheoryRecapHistoryViewerScreen extends StatefulWidget {
  const TheoryRecapHistoryViewerScreen({super.key});

  @override
  State<TheoryRecapHistoryViewerScreen> createState() =>
      _TheoryRecapHistoryViewerScreenState();
}

class _EntryInfo {
  final TheoryRecapReviewEntry entry;
  final bool suppressed;
  final String? reason;
  final bool cooldown;

  _EntryInfo(this.entry, this.suppressed, this.reason, this.cooldown);
}

class _TheoryRecapHistoryViewerScreenState
    extends State<TheoryRecapHistoryViewerScreen> {
  final List<_EntryInfo> _items = [];
  final Set<String> _triggers = {};
  bool _loading = true;
  String? _filter;
  bool _suppressedOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await TheoryRecapReviewTracker.instance.getHistory();
    final List<_EntryInfo> items = [];
    for (final e in history) {
      final reason = await TheoryRecapSuppressionEngine.instance
          .getSuppressionReason(lessonId: e.lessonId, trigger: e.trigger);
      final cooldown = e.lessonId.isNotEmpty
          ? await TheoryBoosterRecapDelayManager.isUnderCooldown(
              'lesson:${e.lessonId}',
              const Duration(hours: 24),
            )
          : false;
      items.add(_EntryInfo(e, reason != null, reason, cooldown));
      _triggers.add(e.trigger);
    }
    setState(() {
      _items
        ..clear()
        ..addAll(items);
      _loading = false;
    });
  }

  List<_EntryInfo> get _filtered {
    Iterable<_EntryInfo> list = _items;
    if (_filter != null) {
      list = list.where((e) => e.entry.trigger == _filter);
    }
    if (_suppressedOnly) {
      list = list.where((e) => e.suppressed);
    }
    return list.toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Theory Recap History')),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      DropdownButton<String?>(
                        hint: const Text('Trigger'),
                        value: _filter,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All'),
                          ),
                          ..._triggers.map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          ),
                        ],
                        onChanged: (v) => setState(() => _filter = v),
                      ),
                      const SizedBox(width: 16),
                      Checkbox(
                        value: _suppressedOnly,
                        onChanged: (v) =>
                            setState(() => _suppressedOnly = v ?? false),
                      ),
                      const Text('Suppressed only'),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = _filtered[i];
                      final ts = item.entry.timestamp.toIso8601String();
                      return Card(
                        color: AppColors.cardBackground,
                        child: ListTile(
                          title: Text(
                            item.entry.lessonId.isEmpty
                                ? '(no lesson)'
                                : item.entry.lessonId,
                          ),
                          subtitle: Text('${item.entry.trigger} • $ts'),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.suppressed
                                    ? 'Suppressed${item.reason != null ? ' (${item.reason})' : ''}'
                                    : 'Shown',
                              ),
                              Text(item.cooldown ? 'Cooldown' : ''),
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
