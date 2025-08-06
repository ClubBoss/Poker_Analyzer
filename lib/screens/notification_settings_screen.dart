import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../widgets/streak_reminder_settings_widget.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    NotificationService.getReminderTime(context)
        .then((t) => setState(() => _time = t));
  }

  Future<void> _pick() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      await NotificationService.updateReminderTime(context, picked);
      if (mounted) setState(() => _time = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeText = _time.format(context);
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Notification Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Reminder Time', style: TextStyle(color: Colors.white)),
            subtitle: Text(timeText, style: const TextStyle(color: Colors.white70)),
            onTap: _pick,
          ),
          const StreakReminderSettingsWidget(),
        ],
      ),
    );
  }
}
