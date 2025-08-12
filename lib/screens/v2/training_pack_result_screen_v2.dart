import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import '../../models/v2/training_pack_template.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../theme/app_colors.dart';
import 'training_pack_play_screen.dart';
import '../../services/mistake_review_pack_service.dart';
import '../../utils/responsive.dart';
import '../../services/smart_suggestion_service.dart';
import '../../services/training_session_service.dart';
import '../../core/training/generation/yaml_reader.dart';
import '../../services/weak_spot_recommendation_service.dart';
import '../training_session_screen.dart';
import '../../services/auto_mistake_tagger_engine.dart';
import '../../models/training_spot_attempt.dart';
import '../../models/mistake_tag.dart';

class TrainingPackResultScreenV2 extends StatefulWidget {
  final TrainingPackTemplate template;
  final TrainingPackTemplate original;
  final Map<String, String> results;
  const TrainingPackResultScreenV2({
    super.key,
    required this.template,
    required this.results,
    TrainingPackTemplate? original,
  }) : original = original ?? template;

  @override
  State<TrainingPackResultScreenV2> createState() => _TrainingPackResultScreenV2State();
}

class _TrainingPackResultScreenV2State extends State<TrainingPackResultScreenV2> {
  final List<TrainingPackTemplate> _related = [];

  @override
  void initState() {
    super.initState();
    _loadRelated();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowPackTip());
  }

  Future<void> _loadRelated() async {
    final service = context.read<SmartSuggestionService>();
    final paths = await service.suggestRelated(widget.template.tags);
    final docs = await getApplicationDocumentsDirectory();
    const reader = YamlReader();
    for (final rel in paths) {
      final file = File(p.join(docs.path, 'training_packs', 'library', rel));
      if (!file.existsSync()) continue;
      try {
        final map = reader.read(await file.readAsString());
        _related.add(TrainingPackTemplate.fromJson(map));
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  Future<void> _maybeShowPackTip() async {
    final total = widget.template.spots.length;
    int correct = 0;
    for (final s in widget.template.spots) {
      final exp = _expected(s);
      final ans = widget.results[s.id];
      if (exp != null && ans != null && ans.toLowerCase() == exp.toLowerCase()) {
        correct++;
      }
    }
    if (total < 10) return;
    final acc = total == 0 ? 0.0 : correct * 100 / total;
    if (acc >= 90) return;
    final weak = context.read<WeakSpotRecommendationService>();
    final tpl = await weak.buildPack();
    final rec = weak.recommendation;
    if (tpl == null || rec == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'weak_tip_${rec.position.name}';
    final lastStr = prefs.getString(key);
    if (lastStr != null) {
      final last = DateTime.tryParse(lastStr);
      if (last != null && DateTime.now().difference(last) < const Duration(days: 1)) {
        return;
      }
    }
    await prefs.setString(key, DateTime.now().toIso8601String());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Want to improve your ${rec.position.label}? Try ${tpl.name}.'),
        action: SnackBarAction(
          label: 'Train',
          onPressed: () async {
            await context.read<TrainingSessionService>().startSession(tpl, persist: false);
            if (!context.mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
            );
          },
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  String? _expected(TrainingPackSpot s) {
    final eval = s.evalResult?.expectedAction;
    if (eval != null && eval.isNotEmpty) return eval;
    for (final a in s.hand.actions[0] ?? []) {
      if (a.playerIndex == s.hand.heroIndex) return a.action;
    }
    return null;
  }

  double? _actionEv(TrainingPackSpot s, String action) {
    for (final a in s.hand.actions[0] ?? []) {
      if (a.playerIndex == s.hand.heroIndex &&
          a.action.toLowerCase() == action.toLowerCase()) {
        return a.ev;
      }
    }
    return null;
  }

  double? _actionIcmEv(TrainingPackSpot s, String action) {
    for (final a in s.hand.actions[0] ?? []) {
      if (a.playerIndex == s.hand.heroIndex &&
          a.action.toLowerCase() == action.toLowerCase()) {
        return a.icmEv;
      }
    }
    return null;
  }

  double? _bestEv(TrainingPackSpot s) {
    double? best;
    for (final a in s.hand.actions[0] ?? []) {
      if (a.playerIndex == s.hand.heroIndex && a.ev != null) {
        best = best == null ? a.ev! : max(best, a.ev!);
      }
    }
    return best;
  }

  double? _bestIcmEv(TrainingPackSpot s) {
    double? best;
    for (final a in s.hand.actions[0] ?? []) {
      if (a.playerIndex == s.hand.heroIndex && a.icmEv != null) {
        best = best == null ? a.icmEv! : max(best, a.icmEv!);
      }
    }
    return best;
  }

  Future<void> _repeat(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tpl_seq_${widget.original.id}');
    await prefs.remove('tpl_prog_${widget.original.id}');
    await prefs.remove('tpl_res_${widget.original.id}');
    await prefs.remove('tpl_ts_${widget.original.id}');
    if (widget.original.targetStreet != null) {
      await prefs.remove('tpl_street_${widget.original.id}');
    }
    if (widget.original.focusHandTypes.isNotEmpty) {
      await prefs.remove('tpl_hand_${widget.original.id}');
    }
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackPlayScreen(
          template: widget.template,
          original: widget.original,
        ),
      ),
    );
  }

  Widget _emptyResultState() => const Center(
        child: Text('Нет данных', style: TextStyle(color: Colors.white70)),
      );

  Future<void> _exportCsv(BuildContext context) async {
    final rows = <List<dynamic>>[
      ['Title', 'Your', 'Correct', 'EV diff', 'ICM diff']
    ];
    for (final s in widget.template.spots) {
      final ans = widget.results[s.id];
      final exp = _expected(s);
      if (ans == null || exp == null) continue;
      final heroEv = _actionEv(s, ans);
      final bestEv = _bestEv(s);
      final heroIcm = _actionIcmEv(s, ans);
      final bestIcm = _bestIcmEv(s);
      final evDiff = heroEv != null && bestEv != null ? heroEv - bestEv : null;
      final icmDiff =
          heroIcm != null && bestIcm != null ? heroIcm - bestIcm : null;
      rows.add([
        s.title,
        ans,
        exp,
        evDiff?.toStringAsFixed(2) ?? '',
        icmDiff?.toStringAsFixed(3) ?? ''
      ]);
    }
    final csvStr = const ListToCsvConverter().convert(rows, eol: '\r\n');
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/pack_result_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvStr, encoding: utf8);
    await Share.shareXFiles([XFile(file.path)], text: 'pack_result.csv');
  }


  @override
  Widget build(BuildContext context) {
    if (widget.template.id == MistakeReviewPackService.cachedTemplate?.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<MistakeReviewPackService>().setProgress(0);
      });
    }
    final spots = widget.template.spots;
    if (spots.isEmpty) return _emptyResultState();
    int correct = 0;
    final diffs = <double>[];
    final icmDiffs = <double>[];
    final mistakes = <_MistakeData>[];
    for (final s in spots) {
      final ans = widget.results[s.id];
      final exp = _expected(s);
      if (ans == null || exp == null) continue;
      final heroEv = _actionEv(s, ans);
      final bestEv = _bestEv(s);
      final heroIcm = _actionIcmEv(s, ans);
      final bestIcm = _bestIcmEv(s);
      if (heroEv != null && bestEv != null) diffs.add(heroEv - bestEv);
      if (heroIcm != null && bestIcm != null) icmDiffs.add(heroIcm - bestIcm);
      if (ans.toLowerCase() == exp.toLowerCase()) {
        correct++;
      } else {
        mistakes.add(
            _MistakeData(s, ans, exp, heroEv, bestEv, heroIcm, bestIcm));
      }
    }
    final total = spots.length;
    final accuracy = total == 0 ? 0 : correct * 100 / total;
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Результаты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Export CSV',
            onPressed: () => _exportCsv(context),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Точность: ${accuracy.toStringAsFixed(1)}%',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 8),
            Text('Верно: $correct / $total',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
            Text('Ошибки: ${total - correct}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
            if (diffs.length >= 2) ...[
              const SizedBox(height: 16),
              _EvDiffChart(diffs: diffs),
            ],
            if (icmDiffs.length >= 2) ...[
              const SizedBox(height: 16),
              _IcmDiffChart(diffs: icmDiffs),
            ],
            if (mistakes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Ошибки:',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: mistakes.length,
                  itemBuilder: (context, i) {
                    final m = mistakes[i];
                    final board = m.spot.hand.board.join(' ');
                    final hero = m.spot.hand.heroCards;
                    final diff = _calcEvDiff(m.heroEv, m.bestEv, m.ans, m.exp);
                    final diffText = diff == null
                        ? '--'
                        : '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            board.isEmpty ? '(Preflop)' : board,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hero: $hero',
                                style: const TextStyle(color: Colors.white70)),
                            Text('Ваше действие: ${m.ans}',
                                style: const TextStyle(color: Colors.redAccent)),
                            Text('Лучшее действие: ${m.exp}',
                                style:
                                    const TextStyle(color: Colors.greenAccent)),
                            Text('EV diff: $diffText',
                                style: const TextStyle(color: Colors.white70)),
                            if (m.tags.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  spacing: 4,
                                  children: [
                                    for (final t in m.tags)
                                      Chip(
                                        label: Text(
                                          t.label,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        backgroundColor:
                                            _tagColors[t] ?? Colors.blueGrey,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else
              const Spacer(),
            if (_related.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('📌 Похожие паки',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (final r in _related)
                ListTile(
                  title: Text(r.name),
                  onTap: () async {
                    final session = await context
                        .read<TrainingSessionService>()
                        .startFromTemplate(r);
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TrainingPackPlayScreen(
                                template: r,
                                original: r,
                              )),
                    );
                  },
                ),
            ],
            ElevatedButton(
              onPressed: () => _repeat(context),
              child: const Text('Повторить тренировку'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Назад'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvDiffChart extends StatelessWidget {
  final List<double> diffs;
  const _EvDiffChart({required this.diffs});

  @override
  Widget build(BuildContext context) {
    if (diffs.isEmpty) return const SizedBox.shrink();
    final limit = diffs.map((e) => e.abs()).reduce(max);
    final maxY = limit == 0 ? 1.0 : limit;
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < diffs.length; i++) {
      final d = diffs[i];
      final color = d > 0
          ? Colors.greenAccent
          : d < 0
              ? Colors.redAccent
              : Colors.blueGrey;
      groups.add(
        BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: d,
            width: 14,
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.7), color],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ]),
      );
    }
    final interval = maxY / 5;
    return Container(
      height: responsiveSize(context, 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: -maxY,
          alignment: BarChartAlignment.spaceBetween,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) =>
                const FlLine(color: Colors.white24, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: 48,
                getTitlesWidget: (value, _) => Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= diffs.length) {
                    return const SizedBox.shrink();
                  }
                  return Text('${i + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 10));
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

class _IcmDiffChart extends StatelessWidget {
  final List<double> diffs;
  const _IcmDiffChart({required this.diffs});

  @override
  Widget build(BuildContext context) {
    if (diffs.isEmpty) return const SizedBox.shrink();
    final limit = diffs.map((e) => e.abs()).reduce(max);
    final maxY = limit == 0 ? 1.0 : limit;
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < diffs.length; i++) {
      final d = diffs[i];
      final color = d > 0
          ? Colors.greenAccent
          : d < 0
              ? Colors.redAccent
              : Colors.blueGrey;
      groups.add(
        BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: d,
            width: 14,
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.7), color],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ]),
      );
    }
    final interval = maxY / 5;
    return Container(
      height: responsiveSize(context, 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: -maxY,
          alignment: BarChartAlignment.spaceBetween,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) =>
                const FlLine(color: Colors.white24, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: 48,
                getTitlesWidget: (value, _) => Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= diffs.length) {
                    return const SizedBox.shrink();
                  }
                  return Text('${i + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 10));
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

double? _calcEvDiff(
    double? heroEv, double? bestEv, String user, String correct) {
  if (heroEv == null || bestEv == null) return null;
  final c = correct.toLowerCase();
  if (c == 'push' || c == 'call' || c == 'raise') {
    return bestEv - heroEv;
  }
  return heroEv - bestEv;
}

const Map<MistakeTag, Color> _tagColors = {
  MistakeTag.overpush: Colors.redAccent,
  MistakeTag.looseCallBb: Colors.redAccent,
  MistakeTag.looseCallSb: Colors.redAccent,
  MistakeTag.looseCallCo: Colors.redAccent,
  MistakeTag.overfoldBtn: Colors.blueAccent,
  MistakeTag.overfoldShortStack: Colors.blueAccent,
  MistakeTag.missedEvPush: Colors.blueAccent,
  MistakeTag.missedEvCall: Colors.blueAccent,
  MistakeTag.missedEvRaise: Colors.blueAccent,
};

class _MistakeData {
  final TrainingPackSpot spot;
  final String ans;
  final String exp;
  final double? heroEv;
  final double? bestEv;
  final double? heroIcmEv;
  final double? bestIcmEv;
  late final List<MistakeTag> tags;

  _MistakeData(this.spot, this.ans, this.exp, this.heroEv, this.bestEv,
      this.heroIcmEv, this.bestIcmEv) {
    final diff = _calcEvDiff(heroEv, bestEv, ans, exp);
    final attempt = TrainingSpotAttempt(
      spot: spot,
      userAction: ans,
      correctAction: exp,
      evDiff: diff ?? 0,
    );
    tags = const AutoMistakeTaggerEngine().tag(attempt);
  }
}
