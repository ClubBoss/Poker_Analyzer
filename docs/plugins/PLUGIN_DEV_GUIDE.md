# Plugin Development Guide

This guide covers how to create and register custom plug-ins for Poker Analyzer.

## Plugin interface

A plug-in implements the `Plugin` class and registers services inside `register()`:

```dart
abstract class Plugin {
  void register(ServiceRegistry registry);
  List<ServiceExtension<dynamic>> get extensions;
  String get name;
  String get description;
  String get version;
}
```

`extensions` is an optional list of `ServiceExtension` objects that inject additional services.

## Converter plug-ins

Converters handle import and export of external formats. They extend `ConverterPlugin`:

```dart
abstract class ConverterPlugin extends AbstractConverterPlugin {
  ConverterPlugin({
    required this.formatId,
    required this.description,
    required ConverterFormatCapabilities capabilities,
  }) : super(capabilities);

  final String formatId;
  final String description;

  SavedHand? convertFrom(String externalData);
}
```

See `lib/plugins/converters/poker_analyzer_json_converter.dart` and other files in `lib/plugins/converters` for complete examples.

## Building a custom plug-in

1. Create a Dart file ending with `Plugin.dart`.
2. Implement `Plugin` or `ConverterPlugin` in that file.
3. Compile the plug-in using `dart compile jit-snapshot` or include it directly in the `plugins` directory.
4. Place the resulting `<Name>Plugin.dart` inside the `plugins` folder of the app data directory.
5. Enable the plug-in from `PluginManagerScreen` and reload plug-ins.

Example snippet for a simple converter:

```dart
class MyFormatConverter extends ConverterPlugin {
  MyFormatConverter()
      : super(
          formatId: 'my_format',
          description: 'Custom format',
          capabilities: const ConverterFormatCapabilities(
            supportsImport: true,
            supportsExport: true,
            requiresBoard: false,
            supportsMultiStreet: true,
          ),
        );

  @override
  SavedHand? convertFrom(String externalData) {
    // parse data
    return null;
  }
}
```

To make the converter discoverable, add it to a plug-in:

```dart
class MyPlugin implements Plugin {
  @override
  void register(ServiceRegistry registry) {}

  @override
  List<ServiceExtension<dynamic>> get extensions => [];

  @override
  String get name => 'My Plugin';

  @override
  String get description => 'Adds MyFormat support';

  @override
  String get version => '1.0.0';
}
```

Register the converter by creating a `ConverterDiscoveryPlugin` with your converter and returning it from the isolate entrypoint.

