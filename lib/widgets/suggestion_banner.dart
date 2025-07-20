import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/suggestion_banner_engine.dart';

class SuggestionBanner extends StatefulWidget {
  const SuggestionBanner({super.key});

  @override
  State<SuggestionBanner> createState() => _SuggestionBannerState();
}

class _SuggestionBannerState extends State<SuggestionBanner> {
  bool _loading = true;
  SuggestionBannerData? _data;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final engine = context.read<SuggestionBannerEngine>();
    final data = await engine.getBanner();
    if (mounted) {
      setState(() {
        _data = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    if (_loading || d == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            d.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(d.subtitle, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: d.onTap,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: Text(d.buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
