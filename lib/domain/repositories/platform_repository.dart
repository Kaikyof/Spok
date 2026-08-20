import '../entities/snapshot.dart';

abstract class PlatformRepository {
  /// Путь к репозиторию платформы; null — не найден.
  String? get rootPath;

  /// Роль машины из AVTOTO_ROLE.
  String get role;

  Future<ConsoleSnapshot> load();

  /// Читает markdown-файл документации (внутри репозитория платформы).
  Future<String> readDoc(String absolutePath);
}
