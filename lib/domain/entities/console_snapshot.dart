import 'change_unit.dart';
import 'divergence.dart';
import 'doc_node.dart';
import 'env_report.dart';
import 'group.dart';
import 'project_profile.dart';

/// Почему статусы трекера не получены.
///
/// [notDeclared] — спека трекером не пользуется: нет ни `openspec/redmine.yaml`,
/// ни ключа адреса в `.env.example`. Это не нехватка, а устройство спеки:
/// трекер не опрашивается, и полосы над таблицей нет.
enum TrackerProblem { none, notDeclared, noApiKey, unreachable, platformNotFound }

/// Слепок состояния платформы на момент обновления.
/// Приложение ничего не хранит: слепок пересобирается заново при refresh.
class ConsoleSnapshot {
  final List<Group> groups;
  final List<ChangeUnit> changes;
  final List<Divergence> divergences;
  final EnvReport env;

  /// Дерево документов спеки: группы, их change'и и архив.
  final List<DocNode> docs;

  /// Что распознано в спеке: схема, статусы, стеки, доступные фичи.
  final ProjectProfile profile;

  final TrackerProblem trackerProblem;
  final String trackerProblemDetail;

  /// Имя системы трекера из контракта («Redmine»); пусто — трекера нет.
  /// Тексты ядра подставляют его вместо названия системы.
  final String trackerName;

  /// Ключи `.env`, без которых трекер не спросить; пусто — трекера нет.
  final List<String> trackerKeys;

  /// Адрес задачи по идентификатору — от контракта трекера; null —
  /// ссылку собрать не из чего.
  final String? Function(int issueId) issueUrl;

  final DateTime refreshedAt;

  const ConsoleSnapshot({
    required this.groups,
    required this.changes,
    required this.divergences,
    required this.env,
    this.docs = const [],
    this.profile = const ProjectProfile(),
    required this.trackerProblem,
    this.trackerProblemDetail = '',
    this.trackerName = '',
    this.trackerKeys = const [],
    this.issueUrl = noIssueUrl,
    required this.refreshedAt,
  });

  /// Трекер объявлен спекой и спрошен или мог быть спрошен: его статусы
  /// и ссылки имеют смысл показывать рядом со стадией.
  bool get trackerActive =>
      trackerProblem != TrackerProblem.notDeclared && trackerProblem != TrackerProblem.platformNotFound;

  /// Адресов задач нет — у спеки без трекера.
  static String? noIssueUrl(int issueId) => null;
}
