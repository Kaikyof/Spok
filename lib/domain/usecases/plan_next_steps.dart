import '../entities/slash_command.dart';
import '../entities/work_stage.dart';

/// Что предлагается после сессии: подпись выбирает presentation по виду.
enum NextStepKind { continuePlanning, apply, archive }

/// Следующий шаг по change'у: команда спеки с уже подставленным id.
class NextStep {
  final NextStepKind kind;
  final SlashCommand command;
  final String changeId;

  const NextStep(this.kind, this.command, this.changeId);

  /// Строка для ввода — вызов с change'ем, задание человек допишет сам.
  String get line => '${command.invocation} $changeId';
}

/// Следующий шаг после сессии по стадии её change'а. Команда берётся из
/// ролей спеки: нет команды на роль — нет и шага, выдумывать вызов за спеку
/// нельзя.
class PlanNextSteps {
  const PlanNextSteps();

  List<NextStep> call({required WorkStage stage, required String changeId, required List<SlashCommand> commands}) {
    final roles = resolveCommandRoles(commands);
    NextStep? step(NextStepKind kind, SlashCommand? command) =>
        command == null ? null : NextStep(kind, command, changeId);

    final next = switch (stage) {
      PlanningStage() => step(
        NextStepKind.continuePlanning,
        _continueCommand(commands) ?? roles[CommandRole.newChange],
      ),
      ReadyToApplyStage() || InProgressStage() => step(NextStepKind.apply, roles[CommandRole.apply]),
      DoneStage() => step(NextStepKind.archive, roles[CommandRole.archive]),
      ArchivedStage() => null,
    };
    return [?next];
  }

  /// Upstream продолжает планирование командой `continue` или `update`;
  /// скрипты сборки с похожим именем (`openspec:update`) — не она.
  SlashCommand? _continueCommand(List<SlashCommand> commands) => commands
      .where((command) => command.runLine.isEmpty)
      .where((command) => RegExp(r'(^|[:\-])(continue|update)$').hasMatch(command.id))
      .firstOrNull;
}
