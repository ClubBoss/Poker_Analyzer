import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:poker_analyzer/plugins/plugin_loader_io.dart';
import 'package:poker_analyzer/plugins/sample_logging_plugin.dart';
import 'package:poker_analyzer/plugins/plugin_manager.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

class _FakeHttpClient extends HttpClient {
  _FakeHttpClient(this.data);
  final List<int> data;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _Request(data);
  @override
  void close({bool force = false}) {}
}

class _Request implements HttpClientRequest {
  _Request(this.data);
  final List<int> data;
  @override
  Future<HttpClientResponse> close() async => _Response(data);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.data);
  final List<int> data;
  @override
  int get statusCode => HttpStatus.ok;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([data]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadBuiltInPlugins includes logger', () {
    final loader = PluginLoader();
    final plugins = loader.loadBuiltInPlugins();
    expect(plugins.whereType<SampleLoggingPlugin>().length, 1);
  });

  test('loadConfig reads config file', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _FakePathProvider(dir.path);
    final pluginsDir = Directory('${dir.path}/plugins');
    await pluginsDir.create();
    await File(
      '${pluginsDir.path}/plugin_config.json',
    ).writeAsString('{"X.dart": false}');
    final loader = PluginLoader();
    final config = await loader.loadConfig();
    expect(config['X.dart'], false);
  });

  test('loadFromFile spawns isolate', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _FakePathProvider(dir.path);
    final pluginsDir = Directory('${dir.path}/plugins');
    await pluginsDir.create();
    await File('${pluginsDir.path}/plugin_config.json').writeAsString('{}');
    final file = File('${pluginsDir.path}/TestPlugin.dart');
    await file.writeAsString('''
import 'dart:isolate';
import 'package:poker_analyzer/plugins/sample_logging_plugin.dart';
void main(List<String> args, SendPort port) {
  port.send(SampleLoggingPlugin());
}
''');
    final loader = PluginLoader();
    final manager = PluginManager();
    final plugin = await loader.loadFromFile(file, manager);
    expect(plugin, isA<SampleLoggingPlugin>());
  });

  test('loadFromFile rejects invalid checksum', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _FakePathProvider(dir.path);
    final pluginsDir = Directory('${dir.path}/plugins');
    await pluginsDir.create();
    await File('${pluginsDir.path}/plugin_config.json').writeAsString('{}');
    final file = File('${pluginsDir.path}/TestPlugin.dart');
    await file.writeAsString('''
import 'dart:isolate';
import 'package:poker_analyzer/plugins/sample_logging_plugin.dart';
void main(List<String> args, SendPort port) {
  port.send(SampleLoggingPlugin());
}
''');
    await File('${file.path}.sha256').writeAsString('0');
    final loader = PluginLoader();
    final manager = PluginManager();
    final plugin = await loader.loadFromFile(file, manager);
    expect(plugin, isNull);
  });

  test('downloadFromUrl saves file', () async {
    final bytes = utf8.encode('data');
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _FakePathProvider(dir.path);
    HttpOverrides.runZoned(() async {
      final loader = PluginLoader();
      final downloaded = await loader.downloadFromUrl(
        'http://x/TestPlugin.dart',
      );
      expect(downloaded, true);
      final file = File('${dir.path}/plugins/TestPlugin.dart');
      expect(await file.exists(), true);
      expect(await file.readAsString(), 'data');
    }, createHttpClient: (_) => _FakeHttpClient(bytes));
  });
}
