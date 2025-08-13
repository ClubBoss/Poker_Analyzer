import 'package:flutter/material.dart';
import '../../models/v2/training_pack_template.dart';
import '../../models/v2/training_pack_variant.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../services/training_pack_play_service.dart';
import '../../services/dynamic_pack_adjustment_service.dart';
import 'training_pack_play_screen.dart';
import 'training_pack_play_screen_v2.dart';
import '../../services/app_settings_service.dart';
import 'package:provider/provider.dart';

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
  bool _canceled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _canceled = true;
    super.dispose();
  }

  Future<void> _load() async {
    final service = TrainingPackPlayService();
    final adjust = context.read<DynamicPackAdjustmentService>();
    final tpl = await adjust.adjust(widget.template);
    final List<TrainingPackSpot> spots = await service.loadSpots(
      tpl,
      widget.variant,
      forceReload: widget.forceReload,
    );
    if (_canceled || !mounted) return;
    final rootCtx = context;
    if (spots.isEmpty) {
      Navigator.pop(rootCtx);
      ScaffoldMessenger.of(rootCtx).showSnackBar(
        const SnackBar(content: Text('Не удалось сгенерировать споты')),
      );
      return;
    }
    final playTpl = tpl.copyWith(spots: spots);
    ScaffoldMessenger.of(rootCtx).showSnackBar(
      SnackBar(
        content: Text(
            'Stack ${tpl.heroBbStack}bb • Range ${tpl.heroRange?.length ?? 0}'),
      ),
    );
    Navigator.pushReplacement(
      rootCtx,
      MaterialPageRoute(
        builder: (_) => (AppSettingsService.instance.useNewTrainerUi
            ? TrainingPackPlayScreenV2(
                template: playTpl,
                original: widget.template,
                variant: widget.variant,
                spots: spots,
              )
            : TrainingPackPlayScreen(
                template: playTpl,
                original: widget.template,
                variant: widget.variant,
                spots: spots,
              )),
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
