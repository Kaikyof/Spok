import 'stack_state.dart';

/// Change — единица работы: спека, задачи, код, тест-кейсы.
class ChangeUnit {
  final String id; // имя папки openspec/changes/<id>
  final String title;
  final String dir; // абсолютный путь к папке change'а
  final String groupId; // id группы; пусто — вне групп
  final List<String> dependsOn; // предшественники из group.members

  /// Стеки change'а в порядке схемы; пусто — работа без разделения на стеки.
  final Map<String, StackState> stackStates;

  /// Формат `redmine.yaml` не распознан — показываем это, а не пустоту.
  final String formatWarning;

  const ChangeUnit({
    required this.id,
    required this.title,
    required this.dir,
    this.groupId = '',
    this.stackStates = const {},
    this.dependsOn = const [],
    this.formatWarning = '',
  });

  List<StackState> get stacks => stackStates.values.toList();

  StackState? stack(String id) => stackStates[id];
}
