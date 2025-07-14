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

  Future<void> _resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('progress_tpl_${widget.template.id}');
    await prefs.remove('completed_tpl_${widget.template.id}');
    await prefs.remove('completed_at_tpl_${widget.template.id}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Прогресс сброшен')),
      );
    }
    await widget.onRefresh?.call();
  }

  @override
  void initState() {
    super.initState();
    _pinned = widget.template.isPinned;
    if (widget.dimmed) _loadCompletedAt();
  }

  Future<void> _loadCompletedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = DateTime.tryParse(
        prefs.getString('completed_at_tpl_${widget.template.id}') ?? '');
    if (ts != null && mounted) {
      setState(() {
        _completedAt = formatLongDate(ts);
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
            ElevatedButton(onPressed: widget.onTap, child: const Text('Train')),
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
            if (widget.dimmed && _completedAt != null)
              Positioned(
                bottom: 4,
                right: 4,
                child: Text(
                  _completedAt!,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
