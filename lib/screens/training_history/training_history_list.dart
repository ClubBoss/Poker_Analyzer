import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/common/history_list_item.dart';
import '../training_detail_screen.dart';
import 'training_history_view_model.dart';

class TrainingHistoryList extends StatelessWidget {
  const TrainingHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrainingHistoryViewModel>();
    final sessions = vm.getFilteredHistory();
    return Expanded(
      child: ListView.builder(
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final result = sessions[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: HistoryListItem(
              result: result,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TrainingDetailScreen(
                      result: result,
                      onDelete: () async {},
                      onEditTags: (_) async {},
                      onEditAccuracy: (_) async {},
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
