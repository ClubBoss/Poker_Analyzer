import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/theory_snippet.dart';

class InlineTheoryRecallCard extends StatefulWidget {
  final TheorySnippet snippet;
  final List<TheorySnippet> snippets;
  final VoidCallback onDismiss;
  const InlineTheoryRecallCard({
    super.key,
    required this.snippet,
    this.snippets = const [],
    required this.onDismiss,
  });

  @override
  State<InlineTheoryRecallCard> createState() => _InlineTheoryRecallCardState();
}

class _InlineTheoryRecallCardState extends State<InlineTheoryRecallCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _controller.forward();
    _timer = Timer(const Duration(seconds: 12), _handleDismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    if (mounted) widget.onDismiss();
  }

  Future<void> _showMore() async {
    _timer?.cancel();
    await showModalBottomSheet(
      context: context,
      builder: (_) => SizedBox(
        height: 300,
        child: PageView(
          children: [
            for (final s in widget.snippets)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    Text(s.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    for (final b in s.bullets)
                      Text('• $b', style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
    if (mounted) {
      _timer = Timer(const Duration(seconds: 12), _handleDismiss);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snippet = widget.snippet;
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
      child: GestureDetector(
        onTap: _handleDismiss,
        child: Card(
          color: Colors.blueGrey[800],
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(snippet.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                for (final b in snippet.bullets)
                  Text('• $b', style: const TextStyle(color: Colors.white70)),
                if (snippet.uri != null)
                  TextButton(
                    onPressed: () async {
                      final uri = Uri.parse(snippet.uri!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    child: const Text('Learn More'),
                  ),
                if (widget.snippets.length > 1)
                  TextButton(
                    onPressed: _showMore,
                    child: const Text('More on this...'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
