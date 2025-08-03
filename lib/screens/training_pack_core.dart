import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/training_pack_controller.dart';
import '../models/result_entry.dart';
import '../models/saved_hand.dart';
import '../models/training_pack.dart';
import '../services/cloud_sync_service.dart';
import '../services/training_spot_storage_service.dart';

import 'training_pack_overlay.dart';
import 'training_pack_spot_panel.dart';
import 'training_pack_stats_panel.dart';

class TrainingPackCore extends StatefulWidget {
  final TrainingPack pack;
  final List<SavedHand>? hands;
  final bool mistakeReviewMode;
  final ValueChanged<bool>? onComplete;
  final bool persistResults;
  final int? initialPosition;

  const TrainingPackCore({
    super.key,
    required this.pack,
    this.hands,
    this.mistakeReviewMode = false,
    this.onComplete,
    this.persistResults = true,
    this.initialPosition,
  });

  @override
  State<TrainingPackCore> createState() => TrainingPackCoreState();
}

class TrainingPackCoreState extends State<TrainingPackCore> {
  late final TrainingPackController _controller;
  final List<ResultEntry> _results = [];

  @override
  void initState() {
    super.initState();
    final storage = TrainingSpotStorageService(
      cloud: context.read<CloudSyncService>(),
    );
    _controller = TrainingPackController(
      pack: widget.pack,
      allHands: widget.hands ?? widget.pack.hands,
      storage: storage,
    )..loadSpots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: TrainingPackSpotPanel(controller: _controller),
          ),
          Expanded(
            flex: 2,
            child: TrainingPackStatsPanel(results: _results),
          ),
        ],
      ),
      floatingActionButton: TrainingPackOverlay(pack: widget.pack),
    );
  }
}

