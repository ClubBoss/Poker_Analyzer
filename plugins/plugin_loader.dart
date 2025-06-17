import 'converter_discovery_plugin.dart';
import 'converter_plugin.dart';
import 'plugin.dart';
import 'sample_logging_plugin.dart';

/// Prototype loader for built-in plug-ins.
///
/// Future iterations may support loading plugins dynamically. For now this
/// returns the set of plug-ins bundled directly with the application.
class PluginLoader {
  /// Returns all built-in plug-ins included with the application.
  List<Plugin> loadBuiltInPlugins() {
    // Currently there are no built-in converter plug-ins to supply to the
    // discovery plug-in, so an empty list is passed.
    return <Plugin>[
      SampleLoggingPlugin(),
      ConverterDiscoveryPlugin(<ConverterPlugin>[]),
    ];
  }
}
