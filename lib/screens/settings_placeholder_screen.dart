import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';

import '../helpers/date_utils.dart';
import '../services/reminder_service.dart';
import '../services/daily_reminder_service.dart';
import '../services/user_action_logger.dart';
import '../services/daily_target_service.dart';
import '../widgets/sync_status_widget.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сохранён: $name.csv')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ошибка экспорта CSV')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminder = context.watch<ReminderService>();
    final dailyReminder = context.watch<DailyReminderService>();
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
          const SizedBox(height: 32),
          const Center(
            child: Text(
              'Настройки будут доступны позже',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 16),
          Center(
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
