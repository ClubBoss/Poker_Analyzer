import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/daily_hand_service.dart';
import '../widgets/saved_hand_tile.dart';
import '../widgets/saved_hand_detail_sheet.dart';
import '../helpers/date_utils.dart';
import '../widgets/sync_status_widget.dart';

class DailyHandScreen extends StatelessWidget {
  const DailyHandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DailyHandService>();
    final hand = service.hand;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ежедневная раздача'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context), 
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PastDailyHandsScreen()),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: hand == null
            ? const Text(
                'Нет активной раздачи на сегодня',
                style: TextStyle(color: Colors.white70),
              )
            : SavedHandTile(
                hand: hand,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.grey[900],
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (_) => SavedHandDetailSheet(
                      hand: hand,
                      onDelete: () {},
                      onExportJson: () async {},
                      onExportCsv: () async {},
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class PastDailyHandsScreen extends StatelessWidget {
  const PastDailyHandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DailyHandService>();
    final history = service.history.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('История ежедневных раздач'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      backgroundColor: const Color(0xFF121212),
      body: history.isEmpty
          ? const Center(
              child: Text(
                'История пуста',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                return ListTile(
                  title: Text(
                    formatDate(entry.date, context: context),
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: Icon(
                    entry.correct ? Icons.check_circle : Icons.cancel,
                    color: entry.correct ? Colors.green : Colors.red,
                  ),
                );
              },
            ),
    );
  }
}
