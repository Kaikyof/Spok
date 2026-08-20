import '../entities/console_snapshot.dart';

abstract class PlatformRepository {
  /// Путь к репозиторию платформы; null — не найден.
  String? get rootPath;

  /// Роль машины из AVTOTO_ROLE.
  String get role;

  Future<ConsoleSnapshot> load();

  /// Читает markdown-файл документации (внутри репозитория платформы).
  Future<String> readDoc(String absolutePath);

  /// Путь к конфиг-файлу приложения (для подсказки на экране настройки).
  Future<String> configFilePath();

  /// Сохраняет путь к платформе; false — по пути нет workspace.yaml.
  Future<bool> setPlatformDir(String path);
}
