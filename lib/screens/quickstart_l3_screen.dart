import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/l3_cli_runner.dart';
import '../utils/shared_prefs_keys.dart';
import 'l3_report_viewer_screen.dart';

class QuickstartL3Screen extends StatefulWidget {
  const QuickstartL3Screen({super.key});

  @override
  State<QuickstartL3Screen> createState() => _QuickstartL3ScreenState();
}

class _QuickstartL3ScreenState extends State<QuickstartL3Screen> {
  final _weightsController = TextEditingController();
  String? _weightsPreset;
  bool _running = false;
  L3CliResult? _result;
  String? _lastReportPath;
  String? _inlineWarning;
  String? _error;

  bool get _isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  @override
  void initState() {
    super.initState();
    _loadLast();
    if (!_isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final loc = AppLocalizations.of(context);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            content: Text(loc.desktopOnly),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              )
            ],
          ),
        ).then((_) => Navigator.pop(context));
      });
    }
  }

  Future<void> _loadLast() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastReportPath = prefs.getString(SharedPrefsKeys.lastL3ReportPath);
    });
  }

  Future<void> _run() async {
    setState(() {
      _running = true;
      _error = null;
      _inlineWarning = null;
    });
    var weights = _weightsController.text.trim();
    String? weightsArg = weights.isEmpty ? null : weights;
    var preset = _weightsPreset;
    if (weightsArg != null && preset != null) {
      weightsArg = null;
      _inlineWarning = AppLocalizations.of(context).presetWillBeUsed;
    }
    final runner = L3CliRunner();
    final res = await runner.run(weights: weightsArg, weightsPreset: preset);
    final prefs = await SharedPreferences.getInstance();
    if (res.exitCode == 0) {
      await prefs.setString(SharedPrefsKeys.lastL3ReportPath, res.outPath);
      _lastReportPath = res.outPath;
    }
    setState(() {
      _running = false;
      _result = res;
      if (res.exitCode != 0) {
        _error = res.stderr;
      }
    });
    final warnings = <String>[];
    if (_inlineWarning != null) warnings.add(_inlineWarning!);
    warnings.addAll(res.warnings);
    if (warnings.isNotEmpty && mounted) {
      for (final w in warnings) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(w)));
      }
    }
  }

  Future<void> _openReport() async {
    final path = _lastReportPath;
    if (path == null) return;
    final file = File(path);
    final exists = await file.exists();
    if (!exists || (await file.readAsString()).trim().isEmpty) {
      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.reportEmpty)));
      }
      return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => L3ReportViewerScreen(path: path)),
    );
  }

  void _viewLogs() {
    final path = _result?.logPath;
    if (path == null) return;
    final text = File(path).readAsStringSync();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context).viewLogs),
        content: SingleChildScrollView(child: SelectableText(text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  void _retry() {
    _run();
  }

  @override
  void dispose() {
    _weightsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    Widget body;
    if (_running) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _viewLogs,
                      child: Text(loc.viewLogs),
                    ),
                    TextButton(
                      onPressed: _retry,
                      child: Text(loc.retry),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      );
    } else {
      body = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _weightsController,
              decoration: InputDecoration(labelText: loc.weightsJson),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              hint: Text(loc.weightsPreset),
              value: _weightsPreset,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'default', child: Text('default')),
                DropdownMenuItem(value: 'aggro', child: Text('aggro')),
                DropdownMenuItem(value: 'nitty', child: Text('nitty')),
              ],
              onChanged: (v) => setState(() => _weightsPreset = v),
            ),
            if (_weightsController.text.isNotEmpty && _weightsPreset != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_inlineWarning ?? ''),
              ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _run, child: Text(loc.run)),
            const SizedBox(height: 16),
            if (_lastReportPath != null)
              ElevatedButton(
                onPressed: _openReport,
                child: Text(loc.openReport),
              ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(loc.quickstartL3)),
      body: body,
    );
  }
}
