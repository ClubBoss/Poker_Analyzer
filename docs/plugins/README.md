# Создание плагинов

## Структура плагина

Плагин наследует интерфейс `Plugin` и реализует метод `register()` для регистрации сервисов. При необходимости можно возвращать расширения через `extensions`.

```dart
abstract class Plugin {
  void register(ServiceRegistry registry);
  List<ServiceExtension<dynamic>> get extensions => <ServiceExtension<dynamic>>[];
}
```

## Загрузка и включение

`PluginLoader` ищет файлы `*Plugin.dart` в папке `plugins`. Метод `loadFromFile()` подключает плагин только если он разрешён в `plugin_config.json`.

```dart
Future<Plugin?> loadFromFile(File file) async {
  final name = p.basename(file.path);
  final config = await loadConfig();
  if (config[name] == false) {
    ErrorLogger.instance.logError('Plugin skipped: $name');
    return null;
  }
  // загрузка и инициализация
}
```

Пример конфигурации:

```json
{
  "SampleLoggingPlugin": true,
  "ConverterDiscoveryPlugin": true
}
```

## Пример

`SampleLoggingPlugin` регистрирует сервис логирования:

```dart
class LoggerService {
  void log(String message) {
    ErrorLogger.instance.logError('LOG: $message');
  }
}

class LoggerServiceExtension extends ServiceExtension<LoggerService> {
  @override
  LoggerService create(ServiceRegistry registry) => LoggerService();
}

class SampleLoggingPlugin implements Plugin {
  @override
  void register(ServiceRegistry registry) {}

  @override
  List<ServiceExtension<dynamic>> get extensions =>
      <ServiceExtension<dynamic>>[LoggerServiceExtension()];
}
```

## Управление и тестирование

`PluginManagerScreen` перечисляет доступные файлы и сохраняет выбор в `plugin_config.json`. Кнопка «Reload Plugins» перезагружает плагины:

```dart
Future<void> _reload() async {
  final registry = ServiceRegistry();
  final manager = PluginManager();
  final loader = PluginLoader();
  await loader.loadAll(registry, manager, context: context);
  if (mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Plugins reloaded')));
  }
}
```

После перезагрузки новые модули становятся активны. Кнопка «Reset Plugins» удаляет конфигурацию и кэш.
Загрузчик также проверяет повторяющиеся имена плагинов. Если такие найдены, дубликаты пропускаются, а на экране появляется предупреждение.
