import 'package:flutter/material.dart';

import '../services/smart_inbox_debug_service.dart';
import '../services/smart_pinned_block_booster_provider.dart';

class SmartInboxDebugBannerWidget extends StatelessWidget {
  const SmartInboxDebugBannerWidget({super.key, required this.info});

  final SmartInboxDebugInfo info;

  Widget _buildStage(String name, List<PinnedBlockBoosterSuggestion> list) {
    return ExpansionTile(
      title: Text('$name (${list.length})'),
      children: [
        for (final b in list)
          ListTile(
            dense: true,
            title: Text('${b.tag} - ${b.action}'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Smart Inbox Debug',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          _buildStage('raw', info.raw),
          _buildStage('scheduled', info.scheduled),
          _buildStage('deduplicated', info.deduplicated),
          _buildStage('sorted', info.sorted),
          _buildStage('limited', info.limited),
          _buildStage('rendered', info.rendered),
        ],
      ),
    );
  }
}
