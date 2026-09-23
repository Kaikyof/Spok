import '../entities/change_unit.dart';
import '../entities/divergence.dart';
import '../entities/group.dart';
import '../entities/stack_state.dart';
import '../entities/status_semantics.dart';

/// Правила расхождений: сравнение ярлыка (трекер) с фактом (файлы, сборки).
/// Смысл статусов берётся из `openspec/redmine.yaml` спеки, а не из строк
/// в коде: у каждой команды свой набор статусов.
class FindDivergences {
  List<Divergence> call(
    Group? group,
    List<ChangeUnit> changes,
    StatusSemantics semantics,
  ) {
    if (semantics.isEmpty) return const [];
    final working = semantics.workingStatuses;
    final closed = semantics.testingStatuses.union(semantics.closingStatuses);
    final stackEntries = [
      for (final change in changes)
        for (final stack in change.stacks) (change: change, stack: stack),
    ];
    return [
      ...stackEntries
          .map((entry) => _checkStack(entry, working, closed))
          .nonNulls,
      ..._checkBuilds(group, changes, semantics),
    ];
  }

  Divergence? _checkStack(
    ({ChangeUnit change, StackState stack}) entry,
    Set<String> workingStatuses,
    Set<String> closedStatuses,
  ) {
    final stack = entry.stack;
    final status = stack.redmineStatus;
    if (status == null || stack.tasks.isEmpty) return null;

    if (stack.allDone && workingStatuses.contains(status)) {
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
    if (!stack.allDone && closedStatuses.contains(status)) {
      return Divergence(
        kind: DivergenceKind.tasksNotClosed,
        changeId: entry.change.id,
        changeTitle: entry.change.title,
        stack: stack.stack,
        redmineStatus: status,
        openTaskNumbers: stack.openTasks.map((task) => task.number).toList(),
      );
    }
    return null;
  }

  /// Сборка нужна там, где спека её ведёт: есть builds.yaml группы.
  /// Нет файла сборок — нет и правила, а не вечное «сборка не записана».
  List<Divergence> _checkBuilds(
      Group? group, List<ChangeUnit> changes, StatusSemantics semantics) {
    if (group == null || group.builds.isEmpty) return const [];
    final handoffStatus = semantics.handoffStatus;
    final waitingStacks = {
      for (final change in changes)
        for (final stack in change.stacks)
          if (stack.redmineStatus == handoffStatus) stack.stack,
    };
    return [
      for (final stack in waitingStacks)
        if (group.buildFor(stack) == null)
          Divergence(
            kind: DivergenceKind.buildMissing,
            changeId: group.id,
            changeTitle: group.title,
            stack: stack,
          ),
    ];
  }
}
