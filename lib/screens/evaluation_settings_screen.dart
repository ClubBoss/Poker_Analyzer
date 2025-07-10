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

  @override
  void initState() {
    super.initState();
    final s = EvaluationSettingsService.instance;
    _offline = s.offline;
    _endpoint = TextEditingController(text: s.remoteEndpoint);
  }

  Future<void> _setOffline(bool v) async {
    setState(() => _offline = v);
    await EvaluationSettingsService.instance.update(offline: v);
    OfflineEvaluatorService.isOffline = v;
  }

  Future<void> _setEndpoint(String v) async {
    await EvaluationSettingsService.instance.update(endpoint: v);
  }

  @override
  void dispose() {
    _endpoint.dispose();
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
        ],
      ),
    );
  }
}
