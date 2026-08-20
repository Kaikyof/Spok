import 'stack_state.dart';

/// Change — единица работы: спека, задачи, код, тест-кейсы.
class ChangeUnit {
  final String id; // имя папки openspec/changes/<id>
  final String title;
  final String dir; // абсолютный путь к папке change'а
  final StackState? ios;
  final StackState? android;
  final List<String> dependsOn; // предшественники из group.members

  const ChangeUnit({
    required this.id,
    required this.title,
    required this.dir,
    this.ios,
    this.android,
    this.dependsOn = const [],
  });

  List<StackState> get stacks => [?ios, ?android];
}
