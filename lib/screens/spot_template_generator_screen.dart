import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/v2/hero_position.dart';
import '../services/evaluation_executor_service.dart';
import '../services/spot_template_engine.dart';
import 'training_pack_template_preview_screen.dart';

class SpotTemplateGeneratorScreen extends StatefulWidget {
  const SpotTemplateGeneratorScreen({super.key});

  @override
  State<SpotTemplateGeneratorScreen> createState() =>
      _SpotTemplateGeneratorScreenState();
}

class _SpotTemplateGeneratorScreenState
    extends State<SpotTemplateGeneratorScreen> {
  HeroPosition _hero = HeroPosition.sb;
  HeroPosition _villain = HeroPosition.bb;
  String _action = 'push';
  final TextEditingController _stackCtrl = TextEditingController(text: '10-20');
  bool _icm = false;
  bool _loading = false;

  List<int> _parseRange(String text) {
    final clean = text.replaceAll(RegExp('[^0-9-- ]'), '');
    if (clean.contains('-') || clean.contains('-')) {
      final p = clean.split(RegExp('[--]'));
      int a = int.tryParse(p.first.trim()) ?? 0;
      int b = int.tryParse(p.last.trim()) ?? a;
      if (b < a) {
        final t = a;
        a = b;
        b = t;
      }
      return [for (var i = a; i <= b; i++) i];
    }
    return [
      for (final part in clean.split(RegExp('[s,]+')))
        if (part.isNotEmpty) int.tryParse(part.trim()) ?? 0,
    ];
  }

  Future<void> _generate() async {
    final range = _parseRange(_stackCtrl.text);
    if (range.isEmpty) return;
    setState(() => _loading = true);
    final engine = SpotTemplateEngine(
      executor: context.read<EvaluationExecutorService>(),
    );
    final tpl = await engine.generate(
      heroPosition: _hero,
      villainPosition: _villain,
      stackRange: range,
      actionType: _action,
      withIcm: _icm,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackTemplatePreviewScreen(template: tpl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Template Generator')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<HeroPosition>(
              initialValue: _hero,
              decoration: const InputDecoration(labelText: 'Hero Position'),
              items: [
                for (final p in kPositionOrder)
                  DropdownMenuItem(value: p, child: Text(p.label)),
              ],
              onChanged: (v) => setState(() => _hero = v ?? _hero),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<HeroPosition>(
              initialValue: _villain,
              decoration: const InputDecoration(labelText: 'Villain Position'),
              items: [
                for (final p in kPositionOrder)
                  DropdownMenuItem(value: p, child: Text(p.label)),
              ],
              onChanged: (v) => setState(() => _villain = v ?? _villain),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _action,
              decoration: const InputDecoration(labelText: 'Action Type'),
              items: const [
                DropdownMenuItem(value: 'push', child: Text('Push')),
                DropdownMenuItem(value: 'callPush', child: Text('Call Push')),
                DropdownMenuItem(
                  value: 'minraiseFold',
                  child: Text('Minraise Fold'),
                ),
              ],
              onChanged: (v) => setState(() => _action = v ?? _action),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stackCtrl,
              decoration: const InputDecoration(labelText: 'Stack Range'),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('With ICM'),
              value: _icm,
              onChanged: (v) => setState(() => _icm = v ?? false),
            ),
            const SizedBox(height: 24),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _generate,
                    child: const Text('Generate'),
                  ),
          ],
        ),
      ),
    );
  }
}
