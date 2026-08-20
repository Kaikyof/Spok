import 'task_item.dart';

/// Состояние одного стека (iOS или Android) внутри change'а.
class StackState {
  final String stack; // ios | android
  final int? issueId;
  final List<TaskItem> tasks;

  /// null — статус недоступен (нет ключа или Redmine не ответил).
  String? redmineStatus;

  StackState({required this.stack, this.issueId, required this.tasks});

  int get doneCount => tasks.where((task) => task.done).length;

  List<TaskItem> get openTasks => tasks.where((task) => !task.done).toList();

  bool get allDone => tasks.isNotEmpty && openTasks.isEmpty;
}
