import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';

import '../models/training_pack_template.dart';
import '../services/template_storage_service.dart';
import '../services/training_session_service.dart';
import '../services/training_topic_suggestion_engine.dart';
import '../screens/training_session_screen.dart';

class SmartSuggestionBanner extends StatefulWidget {
  final Set<String> selectedTags;
  const SmartSuggestionBanner({super.key, required this.selectedTags});

  @override
  State<SmartSuggestionBanner> createState() => _SmartSuggestionBannerState();
}

class _SmartSuggestionBannerState extends State<SmartSuggestionBanner> {
  static const _hideKey = 'hideSmartBannerUntil';
  static const _packKey = 'smartBannerPackId';
  static const _tagKey = 'smartBannerTag';
  static const _dateKey = 'smartBannerDate';

  bool _loading = true;
  TrainingPackTemplate? _pack;
  String? _tag;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final hideStr = prefs.getString(_hideKey);
    final now = DateTime.now();
    if (hideStr != null) {
      final hideUntil = DateTime.tryParse(hideStr);
      if (hideUntil != null && now.isBefore(hideUntil)) {
        setState(() => _loading = false);
        return;
      }
    }
    if (widget.selectedTags.isNotEmpty) {
      setState(() => _loading = false);
      return;
    }
    final dateStr = prefs.getString(_dateKey);
    if (dateStr != null) {
      final d = DateTime.tryParse(dateStr);
      if (d != null &&
          d.year == now.year &&
          d.month == now.month &&
          d.day == now.day) {
        final id = prefs.getString(_packKey);
        final tag = prefs.getString(_tagKey);
        if (id != null && tag != null) {
          final list = context.read<TemplateStorageService>().templates;
          final tpl = list.firstWhereOrNull((t) => t.id == id);
          if (tpl != null) {
            setState(() {
              _pack = tpl;
              _tag = tag;
              _loading = false;
            });
            return;
          }
        }
      }
    }
    final tag = await const TrainingTopicSuggestionEngine().suggestNextTag();
    if (tag == null) {
      setState(() => _loading = false);
      return;
    }
    final list = context.read<TemplateStorageService>().templates;
    final tpl = list.firstWhereOrNull((t) => t.tags.contains(tag));
    if (tpl == null) {
      setState(() => _loading = false);
      return;
    }
    await prefs.setString(_packKey, tpl.id);
    await prefs.setString(_tagKey, tag);
    await prefs.setString(
      _dateKey,
      DateTime(now.year, now.month, now.day).toIso8601String(),
    );
    if (mounted) {
      setState(() {
        _pack = tpl;
        _tag = tag;
        _loading = false;
      });
    }
  }

  Future<void> _hide() async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(const Duration(days: 1));
    await prefs.setString(_hideKey, until.toIso8601String());
    if (mounted) setState(() => _pack = null);
  }

  Future<void> _start() async {
    final tpl = _pack;
    if (tpl == null) return;
    await context.read<TrainingSessionService>().startSession(tpl);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _pack == null || _tag == null)
      return const SizedBox.shrink();
    if (widget.selectedTags.contains(_tag)) return const SizedBox.shrink();
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
          Row(
            children: [
              const Text('📌', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_tag!, style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(
                      '🃏 ${_pack!.name}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: _hide,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Начать тренировку'),
            ),
          ),
        ],
      ),
    );
  }
}
