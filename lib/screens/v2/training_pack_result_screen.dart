import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/v2/training_pack_template.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../theme/app_colors.dart';
import 'training_pack_play_screen.dart';
import 'training_pack_template_editor_screen.dart';

class TrainingPackResultScreen extends StatefulWidget {
  final TrainingPackTemplate template;
  final TrainingPackTemplate original;
  final Map<String, String> results;
  const TrainingPackResultScreen({super.key, required this.template, required this.results, TrainingPackTemplate? original})
      : original = original ?? template;
  
  @override
  State<TrainingPackResultScreen> createState() => _TrainingPackResultScreenState();
}

class _TrainingPackResultScreenState extends State<TrainingPackResultScreen> {
  final ScrollController _controller = ScrollController();
  final _firstKey = GlobalKey();

  String? _expected(TrainingPackSpot s) {
    final eval = s.evalResult?.expectedAction;
    if (eval != null && eval.isNotEmpty) return eval;
    final acts = s.hand.actions[0] ?? [];
    for (final a in acts) {
      if (a.playerIndex == s.hand.heroIndex) return a.action;
    }
    return null;
  }

  int get _correct {
    var c = 0;
    for (final s in widget.template.spots) {
      final exp = _expected(s);
      final ans = widget.results[s.id];
      if (exp != null && ans != null && ans.toLowerCase() == exp.toLowerCase()) {
        c++;
      }
    }
    return c;
  }

  int get _total => widget.template.spots.length;
  int get _mistakes => _total - _correct;
  double get _rate => _total == 0 ? 0 : _correct * 100 / _total;

  String get _message {
    if (_correct == _total) return 'Perfect!';
    if (_rate >= 80) return 'Great effort!';
    return 'Keep training!';
  }

  List<double> get _evs => [for (final s in widget.template.spots) if (s.heroEv != null && widget.results.containsKey(s.id)) s.heroEv!];

  List<TrainingPackSpot> get _mistakeSpots => widget.template.spots
      .where((s) {
        final exp = _expected(s);
        final ans = widget.results[s.id];
        return exp != null &&
            ans != null &&
            ans != 'false' &&
            exp.toLowerCase() != ans.toLowerCase();
      }).toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _firstKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pack Result')),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _correct.toDouble()),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (_, value, __) => Opacity(
                opacity: value / _correct.clamp(1, double.infinity),
                child: Text('${value.round()} of $_total correct',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            Text(_message, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Mistakes: $_mistakes', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Accuracy: ${_mistakes == 0 ? '100' : _rate.toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white70)),
            if (_evs.length >= 2)
              const SizedBox(height: 16),
            if (_evs.length >= 2)
              _EvChart(evs: _evs)
            else
              const SizedBox.shrink(),
            if (_mistakeSpots.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Mistakes',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: _controller,
                  itemCount: _mistakeSpots.length,
                  itemBuilder: (context, i) {
                    final spot = _mistakeSpots[i];
                    final board = spot.hand.board.join(' ');
                    final hero = spot.hand.heroCards;
                    final exp = _expected(spot) ?? '';
                    final ans = widget.results[spot.id] ?? '';
                    return Container(
                      key: i == 0 ? _firstKey : null,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: Text(
                          board.isEmpty ? '(Preflop)' : board,
                          style: const TextStyle(color: Colors.white),
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hero: $hero',
                                style:
                                    const TextStyle(color: Colors.white70),
                                softWrap: false,
                                overflow: TextOverflow.ellipsis),
                            Text('Expected: $exp',
                                style:
                                    const TextStyle(color: Colors.greenAccent),
                                softWrap: false,
                                overflow: TextOverflow.ellipsis),
                            Text('Your: $ans',
                                style:
                                    const TextStyle(color: Colors.redAccent),
                                softWrap: false,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            ElevatedButton(
              onPressed: _mistakes == 0
                  ? null
                  : () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('tpl_seq_${widget.original.id}');
                      await prefs.remove('tpl_prog_${widget.original.id}');
                      await prefs.remove('tpl_res_${widget.original.id}');
                      await prefs.remove('tpl_ts_${widget.original.id}');
                      final spots = widget.template.spots.where((s) {
                        final exp = _expected(s);
                        final ans = widget.results[s.id];
                        return exp != null &&
                            ans != null &&
                            ans != 'false' &&
                            exp.toLowerCase() != ans.toLowerCase();
                      }).toList();
                      final retry = widget.template.copyWith(id: const Uuid().v4(), name: 'Retry mistakes', spots: spots);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrainingPackPlayScreen(template: retry, original: widget.original),
                        ),
                      );
                    },
              child: const Text('Retry Mistakes'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrainingPackTemplateEditorScreen(template: widget.original, templates: [widget.original]),
                  ),
                );
              },
              child: const Text('View Pack'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Back to List'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvChart extends StatelessWidget {
  final List<double> evs;
  const _EvChart({required this.evs});

  @override
  Widget build(BuildContext context) {
    if (evs.length < 2) return const SizedBox.shrink();
    final maxEv = evs.reduce(max);
    final minEv = evs.reduce(min);
    final limit = max(maxEv.abs(), minEv.abs());
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < evs.length; i++) {
      final ev = evs[i];
      final color = ev >= 0 ? Colors.greenAccent : Colors.redAccent;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: ev,
              width: 14,
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.7), color],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        ),
      );
    }
    var interval = limit == 0 ? 1.0 : (limit / 5).ceilToDouble();
    return Tooltip(
      message: 'Only spots you actually answered',
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: BarChart(
        BarChartData(
          maxY: limit,
          minY: -limit,
          alignment: BarChartAlignment.spaceBetween,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.white24, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= evs.length) return const SizedBox.shrink();
                  return Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 10));
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              left: BorderSide(color: Colors.white24),
              bottom: BorderSide(color: Colors.white24),
            ),
          ),
          barGroups: groups,
        ),
      ),
    );
  }
}
