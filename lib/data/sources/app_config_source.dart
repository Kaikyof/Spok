import 'dart:io';

import 'package:path/path.dart' as p;

/// Конфиг приложения — .env-файл в Application Support (macOS).
/// Без path_provider: чистый dart:io, чтобы конфиг был доступен и из
/// CLI-инструментов (tool/smoke.dart), а не только из Flutter-рантайма.
class AppConfigSource {
  static const platformDirKey = 'AVTOTO_PLATFORM_DIR';
  static const sessionModelKey = 'SESSION_MODEL';
  static const sessionEffortKey = 'SESSION_EFFORT';
  static const sessionPermissionKey = 'SESSION_PERMISSION_MODE';

  File _configFile() {
    final home = Platform.environment['HOME'] ?? '';
    return File(p.join(
        home, 'Library', 'Application Support', 'PlatformConsole', '.env'));
  }

  Future<String> configPath() async => _configFile().path;

  Future<String?> readPlatformDir() => read(platformDirKey);

  Future<void> writePlatformDir(String dir) => write(platformDirKey, dir);

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

  /// Перезаписывает ключ, сохраняя остальные строки файла.
  Future<void> write(String key, String value) async {
    final file = _configFile();
    final lines = file.existsSync() ? await file.readAsLines() : <String>[];
    lines.removeWhere((line) => line.startsWith('$key='));
    lines.add('$key=$value');
    await file.create(recursive: true);
    await file.writeAsString('${lines.join('\n')}\n');
  }
}
