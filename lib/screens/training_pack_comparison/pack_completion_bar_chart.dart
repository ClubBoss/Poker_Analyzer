import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../helpers/date_utils.dart';
import '../../models/training_pack_stats.dart';
import '../../models/pack_chart_sort_option.dart';

class PackCompletionBarChart extends StatefulWidget {
  final List<TrainingPackStats> stats;
  final bool hideCompleted;
  final bool forgottenOnly;
  final PackChartSort sort;

  const PackCompletionBarChart({
    super.key,
    required this.stats,
    required this.hideCompleted,
    required this.forgottenOnly,
    required this.sort,
  });

  @override
  State<PackCompletionBarChart> createState() => _PackCompletionBarChartState();
}

class _PackCompletionBarChartState extends State<PackCompletionBarChart>
    with SingleTickerProviderStateMixin {
  int? _index;
  Offset? _pos;
  Timer? _timer;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  void _show(int index, Offset pos) {
    if (_index == index) {
      _hide();
      return;
    }
    _timer?.cancel();
    setState(() {
      _index = index;
      _pos = pos;
    });
    _anim.forward(from: 0);
    _timer = Timer(const Duration(seconds: 2), _hide);
  }

  void _hide() {
    _timer?.cancel();
    if (_index != null) {
      setState(() => _index = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final filtered = widget.stats.where((s) {
      final progress = s.total > 0 ? (s.total - s.mistakes) / s.total : 0.0;
      final completed = progress >= 1.0;
      final forgotten =
          s.lastSession == null || now.difference(s.lastSession!).inDays >= 7;
      if (widget.hideCompleted && completed) return false;
      if (widget.forgottenOnly && !forgotten) return false;
      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (widget.sort) {
        case PackChartSort.lastSession:
          final da = a.lastSession ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.lastSession ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        case PackChartSort.handsPlayed:
          return b.total.compareTo(a.total);
        case PackChartSort.progress:
        default:
          final pa = a.total > 0 ? (a.total - a.mistakes) * 100 / a.total : 0.0;
          final pb = b.total > 0 ? (b.total - b.mistakes) * 100 / b.total : 0.0;
          return pb.compareTo(pa);
      }
    });

    if (filtered.isEmpty) {
      return const SizedBox.shrink();
    }

    final groups = <BarChartGroupData>[];
    for (var i = 0; i < filtered.length; i++) {
      final stat = filtered[i];
      final percent = stat.total > 0
          ? (stat.total - stat.mistakes) * 100 / stat.total
          : 0.0;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: percent,
              width: 14,
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [Colors.lightGreenAccent, Colors.green],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ],
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.7,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          BarChart(
            BarChartData(
              maxY: 100,
              minY: 0,
              barGroups: groups,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                handleBuiltInTouches: false,
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions ||
                      response?.spot == null) {
                    return;
                  }
                  _show(
                    response!.spot!.touchedBarGroupIndex,
                    response.touchLocation,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, _) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= filtered.length) {
                        return const SizedBox.shrink();
                      }
                      return Transform.rotate(
                        angle: -1.5708,
                        child: Text(
                          filtered[idx].pack.name,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
            ),
          ),
          if (_index != null && _pos != null && _index! < filtered.length)
            _BarTooltip(
              position: (context.findRenderObject() as RenderBox).globalToLocal(
                    _pos!,
                  ) -
                  const Offset(40, 60),
              stats: filtered[_index!],
              animation: _anim,
            ),
        ],
      ),
    );
  }
}

class _BarTooltip extends StatefulWidget {
  final Offset position;
  final TrainingPackStats stats;
  final Animation<double> animation;

  const _BarTooltip({
    required this.position,
    required this.stats,
    required this.animation,
  });

  @override
  State<_BarTooltip> createState() => _BarTooltipState();
}

class _BarTooltipState extends State<_BarTooltip> {
  @override
  Widget build(BuildContext context) {
    final s = widget.stats;
    final completed = s.total - s.mistakes;
    final percent = s.total > 0 ? completed * 100 / s.total : 0.0;
    final remain = s.total - completed;
    final last =
        s.lastSession != null ? formatDate(s.lastSession!) : 'нет данных';
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: FadeTransition(
        opacity: widget.animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.8, end: 1.0).animate(widget.animation),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${percent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$completed/${s.total} (осталось $remain)',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  Text(
                    last,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
