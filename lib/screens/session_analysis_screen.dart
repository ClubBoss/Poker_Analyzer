import 'package:flutter/material.dart';

import '../models/saved_hand.dart';
import '../models/action_entry.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/v2/training_pack_spot.dart';
import '../helpers/hand_utils.dart';
import '../services/evaluation_executor_service.dart';
import '../services/mistake_review_pack_service.dart';
import '../services/training_session_service.dart';
import '../services/training_pack_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/pack_export_service.dart';
import '../services/file_saver_service.dart';
import 'session_replay_screen.dart';
import '../widgets/common/animated_line_chart.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import '../constants/app_constants.dart';
import '../services/session_note_service.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'training_session_screen.dart';

class SessionAnalysisScreen extends StatefulWidget {
  final List<SavedHand> hands;
  const SessionAnalysisScreen({super.key, required this.hands});

  @override
  State<SessionAnalysisScreen> createState() => _SessionAnalysisScreenState();
}

class _SessionAnalysisScreenState extends State<SessionAnalysisScreen> {
  final List<double> _evs = [];
  final List<double> _icms = [];
  bool _loading = true;
  late TextEditingController _noteController;

  int get _sessionId =>
      widget.hands.isNotEmpty ? widget.hands.first.sessionId : 0;

  @override
  void initState() {
    super.initState();
    final notes = context.read<SessionNoteService>();
    _noteController = TextEditingController(text: notes.noteFor(_sessionId))
      ..addListener(() => notes.setNote(_sessionId, _noteController.text));
    WidgetsBinding.instance.addPostFrameCallback((_) => _compute());
  }

  Future<void> _compute() async {
    final executor = context.read<EvaluationExecutorService>();
    final data = [...widget.hands]
      ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
    final evs = <double>[];
    final icms = <double>[];
    for (final h in data) {
      final spot = _spotFromHand(h);
      try {
        await executor.evaluateSingle(context, spot, hand: h, anteBb: h.anteBb);
      } catch (_) {}
      evs.add(spot.heroEv ?? 0);
      icms.add(spot.heroIcmEv ?? 0);
    }
    if (!mounted) return;
    setState(() {
      _evs
        ..clear()
        ..addAll(evs);
      _icms
        ..clear()
        ..addAll(icms);
      _loading = false;
    });
    if (!mounted) return;
    _offerTraining();
  }

