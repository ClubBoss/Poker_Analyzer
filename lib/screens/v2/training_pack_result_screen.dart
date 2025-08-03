import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../utils/responsive.dart';

import '../../models/v2/training_pack_template.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../helpers/hand_utils.dart';
import '../../helpers/hand_type_utils.dart';
import '../../theme/app_colors.dart';
import 'training_pack_play_screen.dart';
import 'training_pack_template_editor_screen.dart';
import '../../services/mistake_review_pack_service.dart';
import '../../services/training_pack_stats_service.dart';
import '../../services/training_pack_template_storage_service.dart';
import '../../services/smart_review_service.dart';
import '../../widgets/common/animated_line_chart.dart';
import '../../services/weak_spot_recommendation_service.dart';
import '../training_session_screen.dart';
import '../../services/booster_recap_hook.dart';
import '../../services/training_session_service.dart';
import '../../services/pack_library_completion_service.dart';

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

  double? _actionEv(TrainingPackSpot s, String act) {
    for (final a in s.hand.actions[0] ?? []) {
      if (a.playerIndex == s.hand.heroIndex &&
          a.action.toLowerCase() == act.toLowerCase()) {
        return a.ev;
      }
    }
    return null;
  }

  double? _actionIcmEv(TrainingPackSpot s, String act) {
    for (final a in s.hand.actions[0] ?? []) {
      if (a.playerIndex == s.hand.heroIndex &&
          a.action.toLowerCase() == act.toLowerCase()) {
        return a.icmEv;
      }
    }
    return null;
  }

  double? _bestEv(TrainingPackSpot s) {
    double? best;
    for (final a in s.hand.actions[0] ?? []) {
      if (a.playerIndex == s.hand.heroIndex && a.ev != null) {
        best = best == null ? a.ev! : math.max(best, a.ev!);
      }
    }
    return best;
  }

  double? _bestIcmEv(TrainingPackSpot s) {
    double? best;
    for (final a in s.hand.actions[0] ?? []) {
      if (a.playerIndex == s.hand.heroIndex && a.icmEv != null) {
        best = best == null ? a.icmEv! : math.max(best, a.icmEv!);
      }
    }
    return best;
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

  List<double> get _evs => [
        for (final s in widget.template.spots)
          if (s.heroEv != null && widget.results.containsKey(s.id))
            s.heroEv! * s.priority
      ];

  List<double> get _icmEvs => [
        for (final s in widget.template.spots)
          if (s.heroIcmEv != null && widget.results.containsKey(s.id))
            s.heroIcmEv! * s.priority
      ];

  double get _evSum => _evs.fold(0.0, (a, b) => a + b);
  double get _icmSum => _icmEvs.fold(0.0, (a, b) => a + b);

  List<double> get _evDeltas {
    final list = <double>[];
    for (final s in widget.template.spots) {
      final ans = widget.results[s.id];
      if (ans == null) continue;
      final hero = _actionEv(s, ans);
      final best = _bestEv(s);
      if (hero != null && best != null) list.add((hero - best) * s.priority);
    }
    return list;
  }

  List<double> get _icmDeltas {
    final list = <double>[];
    for (final s in widget.template.spots) {
      final ans = widget.results[s.id];
      if (ans == null) continue;
      final hero = _actionIcmEv(s, ans);
      final best = _bestIcmEv(s);
      if (hero != null && best != null) list.add((hero - best) * s.priority);
    }
    return list;
  }

  List<double> get _evCumulative {
    final list = <double>[];
    double sum = 0;
    for (final d in _evDeltas) {
      sum += d;
      list.add(sum);
    }
    return list;
  }

  List<double> get _icmCumulative {
    final list = <double>[];
    double sum = 0;
    for (final d in _icmDeltas) {
      sum += d;
      list.add(sum);
    }
    return list;
  }

  double get _evDeltaSum => _evDeltas.fold(0.0, (a, b) => a + b);
  double get _icmDeltaSum => _icmDeltas.fold(0.0, (a, b) => a + b);

  List<TrainingPackSpot> get _mistakeSpots => widget.template.spots
      .where((s) {
        final exp = _expected(s);
        final ans = widget.results[s.id];
        return exp != null &&
            ans != null &&
            ans != 'false' &&
            exp.toLowerCase() != ans.toLowerCase();
      }).toList();

  List<String> get _mistakeIds => [for (final s in _mistakeSpots) s.id];

  @override
  void initState() {
    super.initState();
    final ids = _mistakeIds;
    if (ids.isNotEmpty) {
      final template = widget.template.copyWith(
        id: const Uuid().v4(),
        name: 'Review mistakes',
        spots: [for (final s in widget.template.spots) if (ids.contains(s.id)) s],
      );
      MistakeReviewPackService.setLatestTemplate(template);
      unawaited(context.read<MistakeReviewPackService>().addPack(ids,
          templateId: widget.template.id));
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final start = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text('Repeat mistakes',
                style: TextStyle(color: Colors.white)),
            content: Text('Start ${ids.length} mistakes now?',
                style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        if (start == true && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TrainingPackPlayScreen(
                template: MistakeReviewPackService.cachedTemplate!,
                original: null,
              ),
            ),
          );
        }
      });
    }
    if (widget.template.id == MistakeReviewPackService.cachedTemplate?.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<MistakeReviewPackService>().setProgress(0);
      });
    }
    final achieved = _correct == _total;
    PreferencesService.getInstance()
        .then((p) => p.setBool('tpl_goal_${widget.original.id}', achieved));
    final storage = context.read<TrainingPackTemplateStorageService>();
    if (widget.original.focusHandTypes.isNotEmpty) {
      for (final g in widget.original.focusHandTypes) {
        int attempts = 0;
        int correct = 0;
        int total = 0;
        for (final s in widget.original.spots) {
          final code = handCode(s.hand.heroCards);
          if (code != null && matchHandTypeLabel(g.label, code)) {
            total++;
            final ans = widget.results[s.id];
            if (ans != null) {
              attempts++;
              final exp = _expected(s);
              if (exp != null && ans.toLowerCase() == exp.toLowerCase()) {
                correct++;
              }
            }
          }
        }
        final accuracy = attempts > 0 ? correct * 100 / attempts : 0.0;
        final completed = attempts >= total && total > 0;
        storage.saveGoalProgress(
          widget.original.id,
          g.label,
          completed: completed,
          attempts: attempts,
          accuracy: accuracy,
          lastTrainedAt: DateTime.now(),
        );
      }
    }
    final total = widget.template.totalWeight;
    final preEv = total == 0 ? 0.0 : widget.original.evCovered * 100 / total;
    final preIcm = total == 0 ? 0.0 : widget.original.icmCovered * 100 / total;
    final postEv = total == 0 ? 0.0 : widget.template.evCovered * 100 / total;
    final postIcm = total == 0 ? 0.0 : widget.template.icmCovered * 100 / total;
    unawaited(TrainingPackStatsService.recordSession(
      widget.original.id,
      _correct,
      _total,
      preEvPct: preEv,
      preIcmPct: preIcm,
      postEvPct: postEv,
      postIcmPct: postIcm,
      evSum: _evDeltaSum,
      icmSum: _icmDeltaSum,
    ));
    unawaited(SmartReviewService.instance.registerCompletion(
      _total == 0 ? 0.0 : _correct / _total,
      postEv / 100,
      postIcm / 100,
      context: context,
    ));
    unawaited(PackLibraryCompletionService.instance.registerCompletion(
      widget.original.id,
      correct: _correct,
      total: _total,
    ));
    PreferencesService.getInstance().then((p) =>
        p.setString('last_trained_tpl_${widget.original.id}', DateTime.now().toIso8601String()));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _firstKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowPackTip());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tagSet = <String>{};
      for (final s in _mistakeSpots) {
        for (final t in s.tags) {
          final tag = t.trim();
          if (tag.isNotEmpty) tagSet.add(tag);
        }
      }
      BoosterRecapHook.instance
          .onDrillResult(mistakes: _mistakeSpots.length, tags: tagSet.toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: const Text('Pack Result')),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(l.spotsLabel('$_total'), style: const TextStyle(color: Colors.white)),
                  Text('•', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  Text(l.accuracyLabel(_rate.toStringAsFixed(0)), style: const TextStyle(color: Colors.white)),
                  Text('•', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  Text(
                    l.evBb("${_evSum >= 0 ? '+' : ''}${_evSum.toStringAsFixed(1)}"),
                    style: TextStyle(
                      color: _evSum > 0
                          ? Colors.greenAccent
                          : (_evSum < 0 ? Colors.redAccent : Colors.amber),
                    ),
                  ),
                  if (_icmEvs.isNotEmpty) ...[
                    Text('•', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                    Text(
                      l.icmLabel("${_icmSum >= 0 ? '+' : ''}${_icmSum.toStringAsFixed(1)}"),
                      style: TextStyle(
                        color: _icmSum > 0
                            ? Colors.greenAccent
                            : (_icmSum < 0 ? Colors.redAccent : Colors.amber),
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
            if (_evCumulative.length + _icmCumulative.length >= 4) ...[
              const SizedBox(height: 16),
              _DeltaChart(ev: _evCumulative, icm: _icmCumulative),
            ],
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
            if (_mistakeIds.isNotEmpty) ...[
              ElevatedButton(
                onPressed: () async {
                  final template = widget.template.copyWith(
                    id: const Uuid().v4(),
                    name: 'Review mistakes',
                    spots: [for (final s in widget.template.spots) if (_mistakeIds.contains(s.id)) s],
                  );
                  MistakeReviewPackService.setLatestTemplate(template);
                  await context
                      .read<MistakeReviewPackService>()
                      .addPack(_mistakeIds, templateId: widget.template.id);
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrainingPackPlayScreen(
                        template:
                            MistakeReviewPackService.cachedTemplate!,
                        original: null,
                      ),
                    ),
                  );
                },
                child: Text('🔥 Review ${_mistakeIds.length} mistakes'),
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton(
              onPressed: _mistakes == 0
                  ? null
                  : () async {
                      final prefs = await PreferencesService.getInstance();
                      await prefs.remove('tpl_seq_${widget.original.id}');
                      await prefs.remove('tpl_prog_${widget.original.id}');
                      await prefs.remove('tpl_res_${widget.original.id}');
                      await prefs.remove('tpl_ts_${widget.original.id}');
                      if (widget.original.targetStreet != null) {
                        await prefs.remove('tpl_street_${widget.original.id}');
                      }
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

  Future<void> _maybeShowPackTip() async {
    final total = widget.template.spots.length;
    if (total < 10) return;
    int correct = 0;
    for (final s in widget.template.spots) {
      final exp = _expected(s);
      final ans = widget.results[s.id];
      if (exp != null && ans != null && ans.toLowerCase() == exp.toLowerCase()) {
        correct++;
      }
    }
    final acc = total == 0 ? 0.0 : correct * 100 / total;
    if (acc >= 90) return;
    final weak = context.read<WeakSpotRecommendationService>();
    final tpl = await weak.buildPack();
    final rec = weak.recommendation;
    if (tpl == null || rec == null) return;
    final prefs = await PreferencesService.getInstance();
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
        content: Text('Want to improve your ${rec.position.label}? Try ${tpl.name}.'),
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

}

class _DeltaChart extends StatelessWidget {
  final List<double> ev;
  final List<double> icm;
  const _DeltaChart({required this.ev, required this.icm});

  @override
  Widget build(BuildContext context) {
    final len = math.max(ev.length, icm.length);
    if (len < 2) return const SizedBox.shrink();
    final evSpots = <FlSpot>[];
    final icmSpots = <FlSpot>[];
    double minY = 0;
    double maxY = 0;
    for (var i = 0; i < ev.length; i++) {
      final v = ev[i];
      if (v < minY) minY = v;
      if (v > maxY) maxY = v;
      evSpots.add(FlSpot(i.toDouble(), v));
    }
    for (var i = 0; i < icm.length; i++) {
      final v = icm[i];
      if (v < minY) minY = v;
      if (v > maxY) maxY = v;
      icmSpots.add(FlSpot(i.toDouble(), v));
    }
    final range = maxY - minY;
    final interval = range > 0 ? (range / 5).ceilToDouble() : 1.0;
    final step = (len / 6).ceil();
    return Container(
      height: responsiveSize(context, 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedLineChart(
        data: LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) => const FlLine(color: Colors.white24, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  if (i < 0 || i >= len) return const SizedBox.shrink();
                  if (i % step != 0 && i != len - 1) return const SizedBox.shrink();
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
          lineBarsData: [
            if (evSpots.isNotEmpty)
              LineChartBarData(
                spots: evSpots,
                color: Colors.greenAccent,
                barWidth: 2,
                isCurved: false,
                dotData: const FlDotData(show: false),
              ),
            if (icmSpots.isNotEmpty)
              LineChartBarData(
                spots: icmSpots,
                color: Colors.lightBlueAccent,
                barWidth: 2,
                isCurved: false,
                dotData: const FlDotData(show: false),
              ),
          ],
        ),
      ),
    );
  }
}
