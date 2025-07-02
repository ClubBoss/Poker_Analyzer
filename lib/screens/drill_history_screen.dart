import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/drill_history_service.dart';
import '../theme/app_colors.dart';
import '../helpers/date_utils.dart';

class DrillHistoryScreen extends StatefulWidget {
  const DrillHistoryScreen({super.key});

  @override
  State<DrillHistoryScreen> createState() => _DrillHistoryScreenState();
}

class _DrillHistoryScreenState extends State<DrillHistoryScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final results = context.watch<DrillHistoryService>().results;
    final query = _search.text.toLowerCase();
    final filtered = query.isEmpty
        ? results
        : [
            for (final r in results)
              if (r.templateName.toLowerCase().contains(query)) r
          ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('История тренировок'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(hintText: 'Поиск'),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ),
      body: results.isEmpty
          ? const Center(
              child: Text(
                'История пока пуста',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : filtered.isEmpty
              ? const Center(
                  child: Text(
                    'Нет результатов',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final r = filtered[index];
                final pct = r.total == 0 ? 0 : (r.correct / r.total * 100).round();
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
                    leading: const Icon(Icons.history, color: Colors.white),
                    title: Text(r.templateName,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      '${formatDate(r.date)} •  ${r.correct}/${r.total}  ($pct%)',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Text(
                      r.evLoss.toStringAsFixed(2),
                      style: TextStyle(
                          color: r.evLoss > 0 ? Colors.red : Colors.green),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(r.templateName),
                          content: Text(
                            '${formatDate(r.date)}\n'
                            'Верно: ${r.correct}/${r.total} ($pct%)\n'
                            'Потеря EV: ${r.evLoss.toStringAsFixed(2)} bb',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
