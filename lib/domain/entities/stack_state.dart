import 'task_item.dart';

/// Состояние одного стека внутри change'а (backend, ios, mobile …).
/// Стек без задач — единственный «стек работы» change'а с id `work`.
class StackState {
  /// Единственный стек change'а, у которого стеков нет.
  static const singleWorkStack = 'work';

  final String stack;
  final int? issueId;
  final List<TaskItem> tasks;

  /// Статус из кэша `redmine.yaml` change'а: показывается сразу и офлайн.
  final String? cachedStatus;

  /// Статус из трекера; null — не опрошен (нет ключа или Redmine молчит).
  String? liveStatus;

  StackState({
    required this.stack,
    this.issueId,
    required this.tasks,
    this.cachedStatus,
  });

  /// Что показывать: живой статус, иначе закэшированный.
  String? get redmineStatus => liveStatus ?? cachedStatus;

  /// Статус взят из файла, трекер не опрошен — данные могут быть вчерашними.
  bool get statusFromCache => liveStatus == null && cachedStatus != null;

  int get doneCount => tasks.where((task) => task.done).length;

  List<TaskItem> get openTasks => tasks.where((task) => !task.done).toList();

  bool get allDone => tasks.isNotEmpty && openTasks.isEmpty;
}
