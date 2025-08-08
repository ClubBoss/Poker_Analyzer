import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/autogen_status_dashboard_service.dart';
import '../services/theory_injection_scheduler_service.dart';
import '../models/autogen_status.dart';
import '../providers/provider_globals.dart';

/// Dashboard panel displaying TheoryInjectionScheduler stats.
class TheoryInjectionDashboardPanel extends StatelessWidget {
  const TheoryInjectionDashboardPanel({super.key});

  Future<DateTime?> _loadLastRun() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = auth.uid;
    if (uid != null) {
      final raw = prefs.getString('theoryScheduler.lastRun.' + uid);
      if (raw != null) return DateTime.tryParse(raw);
    }
    DateTime? latest;
    for (final k in prefs.getKeys()) {
      if (!k.startsWith('theoryScheduler.lastRun.')) continue;
      final raw = prefs.getString(k);
      final dt = raw != null ? DateTime.tryParse(raw) : null;
      if (dt != null && (latest == null || dt.isAfter(latest))) {
        latest = dt;
      }
    }
    return latest;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = AutogenStatusDashboardService.instance.getStatusNotifier(
      'TheoryInjectionScheduler',
    );
    final policyNotifier = AutogenStatusDashboardService.instance.getStatusNotifier(
      'TheoryLinkPolicy',
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder<AutogenStatus>(
          valueListenable: notifier,
          builder: (context, status, _) {
            int runs = 0;
            int skipped = 0;
            try {
              final data =
                  jsonDecode(status.currentStage) as Map<String, dynamic>;
              runs = data['runs'] as int? ?? 0;
              skipped = data['skipped'] as int? ?? 0;
            } catch (_) {}
            return ValueListenableBuilder<AutogenStatus>(
              valueListenable: policyNotifier,
              builder: (context, policy, __) {
                bool ablated = false;
                try {
                  final data =
                      jsonDecode(policy.currentStage) as Map<String, dynamic>;
                  ablated = data['ablation'] as bool? ?? false;
                } catch (_) {}
                return FutureBuilder<DateTime?>(
                  future: _loadLastRun(),
                  builder: (context, snap) {
                    final dt = snap.data;
                    final last = dt != null
                        ? DateFormat('yyyy-MM-dd HH:mm').format(dt.toLocal())
                        : '-';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Status: '),
                            Text(
                              status.isRunning ? 'Running' : 'Idle',
                              style: TextStyle(
                                color: status.isRunning
                                    ? Colors.green
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (ablated) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'A/B: Ablated',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Last run: ' + last),
                        const SizedBox(height: 8),
                        Text(
                          'Runs: '
                              + runs.toString()
                              + '  |  Skipped: '
                              + skipped.toString(),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              TheoryInjectionSchedulerService.instance.runNow(force: true),
                          child: const Text('Run Now'),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
