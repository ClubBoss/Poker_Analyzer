import 'package:flutter/material.dart';

import '../models/eval_request.dart';
import '../models/eval_result.dart';
import '../models/training_spot.dart';
import '../services/evaluation_executor_service.dart';

class EvalResultView extends StatefulWidget {
  final TrainingSpot spot;
  final String action;

  const EvalResultView({super.key, required this.spot, required this.action});

  @override
  State<EvalResultView> createState() => _EvalResultViewState();
}

class _EvalResultViewState extends State<EvalResultView> {
  late Future<EvalResult> _future;

  @override
  void initState() {
    super.initState();
    final req = EvalRequest(
      hash: widget.spot.createdAt.millisecondsSinceEpoch.toString(),
      spot: widget.spot,
      action: widget.action,
    );
    _future = EvaluationExecutorService().evaluate(req);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EvalResult>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final res = snapshot.data!;
        if (res.isError) {
          return const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 4),
                Text('Evaluation failed',
                    style: TextStyle(color: Colors.orange)),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            children: [
              Text('Score: ${res.score.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white)),
              Text('Reason: ${res.reason ?? '-'}',
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
        );
      },
    );
  }
}