  Future<void> _offerTraining() async {
    final tpl = await TrainingPackService.createDrillFromTopCategories(context);
    if (tpl == null || !mounted) return;
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Text(l.startTrainingSessionPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<TrainingSessionService>().startSession(tpl);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  HeroPosition _posFromString(String s) {
    final p = s.toUpperCase();
    if (p.startsWith('SB')) return HeroPosition.sb;
    if (p.startsWith('BB')) return HeroPosition.bb;
    if (p.startsWith('BTN')) return HeroPosition.btn;
    if (p.startsWith('CO')) return HeroPosition.co;
    if (p.startsWith('MP') || p.startsWith('HJ')) return HeroPosition.mp;
    if (p.startsWith('UTG')) return HeroPosition.utg;
    return HeroPosition.unknown;
  }

  TrainingPackSpot _spotFromHand(SavedHand h) {
    final heroCards =
        h.playerCards[h.heroIndex].map((c) => '${c.rank}${c.suit}').join(' ');
    final actions = <ActionEntry>[
      for (final a in h.actions)
        if (a.street == 0) a,
    ];
    final stacks = <String, double>{
      for (int i = 0; i < h.numberOfPlayers; i++)
        '$i': (h.stackSizes[i] ?? 0).toDouble(),
    };
    return TrainingPackSpot(
      id: const Uuid().v4(),
      hand: HandData(
        heroCards: heroCards,
        position: _posFromString(h.heroPosition),
        heroIndex: h.heroIndex,
        playerCount: h.numberOfPlayers,
        stacks: stacks,
        actions: {0: actions},
        anteBb: h.anteBb,
      ),
    );
  }

  Widget _buildChart() {
    if (_evs.length < 2) return const SizedBox.shrink();
    final spotsEv = <FlSpot>[];
    final spotsIcm = <FlSpot>[];
    double maxAbs = 0;
    for (var i = 0; i < _evs.length; i++) {
      final ev = _evs[i];
      final icm = _icms[i];
      if (ev.abs() > maxAbs) maxAbs = ev.abs();
      if (icm.abs() > maxAbs) maxAbs = icm.abs();
      spotsEv.add(FlSpot(i.toDouble(), ev));
      spotsIcm.add(FlSpot(i.toDouble(), icm));
    }
    if (maxAbs < 0.1) maxAbs = 0.1;
    final interval = (maxAbs / 5).ceilToDouble();
    final step = (_evs.length / 6).ceil();
    return Container(
      height: responsiveSize(context, 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedLineChart(
        data: LineChartData(
          minY: -maxAbs,
          maxY: maxAbs,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) =>
                const FlLine(color: Colors.white24, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
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
                  if (i < 0 || i >= _evs.length) return const SizedBox.shrink();
                  if (i % step != 0 && i != _evs.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '${i + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  );
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
            LineChartBarData(
              spots: spotsEv,
              color: AppColors.evPre,
              barWidth: 2,
              isCurved: false,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: spotsIcm,
              color: AppColors.icmPre,
              barWidth: 2,
              isCurved: false,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    try {
      final list = [...widget.hands]
        ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
      if (!mounted) return;
      await PackExportService.exportSessionCsv(list, _evs, _icms);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CSV exported')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _exportPdf() async {
    try {
      final list = [...widget.hands]
        ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
      if (!mounted) return;
      await PackExportService.exportSessionPdf(list, _evs, _icms);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF exported')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Widget _buildNoteField() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.padding16,
        vertical: 8,
      ),
      child: Card(
        color: AppColors.cardBackground,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _noteController,
            minLines: 3,
            maxLines: null,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Заметка о сессии',
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = [...widget.hands]
      ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
    int correct = 0;
    int mistakes = 0;
    for (final h in list) {
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (exp != null && gto != null) {
        if (exp == gto) {
          correct++;
        } else {
          mistakes++;
        }
      }
    }
    final accuracy =
        correct + mistakes > 0 ? correct * 100 / (correct + mistakes) : 0.0;
    final preEv = _evs.isNotEmpty ? _evs.first : 0.0;
    final postEv = _evs.isNotEmpty ? _evs.last : 0.0;
    final preIcm = _icms.isNotEmpty ? _icms.first : 0.0;
    final postIcm = _icms.isNotEmpty ? _icms.last : 0.0;
    return Scaffold(
      appBar: AppBar(title: const Text('Session Analysis')),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hands: ${list.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Accuracy: ${accuracy.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mistakes: $mistakes',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'EV: ${preEv.toStringAsFixed(2)} ➜ ${postEv.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ICM: ${preIcm.toStringAsFixed(2)} ➜ ${postIcm.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildChart(),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () async {
                      final tpl = await MistakeReviewPackService.latestTemplate(
                        context,
                      );
                      if (tpl == null) return;
                      await context.read<TrainingSessionService>().startSession(
                            tpl,
                            persist: false,
                          );
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TrainingSessionScreen(),
                        ),
                      );
                    },
                    child: const Text('Review Mistakes'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _exportPdf,
                        child: const Text('Экспорт PDF'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _exportCsv,
                        child: const Text('Экспорт CSV'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildNoteField(),
                const SizedBox(height: 16),
                for (var i = 0; i < list.length; i++) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(
                        list[i].name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'EV: ${_evs[i].toStringAsFixed(2)} • ICM: ${_icms[i].toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SessionReplayScreen(
                              hands: list,
                              initialIndex: i,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () async {
                      final tpl = await MistakeReviewPackService.latestTemplate(
                        context,
                      );
                      if (tpl == null) return;
                      await context.read<TrainingSessionService>().startSession(
                            tpl,
                            persist: false,
                          );
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TrainingSessionScreen(),
                        ),
                      );
                    },
                    child: const Text('Train Mistakes'),
                  ),
                ),
              ],
            ),
    );
  }
}
