import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/hand_analysis_history_service.dart';
import '../models/hand_analysis_record.dart';
import '../theme/app_colors.dart';
import '../models/card_model.dart';
import 'quick_hand_analysis_screen.dart';

class HandAnalysisHistoryScreen extends StatefulWidget {
  const HandAnalysisHistoryScreen({super.key});

  @override
  State<HandAnalysisHistoryScreen> createState() => _HandAnalysisHistoryScreenState();
}

class _HandAnalysisHistoryScreenState extends State<HandAnalysisHistoryScreen> {
  String _period = 'Все';
  String _result = 'Все';

  List<HandAnalysisRecord> _filter(List<HandAnalysisRecord> all) {
    Duration? d;
    if (_period == '7 дней') {
      d = const Duration(days: 7);
    } else if (_period == '30 дней') {
      d = const Duration(days: 30);
    }
    final now = DateTime.now();
    return [
      for (final r in all)
        if ((d == null || r.date.isAfter(now.subtract(d))) &&
            (_result == 'Все' || r.action == _result.toLowerCase()))
          r
    ];
  }

  Widget _card(CardModel c) {
    final red = c.suit == '♥' || c.suit == '♦';
    return Container(
      width: 24,
      height: 34,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        '${c.rank}${c.suit}',
        style: TextStyle(
          color: red ? Colors.red : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _list(List<HandAnalysisRecord> data) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final r = data[index];
          final d = r.date;
          final label = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [for (final c in r.cards) _card(c)],
              ),
              title: Text(
                'EV ${r.ev.toStringAsFixed(2)} BB • ICM ${r.icm.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '${r.action} • $label',
                style: const TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => QuickHandAnalysisScreen(record: r)),
                );
              },
            ),
          );
        },
      );

  Widget _summary(List<HandAnalysisRecord> data) {
    if (data.isEmpty) return const SizedBox.shrink();
    final ev = data.map((e) => e.ev).reduce((a, b) => a + b) / data.length;
    final icm = data.map((e) => e.icm).reduce((a, b) => a + b) / data.length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$_period • $_result\nEV ${ev.toStringAsFixed(2)} BB • ICM ${icm.toStringAsFixed(2)}',
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _overallSummary(List<HandAnalysisRecord> data) {
    if (data.isEmpty) return const SizedBox.shrink();
    final ev = data.map((e) => e.ev).reduce((a, b) => a + b) / data.length;
    final icm = data.map((e) => e.icm).reduce((a, b) => a + b) / data.length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Всего EV ${ev.toStringAsFixed(2)} BB • ICM ${icm.toStringAsFixed(2)}',
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = context.watch<HandAnalysisHistoryService>().records;
    final data = _filter(records);
    return Scaffold(
      appBar: AppBar(title: const Text('История анализов'), centerTitle: true),
      backgroundColor: AppColors.background,
      body: records.isEmpty
          ? const Center(child: Text('История пуста', style: TextStyle(color: Colors.white70)))
          : Column(
              children: [
                _overallSummary(records),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final p in ['Все', '7 дней', '30 дней'])
                            ChoiceChip(
                              label: Text(p),
                              selected: _period == p,
                              onSelected: (_) => setState(() => _period = p),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final r in ['Все', 'Push', 'Fold'])
                            ChoiceChip(
                              label: Text(r),
                              selected: _result == r,
                              onSelected: (_) => setState(() => _result = r),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                _summary(data),
                Expanded(
                  child: data.isEmpty
                      ? const Center(child: Text('Нет результатов', style: TextStyle(color: Colors.white70)))
                      : _list(data),
                ),
              ],
            ),
    );
  }
}
