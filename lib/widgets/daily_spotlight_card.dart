import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/daily_spotlight_service.dart';
import '../screens/v2/training_pack_play_screen.dart';

class DailySpotlightCard extends StatefulWidget {
  const DailySpotlightCard({super.key});

  @override
  State<DailySpotlightCard> createState() => _DailySpotlightCardState();
}

class _DailySpotlightCardState extends State<DailySpotlightCard> {
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    PreferencesService.getInstance().then((p) {
      if (!mounted) return;
      setState(() => _hidden = p.getBool('hide_today_card') ?? false);
    });
  }

  Future<void> _hide() async {
    final prefs = PreferencesService.instance;
    await prefs.setBool('hide_today_card', true);
    if (mounted) setState(() => _hidden = true);
  }

  @override
  Widget build(BuildContext context) {
    final tpl = context.watch<DailySpotlightService>().template;
    if (_hidden || tpl == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.4), accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '🎯 Сегодняшний Пак',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(onPressed: _hide, child: const Text('Скрыть')),
            ],
          ),
          const SizedBox(height: 4),
          Text(tpl.name, style: const TextStyle(color: Colors.white)),
          if (tpl.description.isNotEmpty)
            Text(
              tpl.description,
              style: const TextStyle(color: Colors.white70),
            ),
          const SizedBox(height: 4),
          Text(
            '${tpl.spots.length} спотов',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TrainingPackPlayScreen(template: tpl, original: tpl),
                  ),
                );
              },
              child: const Text('Начать'),
            ),
          ),
        ],
      ),
    );
  }
}
