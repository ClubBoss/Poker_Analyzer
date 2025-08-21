import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import '../services/pinned_pack_service.dart';
import '../theme/app_colors.dart';
import '../helpers/mistake_category_translations.dart';
import 'training_pack_preview_panel.dart';
import 'coverage_meter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/date_utils.dart';
import '../services/training_pack_stats_service.dart';
import 'package:intl/intl.dart';

class TrainingPackCard extends StatefulWidget {
  final TrainingPackTemplate template;
  final VoidCallback onTap;
  final int? progress;
  final Future<void> Function()? onRefresh;
  final bool dimmed;
  final bool locked;
  final String? lockReason;
  const TrainingPackCard({
    super.key,
    required this.template,
    required this.onTap,
    this.progress,
    this.onRefresh,
    this.dimmed = false,
    this.locked = false,
    this.lockReason,
  });

  @override
  State<TrainingPackCard> createState() => _TrainingPackCardState();
}

class _TrainingPackCardState extends State<TrainingPackCard>
    with TickerProviderStateMixin {
  late bool _pinned;
  String? _completedAt;
  double? _accuracy;
  String? _lastAttempt;
  bool _passed = false;
  double? _evPct;
  double? _icmPct;
  double? _accPct;

  Future<void> _togglePin() async {
    await context.read<PinnedPackService>().toggle(widget.template.id);
    if (mounted) {
      setState(() {
        _pinned = !_pinned;
        widget.template.isPinned = _pinned;
      });
    }
  }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Прогресс сброшен')));
    }
    await widget.onRefresh?.call();
  }

  void _showUnlockHint() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Заблокировано'),
        content: Text('Чтобы разблокировать: ${widget.lockReason}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTap() async {
    if (widget.locked) {
      if (widget.lockReason != null) {
        _showUnlockHint();
      }
      return;
    }
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
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = DateTime.tryParse(
      prefs.getString('completed_at_tpl_${widget.template.id}') ?? '',
    );
    final acc = prefs.getDouble('last_accuracy_tpl_${widget.template.id}');
    final a0 = prefs.getDouble('last_accuracy_tpl_${widget.template.id}_0');
    final a1 = prefs.getDouble('last_accuracy_tpl_${widget.template.id}_1');
    final a2 = prefs.getDouble('last_accuracy_tpl_${widget.template.id}_2');
    final stat = await TrainingPackStatsService.getStats(widget.template.id);
    DateTime? last = stat?.last;
    if (last == null) {
      final ms = prefs.getInt('tpl_ts_${widget.template.id}');
      if (ms != null) last = DateTime.fromMillisecondsSinceEpoch(ms);
    }
    if (mounted) {
      setState(() {
        if (ts != null) _completedAt = formatLongDate(ts);
        if (acc != null) _accuracy = acc;
        _passed = a0 != null &&
            a1 != null &&
            a2 != null &&
            a0 >= 80 &&
            a1 >= 80 &&
            a2 >= 80;
        if (stat != null) {
          _evPct = stat.postEvPct > 0 ? stat.postEvPct : stat.preEvPct;
          _icmPct = stat.postIcmPct > 0 ? stat.postIcmPct : stat.preIcmPct;
          _accPct = stat.accuracy * 100;
        }
        if (last != null) {
          final locale = Intl.getCurrentLocale();
          _lastAttempt = DateFormat('dd MMM', locale).format(last.toLocal());
        }
      });
    }
  }

  Widget _progressLine() {
    final ev = _evPct ?? 0;
    final icm = _icmPct ?? 0;
    final acc = _accPct ?? 0;
    if (ev >= 100 && icm >= 100 && acc >= 100) return const SizedBox.shrink();
    Color c(double v) => v >= 90
        ? Colors.green
        : v >= 60
            ? Colors.yellow
            : Colors.red;
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'EV: '),
          TextSpan(
            text: '${ev.round()}%',
            style: TextStyle(color: c(ev)),
          ),
          const TextSpan(text: ', ICM: '),
          TextSpan(
            text: '${icm.round()}%',
            style: TextStyle(color: c(icm)),
          ),
          const TextSpan(text: ', Acc: '),
          TextSpan(
            text: '${acc.round()}%',
            style: TextStyle(color: c(acc)),
          ),
        ],
      ),
      style: const TextStyle(fontSize: 12, color: Colors.white70),
    );
  }

  @override
  Widget build(BuildContext context) {
    final updatedAt = widget.template.updatedDate ?? widget.template.createdAt;
    final isNew = DateTime.now().difference(updatedAt).inDays <= 3;
    final catSet = <String>{};
    for (final s in widget.template.spots) {
      for (final t in s.tags.where((t) => t.startsWith('cat:'))) {
        catSet.add(t.substring(4));
      }
    }
    final cats = [for (final c in catSet) translateMistakeCategory(c)];
    return GestureDetector(
      onLongPress: _togglePin,
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
            Positioned(
              left: 4,
              top: 4,
              child: GestureDetector(
                onTap: _togglePin,
                child: Text(
                  '📌',
                  style: TextStyle(
                    color: _pinned ? Colors.orange : Colors.white54,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.template.meta['theme'] != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Chip(
                            label: Text(
                              widget.template.meta['theme'].toString(),
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: Colors.blueGrey,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(
                              horizontal: -4,
                              vertical: -4,
                            ),
                          ),
                        ),
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
                      if (widget.locked && widget.lockReason != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            widget.lockReason!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (widget.template.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            widget.template.description,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: widget.template.meta['dynamicParams'] != null
                            ? Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 4,
                                ),
                                child: TrainingPackPreviewPanel(
                                  tpl: TrainingPackTemplateV2.fromTemplate(
                                    widget.template,
                                    type: TrainingType.pushFold,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
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
                                  labelStyle: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (widget.template.coveragePercent != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: CoverageMeter(
                            widget.template.coveragePercent!,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: widget.locked ? null : _handleTap,
                  child: const Text('Train'),
                ),
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
            if (isNew)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Text(
                    '🆕 Новая',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            if (widget.template.trending)
              Positioned(
                right: 4,
                top: isNew ? 24 : 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Text(
                    '🔥 Тренд',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            if (_passed)
              Positioned(
                right: 4,
                top: (isNew ? 24 : 4) + (widget.template.trending ? 20 : 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
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
            if (_evPct != null || _icmPct != null || _accPct != null)
              Positioned(bottom: 4, left: 4, child: _progressLine()),
            if (_lastAttempt != null ||
                (widget.dimmed && (_completedAt != null || _accuracy != null)))
              Positioned(
                bottom: 4,
                right: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_lastAttempt != null)
                      Text(
                        _lastAttempt!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    if (widget.dimmed && _completedAt != null)
                      Text(
                        _completedAt!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    if (widget.dimmed && _accuracy != null)
                      Text(
                        'Accuracy: ${_accuracy!.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            if (widget.locked)
              Positioned.fill(
                child: Tooltip(
                  message: widget.lockReason == null
                      ? 'Пак заблокирован'
                      : 'Чтобы разблокировать: ${widget.lockReason}',
                  child: InkWell(
                    onTap: widget.lockReason != null ? _showUnlockHint : null,
                    child: Container(
                      color: Colors.black54,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
