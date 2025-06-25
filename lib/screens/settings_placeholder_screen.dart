import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/date_utils.dart';
import '../services/reminder_service.dart';

class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({super.key});

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
        ],
      ),
    );
  }
}
