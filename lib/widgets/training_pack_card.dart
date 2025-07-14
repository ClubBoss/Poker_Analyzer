import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/v2/training_pack_template.dart';
import '../services/pinned_pack_service.dart';
import '../theme/app_colors.dart';
import '../helpers/mistake_category_translations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/date_utils.dart';

class TrainingPackCard extends StatefulWidget {
  final TrainingPackTemplate template;
  final VoidCallback onTap;
  final int? progress;
  final Future<void> Function()? onRefresh;
  final bool dimmed;
  const TrainingPackCard({
    super.key,
    required this.template,
    required this.onTap,
    this.progress,
    this.onRefresh,
    this.dimmed = false,
  });

  @override
  State<TrainingPackCard> createState() => _TrainingPackCardState();
}

class _TrainingPackCardState extends State<TrainingPackCard> {
  late bool _pinned;
  String? _completedAt;
  double? _accuracy;
  bool _passed = false;

  Future<void> _resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('progress_tpl_${widget.template.id}');
    await prefs.remove('completed_tpl_${widget.template.id}');
    await prefs.remove('completed_at_tpl_${widget.template.id}');
    await prefs.remove('last_accuracy_tpl_${widget.template.id}');
    await prefs.remove('last_accuracy_tpl_${widget.template.id}_0');
    await prefs.remove('last_accuracy_tpl_${widget.template.id}_1');
    await prefs.remove('last_accuracy_tpl_${widget.template.id}_2');
    if (mounted) {
      setState(() {
        _passed = false;
        _accuracy = null;
        _completedAt = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Прогресс сброшен')),
      );
    }
    await widget.onRefresh?.call();
  }

  Future<void> _handleTap() async {
    if (!_passed) {
      widget.onTap();
      return;
    }
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Пак пройден'),
        content: const Text('Повторить или сбросить прогресс?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'reset'),
            child: const Text('Сбросить прогресс'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'repeat'),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
    if (result == 'repeat') {
      widget.onTap();
    } else if (result == 'reset') {
      await _resetProgress();
    }
  }

  @override
  void initState() {
    super.initState();
    _pinned = widget.template.isPinned;
    if (widget.dimmed) _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = DateTime.tryParse(
        prefs.getString('completed_at_tpl_${widget.template.id}') ?? '');
    final acc = prefs.getDouble('last_accuracy_tpl_${widget.template.id}');
    final a0 = prefs.getDouble('last_accuracy_tpl_${widget.template.id}_0');
    final a1 = prefs.getDouble('last_accuracy_tpl_${widget.template.id}_1');
    final a2 = prefs.getDouble('last_accuracy_tpl_${widget.template.id}_2');
    if (mounted) {
      setState(() {
        if (ts != null) _completedAt = formatLongDate(ts);
        if (acc != null) _accuracy = acc;
        _passed = a0 != null && a1 != null && a2 != null &&
            a0 >= 80 && a1 >= 80 && a2 >= 80;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final catSet = <String>{};
    for (final s in widget.template.spots) {
      for (final t in s.tags.where((t) => t.startsWith('cat:'))) {
        catSet.add(t.substring(4));
      }
    }
    final cats = [for (final c in catSet) translateMistakeCategory(c)];
    return GestureDetector(
      onLongPress: () async {
        await context.read<PinnedPackService>().toggle(widget.template.id);
        if (mounted)
          setState(() {
            _pinned = !_pinned;
            widget.template.isPinned = _pinned;
          });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.dimmed
              ? const Color(0xFF3A3B3E)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Row(
              children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_pinned)
                        const Text(
                          '📌 ',
                          style: TextStyle(color: Colors.white),
                        ),
                      Expanded(
                        child: Text(
                          widget.template.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.template.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.template.description,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${widget.template.spots.length} spots',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  if (widget.progress != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${widget.progress} / ${widget.template.spots.length}',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                  if (cats.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final c in cats)
                            Chip(
                              label: Text(c),
                              backgroundColor: const Color(0xFF3A3B3E),
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _handleTap, child: const Text('Train')),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'reset') _resetProgress();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'reset',
                  child: Text('Сбросить прогресс'),
                ),
              ],
            ),
          ],
            ),
            if (_passed)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '✅ Completed',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            if (widget.dimmed && (_completedAt != null || _accuracy != null))
              Positioned(
                bottom: 4,
                right: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_completedAt != null)
                      Text(
                        _completedAt!,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    if (_accuracy != null)
                      Text(
                        'Accuracy: ${_accuracy!.toStringAsFixed(0)}%',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
