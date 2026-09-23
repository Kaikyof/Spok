import 'dart:io';

import 'package:path/path.dart' as p;

/// Конфиг приложения — .env-файл в Application Support (macOS).
/// Без path_provider: чистый dart:io, чтобы конфиг был доступен и из
/// CLI-инструментов (tool/smoke.dart), а не только из Flutter-рантайма.
class AppConfigSource {
  static const platformDirKey = 'AVTOTO_PLATFORM_DIR';

  /// Подключённые спеки — пути через «:», как в PATH.
  static const knownSpecsKey = 'SPEC_DIRS';
  static const sessionModelKey = 'SESSION_MODEL';
  static const sessionEffortKey = 'SESSION_EFFORT';
  static const sessionPermissionKey = 'SESSION_PERMISSION_MODE';
  static const sessionTerminalKey = 'SESSION_TERMINAL';

  /// Список моделей для селектора — через запятую. Ключ правится руками:
  /// новая модель не должна ждать релиза приложения.
  static const sessionModelsKey = 'SESSION_MODELS';

  /// Настройка, привязанная к проекту: модель, доступ, усилия и высота
  /// терминала у каждой спеки свои — иначе резюме и режим уходят в чужой
  /// репозиторий (сводный документ, 4.6).
  static String scoped(String key, String? projectPath) {
    final slug = p
        .basename(projectPath ?? '')
        .toUpperCase()
        .replaceAll(RegExp('[^A-Z0-9]'), '_');
    return slug.isEmpty ? key : '${key}__$slug';
  }

  File _configFile() {
    final home = Platform.environment['HOME'] ?? '';
    return File(p.join(
        home, 'Library', 'Application Support', 'Spok', '.env'));
  }

  Future<String> configPath() async => _configFile().path;

  Future<String?> readPlatformDir() => read(platformDirKey);

  Future<void> writePlatformDir(String dir) => write(platformDirKey, dir);

  /// Пути подключённых спек: между ними переключаются из шапки.
  Future<List<String>> readKnownSpecs() async {
    final value = await read(knownSpecsKey) ?? '';
    return [
      for (final path in value.split(':'))
        if (path.trim().isNotEmpty) path.trim(),
    ];
  }

  /// Добавляет спеку в реестр, сохраняя порядок подключения.
  Future<void> rememberSpec(String dir) async {
    final known = await readKnownSpecs();
    if (known.contains(dir)) return;
    await write(knownSpecsKey, [...known, dir].join(':'));
  }

  /// Значение ключа конфига; null — ключа нет.
  Future<String?> read(String key) async {
    final file = _configFile();
    if (!file.existsSync()) return null;
    final entryPattern = RegExp('^$key=(.+)\$');
    for (final line in await file.readAsLines()) {
      final match = entryPattern.firstMatch(line.trim());
      if (match != null) return match.group(1)!.trim();
    }
    return null;
  }

  /// Читает несколько ключей за один проход по файлу.
  Future<Map<String, String>> readAll() async {
    final file = _configFile();
    if (!file.existsSync()) return {};
    final entryPattern = RegExp(r'^([A-Z0-9_]+)=(.*)$');
    return {
      for (final line in await file.readAsLines())
        if (entryPattern.firstMatch(line.trim()) case final match?)
          match.group(1)!: match.group(2)!.trim(),
    };
  }

  /// Записи идут по очереди: настройки сессии сохраняются одновременно,
  /// и параллельная перезапись оставляла в конфиге обрывки чужих строк.
  static Future<void> _queue = Future.value();

  /// Перезаписывает ключ, сохраняя остальные строки файла.
  Future<void> write(String key, String value) {
    final result = _queue.then((_) => _writeNow(key, value));
    _queue = result.catchError((_) {});
    return result;
  }

  Future<void> _writeNow(String key, String value) async {
    final file = _configFile();
    final lines = file.existsSync() ? await file.readAsLines() : <String>[];
    // Заодно выметаем обрывки строк от прежних параллельных записей.
    lines.removeWhere((line) =>
        line.startsWith('$key=') ||
        !RegExp(r'^[A-Z0-9_]+=').hasMatch(line.trim()));
    lines.add('$key=$value');
    await file.parent.create(recursive: true);
    // Пишем во временный файл и подменяем: оборванная запись не портит конфиг.
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString('${lines.join('\n')}\n', flush: true);
    await temporary.rename(file.path);
  }
}
