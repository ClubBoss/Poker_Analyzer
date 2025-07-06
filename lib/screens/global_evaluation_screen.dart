import 'package:flutter/material.dart';

import '../helpers/training_pack_storage.dart';
import '../services/bulk_evaluator_service.dart';
import '../utils/template_coverage_utils.dart';

class GlobalEvaluationScreen extends StatefulWidget {
  const GlobalEvaluationScreen({super.key});

  @override
  State<GlobalEvaluationScreen> createState() => _GlobalEvaluationScreenState();
}

class _GlobalEvaluationScreenState extends State<GlobalEvaluationScreen> {
  double _progress = 0;
  bool _running = false;

  Future<void> _run() async {
    if (_running) return;
    setState(() {
      _running = true;
      _progress = 0;
    });
    final templates = await TrainingPackStorage.load();
    final total = templates.length;
    for (var i = 0; i < templates.length; i++) {
      final t = templates[i];
      await BulkEvaluatorService().generateMissingForTemplate(
        t,
        onProgress: (p) {
          setState(() => _progress = (i + p) / total);
        },
      );
      TemplateCoverageUtils.recountAll(t);
      await TrainingPackStorage.save(templates);
    }
    if (mounted) {
      setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Global Evaluation'),
        centerTitle: true,
      ),
      body: Center(
        child: _running
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(value: _progress),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(_progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: _run,
                child: const Text('Recalculate EV/ICM for All Templates'),
              ),
      ),
    );
  }
}
