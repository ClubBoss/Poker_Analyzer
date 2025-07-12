import 'package:flutter/material.dart';
import '../services/offline_evaluator_service.dart';
import '../services/evaluation_settings_service.dart';

class EvaluationSettingsScreen extends StatefulWidget {
  const EvaluationSettingsScreen({super.key});

  @override
  State<EvaluationSettingsScreen> createState() => _EvaluationSettingsScreenState();
}

class _EvaluationSettingsScreenState extends State<EvaluationSettingsScreen> {
  late bool _offline;
  late TextEditingController _endpoint;
  late TextEditingController _payouts;

  @override
  void initState() {
    super.initState();
    final s = EvaluationSettingsService.instance;
    _offline = s.offline;
    _endpoint = TextEditingController(text: s.remoteEndpoint);
    _payouts = TextEditingController(text: s.payouts.join(','));
  }

  Future<void> _setOffline(bool v) async {
    setState(() => _offline = v);
    await EvaluationSettingsService.instance.update(offline: v);
    OfflineEvaluatorService.isOffline = v;
  }

  Future<void> _setEndpoint(String v) async {
    await EvaluationSettingsService.instance.update(endpoint: v);
  }

  Future<void> _setPayouts(String v) async {
    final p = v
        .split(',')
        .map((e) => double.tryParse(e.trim()))
        .whereType<double>()
        .toList();
    if (p.isNotEmpty) {
      await EvaluationSettingsService.instance.update(payouts: p);
    }
  }

  @override
  void dispose() {
    _endpoint.dispose();
    _payouts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Evaluation Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: _offline,
            title: const Text('Offline Mode'),
            activeColor: Colors.orange,
            onChanged: _setOffline,
          ),
          TextField(
            controller: _endpoint,
            decoration: const InputDecoration(labelText: 'EV API Endpoint'),
            onChanged: _setEndpoint,
          ),
          TextField(
            controller: _payouts,
            decoration:
                const InputDecoration(labelText: 'ICM Payouts (comma)'),
            onChanged: _setPayouts,
          ),
        ],
      ),
    );
  }
}
