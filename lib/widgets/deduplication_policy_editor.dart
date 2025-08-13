import 'package:flutter/material.dart';

import '../services/deduplication_policy_engine.dart';

class DeduplicationPolicyEditor extends StatefulWidget {
  const DeduplicationPolicyEditor({super.key});

  @override
  State<DeduplicationPolicyEditor> createState() =>
      _DeduplicationPolicyEditorState();
}

class _DeduplicationPolicyEditorState extends State<DeduplicationPolicyEditor> {
  final _engine = DeduplicationPolicyEngine();
  List<DeduplicationPolicy> _policies = const [];
  String _reason = 'duplicate';
  DeduplicationAction _action = DeduplicationAction.block;
  final TextEditingController _thresholdCtrl =
      TextEditingController(text: '1.0');

  @override
  void initState() {
    super.initState();
    _engine.loadPolicies().then((_) {
      setState(() => _policies = _engine.policies);
    });
  }

  @override
  void dispose() {
    _thresholdCtrl.dispose();
    super.dispose();
  }

  void _addPolicy() {
    final th = double.tryParse(_thresholdCtrl.text) ?? 1.0;
    final p = DeduplicationPolicy(
      reason: _reason,
      action: _action,
      threshold: th,
    );
    setState(() => _policies = [..._policies, p]);
    _engine.setPolicies(_policies);
  }

  void _removePolicy(int index) {
    setState(() => _policies = [..._policies]..removeAt(index));
    _engine.setPolicies(_policies);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deduplication Policies')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _policies.length,
                itemBuilder: (context, index) {
                  final p = _policies[index];
                  return ListTile(
                    title: Text('${p.reason} >= ${p.threshold}'),
                    subtitle: Text(p.action.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removePolicy(index),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _reason,
                    items: const [
                      DropdownMenuItem(
                        value: 'duplicate',
                        child: Text('duplicate'),
                      ),
                      DropdownMenuItem(
                        value: 'high_similarity',
                        child: Text('high_similarity'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _reason = v ?? 'duplicate'),
                  ),
                ),
                Expanded(
                  child: DropdownButton<DeduplicationAction>(
                    value: _action,
                    items: [
                      for (final a in DeduplicationAction.values)
                        DropdownMenuItem(
                          value: a,
                          child: Text(a.name),
                        ),
                    ],
                    onChanged: (v) => setState(
                        () => _action = v ?? DeduplicationAction.block),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _thresholdCtrl,
                    decoration: const InputDecoration(labelText: 'Threshold'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                ElevatedButton(
                  onPressed: _addPolicy,
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
