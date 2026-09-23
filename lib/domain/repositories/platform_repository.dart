import '../entities/console_snapshot.dart';
import '../entities/doc_state.dart';
import '../entities/env_field.dart';
import '../entities/handoff_recipient.dart';
import '../entities/issue_comment.dart';
import '../entities/merge_request_info.dart';
import '../entities/slash_command.dart';

abstract class PlatformRepository {
  /// Команды платформы (.claude/commands) для автокомплита в сессиях.
  List<SlashCommand> slashCommands();

  /// Значения для подсказок аргументов: id change'ей и групп.
  ({List<String> changeIds, List<String> groupIds}) argumentValues();

  /// Путь к репозиторию платформы; null — не найден.
  String? get rootPath;

  /// Роль машины из ключа `*_ROLE` в .env спеки.
  String get role;

  /// Имя переменной роли в .env спеки; пусто — спека ролей не использует.
  String get roleKey;

  Future<ConsoleSnapshot> load();

  /// Получатели передачи для стека — подбирает скрипт платформы.
  Future<HandoffRecipients> handoffRecipients(String stack);

  /// Состояние MR change'а по стекам: ярлык GitLab и факт влития.
  /// [groupId] — группа, ветка которой служит целью MR (может быть пустым).
  Future<List<MergeRequestInfo>> mergeRequests(String changeId,
      {String groupId = ''});

  /// Читает markdown-файл документации (внутри репозитория платформы).
  Future<String> readDoc(String absolutePath);

  /// Ветка спеки и состояние файла документа в ней.
  Future<DocState> docState(String absolutePath);

  /// Открывает файл в установленном редакторе; false — открыть нечем.
  Future<bool> openInEditor(String absolutePath);

  /// Лента комментариев задач change'а; пустая, если Redmine недоступен.
  Future<List<IssueComment>> issueComments(List<int> issueIds);

  /// Путь к конфиг-файлу приложения (для подсказки на экране настройки).
  Future<String> configFilePath();

  /// Сохраняет путь к спеке; false — по пути нет openspec/ и workspace.yaml.
  Future<bool> setPlatformDir(String path);

  /// Подключённые спеки: путь к каждой. Текущая входит в список.
  Future<List<String>> knownSpecs();

  /// Форма ключей спеки: поля из `.env.example` со значениями из `.env`.
  Future<EnvForm> envForm();

  /// Сохраняет значения в `.env` спеки.
  Future<void> saveEnv(Map<String, String> values);
}
