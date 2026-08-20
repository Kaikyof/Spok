import 'change_unit.dart';
import 'divergence.dart';
import 'env_report.dart';
import 'sprint.dart';

/// Причина, по которой статусы Redmine не получены.
enum RedmineProblem { none, noApiKey, unreachable, platformNotFound }

/// Слепок состояния платформы на момент обновления.
/// Приложение ничего не хранит: слепок пересобирается заново при refresh.
class ConsoleSnapshot {
  final List<Sprint> sprints;
  final List<ChangeUnit> changes;
  final List<Divergence> divergences;
  final EnvReport env;
  final RedmineProblem redmineProblem;
  final String redmineProblemDetail;
  final String redmineBaseUrl; // для кликабельных ссылок на задачи
  final DateTime refreshedAt;

  const ConsoleSnapshot({
    required this.sprints,
    required this.changes,
    required this.divergences,
    required this.env,
    required this.redmineProblem,
    this.redmineProblemDetail = '',
    this.redmineBaseUrl = '',
    required this.refreshedAt,
  });
}
