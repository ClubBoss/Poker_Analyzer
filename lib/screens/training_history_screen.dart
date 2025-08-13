import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../tutorial/tutorial_flow.dart';
import '../widgets/sync_status_widget.dart';
import 'training_history/training_history_charts.dart';
import 'training_history/training_history_controller.dart';
import 'training_history/training_history_filter_panel.dart';
import 'training_history/training_history_list.dart';
import 'training_history/training_history_view_model.dart';

class TrainingHistoryScreen extends StatelessWidget {
  static final GlobalKey exportCsvKey = GlobalKey();
  final TutorialFlow? tutorial;

  const TrainingHistoryScreen({super.key, this.tutorial});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = TrainingHistoryViewModel(TrainingHistoryController.instance);
        vm.load();
        return vm;
      },
      child: _TrainingHistoryView(tutorial: tutorial),
    );
  }
}

class _TrainingHistoryView extends StatelessWidget {
  final TutorialFlow? tutorial;

  const _TrainingHistoryView({this.tutorial});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tutorial?.showCurrentStep(context);
    });
    final vm = context.watch<TrainingHistoryViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training History'),
        centerTitle: true,
        actions: [
          SyncStatusIcon.of(context),
          TextButton(
            onPressed: vm.history.isEmpty ? null : vm.clear,
            child: const Text('Clear History'),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: vm.history.isEmpty
          ? const Center(
              child: Text(
                'No history available.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : const Column(
              children: [
                TrainingHistoryFilterPanel(),
                TrainingHistoryCharts(),
                TrainingHistoryList(),
              ],
            ),
    );
  }
}
