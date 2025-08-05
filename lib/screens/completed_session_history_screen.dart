import 'package:flutter/material.dart';
import 'package:poker_analyzer/presenters/completed_session_history_presenter.dart';
import 'package:poker_analyzer/services/completed_session_summary_service.dart';

class CompletedSessionHistoryScreen extends StatefulWidget {
  const CompletedSessionHistoryScreen({super.key});

  @override
  State<CompletedSessionHistoryScreen> createState() =>
      _CompletedSessionHistoryScreenState();
}

class _CompletedSessionHistoryScreenState
    extends State<CompletedSessionHistoryScreen> {
  final _presenter = const CompletedSessionHistoryPresenter();
  var _items = <CompletedSessionDisplayItem>[];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final summaries = await const CompletedSessionSummaryService()
        .loadSummaries();
    final items = _presenter.present(summaries);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Completed Sessions')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('No completed sessions yet.'))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(item.subtitle),
                  trailing: const Icon(Icons.chevron_right),
                );
              },
            ),
    );
  }
}
