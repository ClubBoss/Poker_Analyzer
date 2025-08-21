import 'package:flutter/material.dart';
import '../services/evaluation_settings_service.dart';

class EvaluationSettingsScreen extends StatefulWidget {
  const EvaluationSettingsScreen({super.key});

  @override
  State<EvaluationSettingsScreen> createState() =>
      _EvaluationSettingsScreenState();
}

class _EvaluationSettingsScreenState extends State<EvaluationSettingsScreen> {
  late TextEditingController _threshold;
  late TextEditingController _endpoint;
  bool _useIcm = false;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    final s = EvaluationSettingsService.instance;
    _threshold = TextEditingController(text: s.evThreshold.toString());
    _endpoint = TextEditingController(text: s.remoteEndpoint);
    _useIcm = s.useIcm;
    _offline = s.offline;
  }

  Future<void> _save() async {
    final threshold =
        double.tryParse(_threshold.text) ??
        EvaluationSettingsService.instance.evThreshold;
    await EvaluationSettingsService.instance.update(
      threshold: threshold,
      icm: _useIcm,
      endpoint: _endpoint.text,
      offline: _offline,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _threshold.dispose();
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _threshold,
              decoration: const InputDecoration(labelText: 'EV Threshold'),
              keyboardType: TextInputType.number,
            ),
            SwitchListTile(
              value: _useIcm,
              title: const Text('Use ICM'),
              activeThumbColor: Colors.orange,
              onChanged: (v) => setState(() => _useIcm = v),
            ),
            SwitchListTile(
              value: _offline,
              title: const Text('Offline Mode'),
              activeThumbColor: Colors.orange,
              onChanged: (v) => setState(() => _offline = v),
            ),
            TextField(
              controller: _endpoint,
              decoration: const InputDecoration(labelText: 'API Endpoint'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
