/// Пункт чеклиста из `tasks_<stack>.md`: «- [x] 1.1 Название».
class TaskItem {
  final String number; // «3.3»
  final String title;
  final bool done;

  const TaskItem(this.number, this.title, this.done);
}
