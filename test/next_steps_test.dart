import 'package:flutter_test/flutter_test.dart';
import 'package:spok/domain/entities/agent_session.dart';
import 'package:spok/domain/entities/slash_command.dart';
import 'package:spok/domain/entities/work_stage.dart';
import 'package:spok/domain/usecases/plan_next_steps.dart';
import 'package:spok/presentation/bloc/sessions_bloc.dart';

/// Следующие шаги после сессии — по стадии её change'а
/// (change `support-upstream-commands`, задача 3.1).
void main() {
  // Команды, как их генерирует upstream: сигнатур нет, роли — по имени.
  const upstream = [
    SlashCommand(id: 'opsx:apply', description: 'Implement tasks'),
    SlashCommand(id: 'opsx:archive', description: 'Archive a change'),
    SlashCommand(id: 'opsx:propose', description: 'Propose a change'),
    SlashCommand(id: 'opsx:update', description: 'Update a change'),
  ];
  const plan = PlanNextSteps();

  List<String> lines(WorkStage stage, [List<SlashCommand> commands = upstream]) => [
    for (final step in plan(stage: stage, changeId: 'add-dark-mode', commands: commands))
      '${step.kind.name} ${step.line}',
  ];

  test('завершённая сессия по сделанному change\'у — архивировать', () {
    expect(lines(WorkStage.done), ['archive /opsx:archive add-dark-mode']);
  });

  test('планирование — продолжить командой update, без неё — propose', () {
    expect(lines(const PlanningStage('design')), ['continuePlanning /opsx:update add-dark-mode']);
    final withoutUpdate = upstream.where((command) => command.id != 'opsx:update').toList();
    expect(lines(const PlanningStage('design'), withoutUpdate), ['continuePlanning /opsx:propose add-dark-mode']);
  });

  test('готов к реализации или в работе — реализовать', () {
    expect(lines(WorkStage.readyToApply), ['apply /opsx:apply add-dark-mode']);
    expect(lines(const InProgressStage(1, 3)), ['apply /opsx:apply add-dark-mode']);
  });

  test('нет команды на роль или change в архиве — шага нет', () {
    expect(lines(WorkStage.done, const [SlashCommand(id: 'opsx:apply', description: '')]), isEmpty);
    expect(lines(WorkStage.archived), isEmpty);
  });

  test('скрипт openspec:update не считается продолжением планирования', () {
    const commands = [
      SlashCommand(id: 'opsx-propose', description: ''),
      SlashCommand(
        id: 'openspec:update',
        description: '',
        sources: [CommandSource.packageScript],
        runLine: 'pnpm openspec:update',
      ),
    ];
    expect(lines(const PlanningStage('design'), commands), ['continuePlanning /opsx-propose add-dark-mode']);
  });

  test('change сессии — аргумент первой реплики, совпавший с id', () {
    const state = SessionsState(changeIds: ['add-dark-mode', 'refactor-config']);
    AgentSession session(String title) =>
        AgentSession(id: '1', title: title, startedAt: DateTime(2026), model: 'sonnet', effort: AgentEffort.medium);

    expect(state.changeOf(session('/opsx:apply add-dark-mode и тесты')), 'add-dark-mode');
    expect(state.changeOf(session('почини add-dark-mode')), 'add-dark-mode');
    expect(state.changeOf(session('/opsx:propose новая фича')), isNull);
  });
}
