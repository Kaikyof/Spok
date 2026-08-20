import '../entities/console_snapshot.dart';
import '../entities/issue_comment.dart';
import '../entities/slash_command.dart';

abstract class PlatformRepository {
  /// Команды платформы (.claude/commands) для автокомплита в сессиях.
  List<SlashCommand> slashCommands();

  /// Значения для подсказок аргументов: id change'ей и спринтов.
  ({List<String> changeIds, List<String> sprintIds}) argumentValues();

  /// Путь к репозиторию платформы; null — не найден.
  String? get rootPath;

  /// Роль машины из AVTOTO_ROLE.
  String get role;

  Future<ConsoleSnapshot> load();

  /// Читает markdown-файл документации (внутри репозитория платформы).
  Future<String> readDoc(String absolutePath);

  /// Лента комментариев задач change'а; пустая, если Redmine недоступен.
  Future<List<IssueComment>> issueComments(List<int> issueIds);

  /// Путь к конфиг-файлу приложения (для подсказки на экране настройки).
  Future<String> configFilePath();

  /// Сохраняет путь к платформе; false — по пути нет workspace.yaml.
  Future<bool> setPlatformDir(String path);
}
