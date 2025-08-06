import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

/// Displays the contents of `autogen_report.log` and refreshes periodically.
class InlineReportViewerWidget extends StatefulWidget {
  const InlineReportViewerWidget({super.key});

  @override
  State<InlineReportViewerWidget> createState() => _InlineReportViewerWidgetState();
}

class _InlineReportViewerWidgetState extends State<InlineReportViewerWidget> {
  String _content = '';
  String _status = 'In progress...';
  String _errors = '0';
  Timer? _timer;
  bool _finalStatsLogged = false;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _load());
  }

  Future<void> _load() async {
    try {
      final file = File('autogen_report.log');
      if (await file.exists()) {
        final text = await file.readAsString();
        final endMatch = RegExp(r'^End:\\s*(.*)\\$', multiLine: true).firstMatch(text);
        final errorMatch = RegExp(r'^Errors:\\s*(\\d+)', multiLine: true).firstMatch(text);
        setState(() {
          _content = text;
          _errors = errorMatch?.group(1) ?? '0';
          if (endMatch != null) {
            _status = 'Completed at ${endMatch.group(1)}';
            _finalStatsLogged = true;
            _timer?.cancel();
          } else {
            _status = 'In progress...';
          }
        });
      } else {
        setState(() {
          _content = '';
          _status = 'In progress...';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error reading log';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_status),
        Text('Errors: $_errors'),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: SelectableText(_content),
          ),
        ),
      ],
    );
  }
}

