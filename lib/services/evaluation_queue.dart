import 'dart:async';
import 'dart:collection';

import '../models/eval_request.dart';
import '../models/eval_result.dart';

/// Serial queue for processing [EvalRequest]s one at a time.
class EvaluationQueue {
  EvaluationQueue(this._processor);

  final Future<EvalResult> Function(EvalRequest) _processor;
  final Queue<_QueueItem> _queue = Queue();
  bool _processing = false;

  /// Enqueues [request] for processing and returns its eventual [EvalResult].
  Future<EvalResult> enqueue(EvalRequest request) {
    final completer = Completer<EvalResult>();
    _queue.add(_QueueItem(request, completer));
    _process();
    return completer.future;
  }

  void _process() {
    if (_processing || _queue.isEmpty) return;
    _processing = true;
    final item = _queue.removeFirst();
    _processor(item.request).then(item.completer.complete).catchError((e, s) {
      item.completer.completeError(e, s);
    }).whenComplete(() {
      _processing = false;
      _process();
    });
  }
}

class _QueueItem {
  final EvalRequest request;
  final Completer<EvalResult> completer;
  _QueueItem(this.request, this.completer);
}
