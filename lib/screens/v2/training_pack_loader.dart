import 'package:flutter/material.dart';
import '../../models/v2/training_pack_template.dart';
import '../../models/v2/training_pack_variant.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../services/training_pack_play_service.dart';
import 'training_pack_play_screen.dart';

class TrainingPackLoader extends StatefulWidget {
  final TrainingPackTemplate template;
  final TrainingPackVariant variant;
  final bool forceReload;
  const TrainingPackLoader({
    super.key,
    required this.template,
    required this.variant,
    this.forceReload = false,
  });
  @override
  State<TrainingPackLoader> createState() => _TrainingPackLoaderState();
}

class _TrainingPackLoaderState extends State<TrainingPackLoader> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = TrainingPackPlayService();
    final List<TrainingPackSpot> spots = await service.loadSpots(
      widget.template,
      widget.variant,
      forceReload: widget.forceReload,
    );
    if (!mounted) return;
    if (spots.isEmpty) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сгенерировать споты')),
      );
      return;
    }
    widget.template.spots = spots;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackPlayScreen(
          template: widget.template,
          original: widget.template,
          variant: widget.variant,
          spots: spots,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
