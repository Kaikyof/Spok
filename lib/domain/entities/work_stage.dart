import 'task_item.dart';

/// Стадия работы change'а, выведенная из его файлов: какие артефакты
/// написаны, сколько задач закрыто, сдан ли change в архив.
///
/// Стадия есть у любой спеки — с трекером и без. Трекер, если он есть,
/// кладёт свой статус рядом ярлыком, но стадию не заменяет: она описывает
/// файлы, а не чужие категории статусов.
sealed class WorkStage {
  const WorkStage();

  static const readyToApply = ReadyToApplyStage();
  static const done = DoneStage();
  static const archived = ArchivedStage();

  /// Стадия по одним отметкам: задач нет или ни одна не закрыта — можно
  /// реализовывать; закрыта часть — в работе; все — сделано. Артефакты
  /// здесь не смотрятся — это делает `AssessWorkStage`.
  static WorkStage fromTasks(Iterable<TaskItem> tasks) {
    var done = 0;
    var total = 0;
    for (final task in tasks) {
      total++;
      if (task.done) done++;
    }
    if (total == 0 || done == 0) return readyToApply;
    if (done < total) return InProgressStage(done, total);
    return WorkStage.done;
  }

  /// Порядок стадий по ходу работы: по нему выбирается самый «отстающий»
  /// change группы для плашки следующего шага.
  int get rank => switch (this) {
    PlanningStage() => 0,
    ReadyToApplyStage() => 1,
    InProgressStage() => 2,
    DoneStage() => 3,
    ArchivedStage() => 4,
  };
}

/// Планирование: артефакт [next] ещё не написан, а всё, чего он требует
/// по `requires`, уже готово.
class PlanningStage extends WorkStage {
  final String next;

  const PlanningStage(this.next);

  @override
  bool operator ==(Object other) => other is PlanningStage && other.next == next;

  @override
  int get hashCode => Object.hash(PlanningStage, next);

  @override
  String toString() => 'PlanningStage($next)';
}

/// Все артефакты написаны или пропущены, задач нет либо ни одна не закрыта.
class ReadyToApplyStage extends WorkStage {
  const ReadyToApplyStage();

  @override
  String toString() => 'ReadyToApplyStage';
}

/// Часть задач закрыта.
class InProgressStage extends WorkStage {
  final int done;
  final int total;

  const InProgressStage(this.done, this.total);

  @override
  bool operator ==(Object other) => other is InProgressStage && other.done == done && other.total == total;

  @override
  int get hashCode => Object.hash(InProgressStage, done, total);

  @override
  String toString() => 'InProgressStage($done/$total)';
}

/// Все задачи закрыты, change ещё не в архиве.
class DoneStage extends WorkStage {
  const DoneStage();

  @override
  String toString() => 'DoneStage';
}

/// Change лежит в `openspec/changes/archive/`.
class ArchivedStage extends WorkStage {
  const ArchivedStage();

  @override
  String toString() => 'ArchivedStage';
}
