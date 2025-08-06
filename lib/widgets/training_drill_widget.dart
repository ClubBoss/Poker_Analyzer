import 'package:flutter/material.dart';
import '../services/lazy_pack_loader_service.dart';
import '../models/v2/training_pack_spot.dart';

/// Widget that consumes a [SpotStreamingEngine] to provide a smooth training
/// experience for packs with a large number of spots.
class TrainingDrillWidget extends StatefulWidget {
  const TrainingDrillWidget({super.key, required this.engine});

  final SpotStreamingEngine engine;

  @override
  State<TrainingDrillWidget> createState() => _TrainingDrillWidgetState();
}

class _TrainingDrillWidgetState extends State<TrainingDrillWidget> {
  TrainingPackSpot? _current;

  @override
  void initState() {
    super.initState();
    widget.engine.initialize().then((_) {
      setState(() {
        _current = widget.engine.next();
      });
    });
  }

  void _advance() {
    final next = widget.engine.next();
    if (next != null) {
      setState(() => _current = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_current == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Expanded(child: Text('Spot: ${_current!.id}')),
        ElevatedButton(onPressed: _advance, child: const Text('Next')),
      ],
    );
  }
}
