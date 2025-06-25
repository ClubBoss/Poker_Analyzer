import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';

import '../helpers/date_utils.dart';
import '../services/reminder_service.dart';
import '../services/user_action_logger.dart';
import '../services/cloud_backup_service.dart';

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

  Future<void> _syncNow(BuildContext context) async {
    final service = context.read<CloudBackupService>();
    try {
      await service.syncNow();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Sync complete')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Sync failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminder = context.watch<ReminderService>();
    final dismissed = reminder.lastDismissed;
    final status = reminder.enabled ? 'Включены' : 'Выключены';
    final info = dismissed != null
        ? '$status, последний отказ: ${formatDateTime(dismissed)}'
        : status;
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Ещё'),
        centerTitle: true,
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
          const SizedBox(height: 8),
          Center(
            child: ElevatedButton(
              onPressed: () => _syncNow(context),
              child: const Text('Sync now'),
            ),
          ),
        ],
      ),
    );
  }
}
