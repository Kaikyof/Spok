import '../entities/change_unit.dart';
import '../entities/spec_schema.dart';
import '../entities/task_item.dart';
import '../entities/work_stage.dart';
import 'list_change_artifacts.dart';

/// Стадия работы change'а — чистая функция от его файлов, без сети.
///
/// Алгоритм тот же, что у готовности артефактов в `openspec status`:
/// артефакт «готов к написанию», когда все его `requires` написаны или
/// пропущены. Первый такой ненаписанный артефакт в порядке схемы даёт
/// `planning`; когда всё написано, стадию решают отметки задач.
class AssessWorkStage {
  const AssessWorkStage();

  /// Стадия change'а целиком. [tasks] — какие задачи считать; по умолчанию
  /// все задачи всех стеков. [stack] — считать стадию одного стека: тогда
  /// артефакты задач других стеков не ждут написания.
  WorkStage call(ChangeUnit change, SpecSchema schema, {Iterable<TaskItem>? tasks, String? stack}) {
    if (change.archived) return WorkStage.archived;
    final states = const ListChangeArtifacts()(change, schema);
    // Change редко трогает все стеки спеки: у backend-change'а не будет
    // `tasks_mobile.md`, и это не «планирование», а отсутствие работы по
    // стеку. Поэтому ненаписанный артефакт чужого стека не считается,
    // когда у change'а есть хотя бы один файл задач.
    final anyStackWritten = states.any((state) => state.artifact.stack.isNotEmpty && state.exists);
    for (final state in states) {
      if (state.exists || state.skipped || state.waitingFor.isNotEmpty) {
        continue;
      }
      final artifactStack = state.artifact.stack;
      if (artifactStack.isNotEmpty) {
        if (stack != null && artifactStack != stack) continue;
        if (stack == null && anyStackWritten) continue;
      }
      return PlanningStage(state.artifact.id);
    }
    return WorkStage.fromTasks(tasks ?? change.stacks.expand((unit) => unit.tasks));
  }
}
