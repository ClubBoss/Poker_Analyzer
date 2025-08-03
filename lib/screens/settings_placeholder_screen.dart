import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../helpers/date_utils.dart';
import '../services/reminder_service.dart';
import '../services/daily_reminder_service.dart';
import '../services/streak_reminder_service.dart';
import '../services/user_action_logger.dart';
import '../services/daily_target_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/saved_hand_export_service.dart';
import '../services/session_note_service.dart';
import '../widgets/sync_status_widget.dart';
import 'notification_settings_screen.dart';
import 'goal_overview_screen.dart';
import 'weakness_overview_screen.dart';
import '../utils/snackbar_util.dart';

class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({super.key});

  Future<void> _exportLog(BuildContext context) async {
    final events = context.read<UserActionLogger>().export();
    if (events.isEmpty) return;
    final rows = <List<dynamic>>[
      ['Time', 'Event'],
      for (final e in events)
        [
          DateFormat('yyyy-MM-dd HH:mm:ss')
              .format(DateTime.parse(e['time'] as String)),
          e['event']
        ]
    ];
    final csv = const ListToCsvConverter(fieldDelimiter: ';')
        .convert(rows, eol: '\r\n');
    final bytes = Uint8List.fromList(utf8.encode(csv));
    final name =
        'user_log_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}';
    try {
      await FileSaver.instance.saveAs(
        name: name,
        bytes: bytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );
      if (!context.mounted) return;
      SnackbarUtil.showMessage(context, 'Файл сохранён: $name.csv');
    } catch (_) {
      if (!context.mounted) return;
      SnackbarUtil.showMessage(context, 'Ошибка экспорта CSV');
    }
  }

  Future<void> _exportHands(BuildContext context) async {
    final exporter = context.read<SavedHandExportService>();
    final path = await exporter.exportSessionsArchive();
    if (path == null) return;
    await Share.shareXFiles([XFile(path)], text: 'saved_hands_archive.zip');
    if (!context.mounted) return;
    final name = path.split(Platform.pathSeparator).last;
    SnackbarUtil.showMessage(context, 'Файл сохранён: $name');
  }

  Future<void> _exportSummary(BuildContext context) async {
    final manager = context.read<SavedHandManagerService>();
    final notes = context.read<SessionNoteService>().notes;
    final path = await manager.exportAllSessionsPdf(notes);
    if (path == null || !context.mounted) return;
    final name = path.split(Platform.pathSeparator).last;
    SnackbarUtil.showMessage(context, 'Файл сохранён: $name');
  }

  Future<void> _exportSummaryCsv(BuildContext context) async {
    final manager = context.read<SavedHandManagerService>();
    final notes = context.read<SessionNoteService>().notes;
    final path = await manager.exportAllSessionsCsv(notes);
    if (path == null) return;
    await Share.shareXFiles([XFile(path)], text: 'training_summary.csv');
    if (!context.mounted) return;
    final name = path.split(Platform.pathSeparator).last;
    SnackbarUtil.showMessage(context, 'Файл сохранён: $name');
  }

  @override
  Widget build(BuildContext context) {
    final reminder = context.watch<ReminderService>();
    final dailyReminder = context.watch<DailyReminderService>();
    final streakReminder = context.watch<StreakReminderService>();
    final dailyTarget = context.watch<DailyTargetService>();
    final dismissed = reminder.lastDismissed;
    final status = reminder.enabled ? 'Включены' : 'Выключены';
    final info = dismissed != null
        ? '$status, последний отказ: ${formatDateTime(dismissed)}'
        : status;
    final drInfo = '${dailyReminder.hour.toString().padLeft(2, '0')}:00';
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Ещё'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Notifications',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ),
          SwitchListTile(
            value: reminder.enabled,
            onChanged: (v) => reminder.setEnabled(v),
            title: const Text('Напоминания'),
            activeColor: Colors.orange,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              info,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          SwitchListTile(
            value: dailyReminder.enabled,
            onChanged: (v) => dailyReminder.setEnabled(v),
            title: const Text('Daily Reminder'),
            activeColor: Colors.orange,
          ),
          SwitchListTile(
            value: streakReminder.enabled,
            onChanged: (v) => streakReminder.setEnabled(v),
            title: const Text('Streak Reminder'),
            activeColor: Colors.orange,
          ),
          ListTile(
            title: const Text('Time', style: TextStyle(color: Colors.white)),
            subtitle: Text(drInfo, style: const TextStyle(color: Colors.white70)),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: dailyReminder.hour, minute: 0),
              );
              if (picked != null) {
                dailyReminder.setHour(picked.hour);
              }
            },
          ),
          ListTile(
            title: const Text('Push Reminder', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Daily hands target',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ),
          Slider(
            value: dailyTarget.target.toDouble(),
            min: 5,
            max: 50,
            divisions: 45,
            label: dailyTarget.target.toString(),
            activeColor: Colors.orange,
            onChanged: (v) => dailyTarget.setTarget(v.round()),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Data Export',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ),
          ListTile(
            title: const Text('Goal Overview',
                style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GoalOverviewScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.insights, color: Colors.white),
            trailing: const Icon(Icons.chevron_right),
            title: const Text('Анализ слабых мест'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const WeaknessOverviewScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: () => _exportHands(context),
              child: const Text('Export Hands Archive'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: () => _exportSummary(context),
              child: const Text('Export Training Summary'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: () => _exportSummaryCsv(context),
              child: const Text('Export Summary CSV'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: () => _exportLog(context),
              child: const Text('Export Activity Log'),
            ),
          ),
        ],
      ),
    );
  }
}
