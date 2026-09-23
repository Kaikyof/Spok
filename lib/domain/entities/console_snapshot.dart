import 'change_unit.dart';
import 'divergence.dart';
import 'doc_node.dart';
import 'env_report.dart';
import 'group.dart';
import 'project_profile.dart';

/// Причина, по которой статусы Redmine не получены.
enum RedmineProblem { none, noApiKey, unreachable, platformNotFound }

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

  final RedmineProblem redmineProblem;
  final String redmineProblemDetail;
  final String redmineBaseUrl; // для кликабельных ссылок на задачи
  final DateTime refreshedAt;

  const ConsoleSnapshot({
    required this.groups,
    required this.changes,
    required this.divergences,
    required this.env,
    this.docs = const [],
    this.profile = const ProjectProfile(),
    required this.redmineProblem,
    this.redmineProblemDetail = '',
    this.redmineBaseUrl = '',
    required this.refreshedAt,
  });
}
