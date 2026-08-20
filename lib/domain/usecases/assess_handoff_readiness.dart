import '../entities/change_unit.dart';
import '../entities/handoff_blocker.dart';
import '../entities/sprint.dart';
import '../entities/stack_state.dart';

/// Готовность спринта к передаче: каждый видимый стек change'а должен быть
/// в статусе «Ожидает тестирования» с закрытыми задачами, сборка — записана.
class AssessHandoffReadiness {
  static const _expectedStatus = 'Ожидает тестирования';

  HandoffReadiness call({
    required Sprint? sprint,
    required List<ChangeUnit> changes,
    required bool Function(String stack) stackVisible,
  }) {
    final stackEntries = [
      for (final change in changes)
        for (final stack in change.stacks)
          if (stackVisible(stack.stack)) (change: change, stack: stack),
    ];
    final blockers = [
      ...stackEntries.expand(_stackBlockers),
      ..._buildBlockers(sprint, stackEntries, stackVisible),
    ];
    final blockedPairs = {
      for (final blocker in blockers)
        if (blocker.kind != HandoffBlockerKind.buildMissing)
          '${blocker.changeTitle}/${blocker.stack}',
    };
    return HandoffReadiness(
      readyCount: stackEntries
          .where((entry) =>
              !blockedPairs.contains('${entry.change.title}/${entry.stack.stack}'))
          .length,
      totalCount: stackEntries.length,
      blockers: blockers,
    );
  }

  Iterable<HandoffBlocker> _stackBlockers(
      ({ChangeUnit change, StackState stack}) entry) sync* {
    final status = entry.stack.redmineStatus;
    if (status != null && status != _expectedStatus) {
      yield HandoffBlocker(
        kind: HandoffBlockerKind.statusNotReady,
        changeTitle: entry.change.title,
        stack: entry.stack.stack,
        status: status,
      );
    }
    if (entry.stack.openTasks.isNotEmpty) {
      yield HandoffBlocker(
        kind: HandoffBlockerKind.tasksOpen,
        changeTitle: entry.change.title,
        stack: entry.stack.stack,
        openTaskNumbers:
            entry.stack.openTasks.map((task) => task.number).toList(),
      );
    }
  }

  List<HandoffBlocker> _buildBlockers(
    Sprint? sprint,
    List<({ChangeUnit change, StackState stack})> stackEntries,
    bool Function(String stack) stackVisible,
  ) {
    if (sprint == null || stackEntries.isEmpty) return const [];
    return [
      if (stackVisible('ios') && sprint.buildIos == null)
        HandoffBlocker(
            kind: HandoffBlockerKind.buildMissing,
            changeTitle: sprint.title,
            stack: 'ios'),
      if (stackVisible('android') && sprint.buildAndroid == null)
        HandoffBlocker(
            kind: HandoffBlockerKind.buildMissing,
            changeTitle: sprint.title,
            stack: 'android'),
    ];
  }
}
