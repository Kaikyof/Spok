import '../entities/change_unit.dart';
import '../entities/divergence.dart';
import '../entities/sprint.dart';
import '../entities/stack_state.dart';

/// Правила расхождений: сравнение ярлыка (Redmine) с фактом (файлы, сборки).
/// Каждое правило — отдельный метод; расширяется без изменения слоёв.
class FindDivergences {
  static const _workingStatuses = [
    'Новая',
    'В работе',
    'Возвращена с ревью',
    'Возвращена',
  ];

  static const _testingStatuses = [
    'Ожидает тестирования',
    'На тестировании',
    'Готово к релизу',
  ];

  List<Divergence> call(Sprint? sprint, List<ChangeUnit> changes) {
    final stackEntries = [
      for (final change in changes)
        for (final stack in change.stacks) (change: change, stack: stack),
    ];
    return [
      ...stackEntries.map(_checkStack).nonNulls,
      ..._checkBuilds(sprint, changes),
    ];
  }

  Divergence? _checkStack(({ChangeUnit change, StackState stack}) entry) {
    final stack = entry.stack;
    final status = stack.redmineStatus;
    if (status == null || stack.tasks.isEmpty) return null;

    if (stack.allDone && _workingStatuses.contains(status)) {
      return Divergence(
        kind: DivergenceKind.marksAheadOfStatus,
        changeId: entry.change.id,
        changeTitle: entry.change.title,
        stack: stack.stack,
        redmineStatus: status,
        doneCount: stack.doneCount,
        totalCount: stack.tasks.length,
      );
    }
    if (!stack.allDone && _testingStatuses.contains(status)) {
      return Divergence(
        kind: DivergenceKind.tasksNotClosed,
        changeId: entry.change.id,
        changeTitle: entry.change.title,
        stack: stack.stack,
        redmineStatus: status,
        openTaskNumbers:
            stack.openTasks.map((task) => task.number).toList(),
      );
    }
    return null;
  }

  List<Divergence> _checkBuilds(Sprint? sprint, List<ChangeUnit> changes) {
    if (sprint == null) return const [];
    final anyWaiting = changes
        .expand((change) => change.stacks)
        .any((stack) => stack.redmineStatus == 'Ожидает тестирования');
    if (!anyWaiting) return const [];
    return [
      if (sprint.buildIos == null)
        Divergence(
          kind: DivergenceKind.buildMissing,
          changeId: sprint.id,
          changeTitle: sprint.title,
          stack: 'ios',
        ),
      if (sprint.buildAndroid == null)
        Divergence(
          kind: DivergenceKind.buildMissing,
          changeId: sprint.id,
          changeTitle: sprint.title,
          stack: 'android',
        ),
    ];
  }
}
