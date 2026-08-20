import 'dart:io';

import 'package:path/path.dart' as p;

/// Конфиг приложения — .env-файл в Application Support (macOS).
/// Без path_provider: чистый dart:io, чтобы конфиг был доступен и из
/// CLI-инструментов (tool/smoke.dart), а не только из Flutter-рантайма.
/// Пока единственный ключ: AVTOTO_PLATFORM_DIR (путь к репозиторию платформы).
class AppConfigSource {
  static const platformDirKey = 'AVTOTO_PLATFORM_DIR';

  File _configFile() {
    final home = Platform.environment['HOME'] ?? '';
    return File(p.join(
        home, 'Library', 'Application Support', 'PlatformConsole', '.env'));
  }

  Future<String> configPath() async => _configFile().path;

  Future<String?> readPlatformDir() async {
    final file = _configFile();
    if (!file.existsSync()) return null;
    final entryPattern = RegExp('^$platformDirKey=(.+)\$');
    for (final line in await file.readAsLines()) {
      final match = entryPattern.firstMatch(line.trim());
      if (match != null) return match.group(1)!.trim();
    }
    return null;
  }

  Future<void> writePlatformDir(String dir) async {
    final file = _configFile();
    final lines = file.existsSync() ? await file.readAsLines() : <String>[];
    lines.removeWhere((line) => line.startsWith('$platformDirKey='));
    lines.add('$platformDirKey=$dir');
    await file.create(recursive: true);
    await file.writeAsString('${lines.join('\n')}\n');
  }
}
