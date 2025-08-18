import 'package:flutter/material.dart';

import '../services/smart_inbox_debug_service.dart';
import '../services/smart_pinned_block_booster_provider.dart';

/// Debug banner displaying Smart Inbox pipeline stages and retained boosters.
class SmartInboxDebugBannerWidget extends StatefulWidget {
  const SmartInboxDebugBannerWidget({super.key});

  @override
  State<SmartInboxDebugBannerWidget> createState() =>
      _SmartInboxDebugBannerWidgetState();
}

class _SmartInboxDebugBannerWidgetState
    extends State<SmartInboxDebugBannerWidget> {
  final _service = SmartInboxDebugService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Widget _stageTile(String label, List<PinnedBlockBoosterSuggestion> list) {
    return ExpansionTile(
      title: Text('$label (${list.length})'),
      children: [
        for (final b in list)
          ListTile(dense: true, title: Text(b.tag), subtitle: Text(b.action)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_service.enabled || _service.info == null) {
      return const SizedBox.shrink();
    }
    final info = _service.info!;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: const Text('Smart Inbox Debug'),
        children: [
          _stageTile('raw', info.raw),
          _stageTile('scheduled', info.scheduled),
          _stageTile('deduplicated', info.deduplicated),
          _stageTile('sorted', info.sorted),
          _stageTile('limited', info.limited),
          _stageTile('rendered', info.rendered),
        ],
      ),
    );
  }
}
