import 'package:flutter/material.dart';
import 'dart:math';

import '../helpers/training_pack_storage.dart';
import '../services/bulk_evaluator_service.dart';
import '../services/offline_evaluator_service.dart';
import '../utils/template_coverage_utils.dart';

class GlobalEvaluationScreen extends StatefulWidget {
  const GlobalEvaluationScreen({super.key});

  @override
  State<GlobalEvaluationScreen> createState() => _GlobalEvaluationScreenState();
}

class _GlobalEvaluationScreenState extends State<GlobalEvaluationScreen> {
  double _progress = 0;
  bool _running = false;
  bool _cancelRequested = false;

  Future<void> _run() async {
    if (_running) return;
    final messenger = ScaffoldMessenger.of(context);
    final templates = await TrainingPackStorage.load();
    if (OfflineEvaluatorService.isOffline || templates.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Глобальный пересчёт недоступен оффлайн')),
      );
      return;
    }
    setState(() {
      _running = true;
      _progress = 0;
      _cancelRequested = false;
    });
    const batchSize = 4;
    final total = templates.length;
    for (var i = 0; i < total && !_cancelRequested; i += batchSize) {
      final batch = templates.sublist(i, min(i + batchSize, total));
      final results = await Future.wait([
        for (var j = 0; j < batch.length; j++)
          BulkEvaluatorService().generateMissingForTemplate(
            batch[j],
            onProgress: (p) {
              if (!mounted || _cancelRequested) return;
              final base = (i + j) / total;
              setState(() => _progress = base + p / total);
            },
          ).catchError((e) {
            debugPrint('globalEval: $e');
            return 0;
          }),
      ]);
      if (!mounted) return;
      if (_cancelRequested) break;
      for (var j = 0; j < batch.length; j++) {
        if (results[j] > 0)
          TemplateCoverageUtils.recountAll(batch[j]).applyTo(batch[j].meta);
      }
      setState(() => _progress = (i + batch.length) / total);
    }
    if (!_cancelRequested) setState(() => _progress = 1);
    await TrainingPackStorage.save(templates);
    if (!mounted) return;
    setState(() => _running = false);
    if (!_cancelRequested) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Пересчёт EV/ICM завершён 🎉')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Глобальный пересчёт EV/ICM'),
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
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() {
                      _cancelRequested = true;
                      _running = false;
                    }),
                    child: const Text('Отмена'),
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: _run,
                child: const Text('Пересчитать EV/ICM для всех шаблонов'),
              ),
      ),
    );
  }
}
