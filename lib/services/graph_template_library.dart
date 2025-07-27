import 'graph_path_template_generator.dart';

/// Central registry of reusable graph templates.
class GraphTemplateLibrary {
  GraphTemplateLibrary._();

  /// Singleton instance.
  static final GraphTemplateLibrary instance = GraphTemplateLibrary._();

  final Map<String, String> _templates = {
    'cash_vs_mtt': const GraphPathTemplateGenerator().generateCashVsMttTemplate(),
    'live_vs_online': const GraphPathTemplateGenerator().generateLiveVsOnlineTemplate(),
    'icm_intro': const GraphPathTemplateGenerator().generateIcmIntroTemplate(),
    'heads_up_intro': const GraphPathTemplateGenerator().generateHeadsUpIntroTemplate(),
  };

  /// IDs of available templates.
  List<String> listTemplates() => List.unmodifiable(_templates.keys);

  /// Returns YAML template with [id] or empty string if not found.
  String getTemplate(String id) => _templates[id] ?? '';
}
