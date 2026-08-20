import 'entities.dart';

/// Слепок состояния платформы на момент обновления.
/// Приложение ничего не хранит: слепок пересобирается заново при каждом refresh.
class ConsoleSnapshot {
  final List<Sprint> sprints;
  final List<ChangeUnit> changes;
  final List<Divergence> divergences;
  final EnvReport env;
  final String? redmineProblem; // null — статусы Redmine получены
  final DateTime refreshedAt;

  const ConsoleSnapshot({
    required this.sprints,
    required this.changes,
    required this.divergences,
    required this.env,
    required this.redmineProblem,
    required this.refreshedAt,
  });
}
