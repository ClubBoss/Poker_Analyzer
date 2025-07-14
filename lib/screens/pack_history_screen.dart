import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/training_session_service.dart';
import '../services/training_pack_template_service.dart';
import '../models/v2/training_pack_template.dart';
import 'training_session_screen.dart';
import '../widgets/training_pack_card.dart';

class PackHistoryScreen extends StatefulWidget {
  const PackHistoryScreen({super.key});

  @override
  State<PackHistoryScreen> createState() => _PackHistoryScreenState();
}

class _PackHistoryScreenState extends State<PackHistoryScreen> {
  final List<TrainingPackTemplate> _templates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final templates = TrainingPackTemplateService.getAllTemplates(context);
    final prefs = await SharedPreferences.getInstance();
    final list = [
      for (final t in templates)
        if (prefs.getBool('completed_tpl_${t.id}') ?? false) t
    ];
    if (!mounted) return;
    setState(() {
      _templates
        ..clear()
        ..addAll(list);
      _loading = false;
    });
  }

  Future<void> _start(TrainingPackTemplate tpl) async {
    await context.read<TrainingSessionService>().startSession(tpl);
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('История паков')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? const Center(
                  child: Text('История пуста',
                      style: TextStyle(color: Colors.white70)),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final t in _templates)
                        TrainingPackCard(template: t, onTap: () => _start(t)),
                    ],
                  ),
                ),
    );
  }
}
