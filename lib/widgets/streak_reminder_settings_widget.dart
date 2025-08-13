import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/streak_reminder_scheduler_service.dart';

class StreakReminderSettingsWidget extends StatefulWidget {
  const StreakReminderSettingsWidget({super.key});

  @override
  State<StreakReminderSettingsWidget> createState() =>
      _StreakReminderSettingsWidgetState();
}

class _StreakReminderSettingsWidgetState
    extends State<StreakReminderSettingsWidget> {
  static const _hourKey = 'streak_reminder_hour';
  static const _muteKey = 'streak_reminder_muted';

  bool _enabled = true;
  int _hour = 20;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_hourKey) ?? 20;
    final muted = prefs.getBool(_muteKey) ?? false;
    if (mounted) {
      setState(() {
        _hour = hour;
        _enabled = !muted;
        _loaded = true;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    final service = context.read<StreakReminderSchedulerService>();
    await service.setMuted(!value);
  }

  Future<void> _pickHour() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: 0),
    );
    if (picked != null) {
      if (picked.hour < 6 || picked.hour > 22) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select an hour between 6 and 22.')),
        );
        return;
      }
      setState(() => _hour = picked.hour);
      final service = context.read<StreakReminderSchedulerService>();
      await service.setHour(picked.hour);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    final timeText = '${_hour.toString().padLeft(2, '0')}:00';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          value: _enabled,
          onChanged: _toggle,
          title: const Text('Streak Reminder'),
          activeColor: Colors.orange,
        ),
        ListTile(
          title: const Text('Reminder Hour',
              style: TextStyle(color: Colors.white)),
          subtitle:
              Text(timeText, style: const TextStyle(color: Colors.white70)),
          enabled: _enabled,
          onTap: _enabled ? _pickHour : null,
        ),
      ],
    );
  }
}
