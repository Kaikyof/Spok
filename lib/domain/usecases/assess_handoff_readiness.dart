import '../entities/change_unit.dart';
import '../entities/group.dart';
import '../entities/handoff_blocker.dart';
import '../entities/stack_state.dart';
import '../entities/status_semantics.dart';

/// Готовность группы к передаче: каждый видимый стек change'а должен быть
/// в статусе передачи с закрытыми задачами, сборка — записана.
/// Статус передачи объявляет спека (`openspec/redmine.yaml`).
class AssessHandoffReadiness {
  HandoffReadiness call({
    required Group? group,
    required List<ChangeUnit> changes,
    required StatusSemantics semantics,
    required bool Function(String stack) stackVisible,
  }) {
    final expectedStatus = semantics.handoffStatus;
    final stackEntries = [
      for (final change in changes)
        for (final stack in change.stacks)
          if (stackVisible(stack.stack)) (change: change, stack: stack),
    ];
    final blockers = [
      for (final entry in stackEntries)
        ..._stackBlockers(entry, expectedStatus),
      ..._buildBlockers(group, stackEntries, stackVisible),
    ];
    final blockedPairs = {
      for (final blocker in blockers)
        if (blocker.kind != HandoffBlockerKind.buildMissing)
          '${blocker.changeTitle}/${blocker.stack}',
    };
    return HandoffReadiness(
      readyCount: stackEntries
          .where((entry) => !blockedPairs
              .contains('${entry.change.title}/${entry.stack.stack}'))
          .length,
      totalCount: stackEntries.length,
      blockers: blockers,
    );
  }

  Iterable<HandoffBlocker> _stackBlockers(
      ({ChangeUnit change, StackState stack}) entry,
      String? expectedStatus) sync* {
    final status = entry.stack.redmineStatus;
    if (expectedStatus != null && status != null && status != expectedStatus) {
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

  /// Сборки требуются только там, где спека их ведёт (builds.yaml группы).
  List<HandoffBlocker> _buildBlockers(
    Group? group,
    List<({ChangeUnit change, StackState stack})> stackEntries,
    bool Function(String stack) stackVisible,
  ) {
    if (group == null || group.builds.isEmpty || stackEntries.isEmpty) {
      return const [];
    }
    final stacks = {for (final entry in stackEntries) entry.stack.stack};
    return [
      for (final stack in stacks)
        if (stackVisible(stack) && group.buildFor(stack) == null)
          HandoffBlocker(
              kind: HandoffBlockerKind.buildMissing,
              changeTitle: group.title,
              stack: stack),
    ];
  }
}
