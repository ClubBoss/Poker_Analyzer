import 'dart:io';

import 'package:flutter/material.dart';

import 'file_runner.dart';
import 'plan_runner.dart';

class QuickstartLauncherPage extends StatefulWidget {
  final String? initialPlan;
  final String? initialBundle;
  final String? initialManifest;
  const QuickstartLauncherPage({
    super.key,
    this.initialPlan,
    this.initialBundle,
    this.initialManifest,
  });

  @override
  State<QuickstartLauncherPage> createState() => _QuickstartLauncherPageState();
}

class _QuickstartLauncherPageState extends State<QuickstartLauncherPage> {
  late final TextEditingController _planCtrl;
  late final TextEditingController _bundleCtrl;
  late final TextEditingController _manifestCtrl;

  @override
  void initState() {
    super.initState();
    _planCtrl = TextEditingController(
      text: widget.initialPlan ?? 'out/plan/play_plan_v1.json',
    );
    _bundleCtrl = TextEditingController(
      text: widget.initialBundle ?? 'dist/training_v1',
    );
    _manifestCtrl = TextEditingController(text: widget.initialManifest ?? '');
  }

  @override
  void dispose() {
    _planCtrl.dispose();
    _bundleCtrl.dispose();
    _manifestCtrl.dispose();
    super.dispose();
  }

  void _openPlan() {
    final plan = _planCtrl.text.trim();
    final bundle = _bundleCtrl.text.trim();
    if (!File(plan).existsSync()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Plan not found')));
      return;
    }
    if (!Directory(bundle).existsSync()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bundle dir not found')));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayFromPlanPage(planPath: plan, bundleDir: bundle),
      ),
    );
  }

  void _playManifest() {
    final manifest = _manifestCtrl.text.trim();
    if (!File(manifest).existsSync()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Manifest not found')));
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PlayFromFilePage(path: manifest)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quickstart')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _planCtrl,
              decoration: const InputDecoration(
                labelText: 'Plan path',
                hintText: 'out/plan/play_plan_v1.json',
              ),
            ),
            TextField(
              controller: _bundleCtrl,
              decoration: const InputDecoration(
                labelText: 'Bundle dir',
                hintText: 'dist/training_v1',
              ),
            ),
            ElevatedButton(
              onPressed: _openPlan,
              child: const Text('Open plan slices'),
            ),
            const Divider(),
            TextField(
              controller: _manifestCtrl,
              decoration: const InputDecoration(labelText: 'Manifest path'),
            ),
            ElevatedButton(
              onPressed: _playManifest,
              child: const Text('Play manifest'),
            ),
          ],
        ),
      ),
    );
  }
}
