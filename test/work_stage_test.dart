import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spok/domain/entities/change_metadata.dart';
import 'package:spok/domain/entities/change_unit.dart';
import 'package:spok/domain/entities/spec_schema.dart';
import 'package:spok/domain/entities/stack_state.dart';
import 'package:spok/domain/entities/task_item.dart';
import 'package:spok/domain/entities/work_stage.dart';
import 'package:spok/domain/usecases/assess_work_stage.dart';

/// Схема upstream `spec-driven` в части зависимостей: specs и design
/// требуют proposal, tasks — specs и design.
const _specDriven = SpecSchema(
  name: 'spec-driven',
  artifacts: [
    SchemaArtifact(id: 'proposal', generates: 'proposal.md'),
    SchemaArtifact(id: 'specs', generates: 'specs/**/*.md', requires: ['proposal']),
    SchemaArtifact(id: 'design', generates: 'design.md', requires: ['proposal']),
    SchemaArtifact(id: 'tasks', generates: 'tasks.md', requires: ['specs', 'design']),
  ],
  tracksFile: 'tasks.md',
);

/// Стадия работы из файлов change'а — сценарии спецификации `work-stage`.
void main() {
  late Directory root;

  void write(String relativePath, String content) {
    final file = File(p.join(root.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  setUp(() {
    root = Directory.systemTemp.createTempSync('work-stage');
  });

  tearDown(() => root.deleteSync(recursive: true));

  ChangeUnit change({
    List<TaskItem> tasks = const [],
    ChangeMetadata meta = ChangeMetadata.none,
    DateTime? archivedAt,
  }) => ChangeUnit(
    id: 'a',
    title: 'A',
    dir: root.path,
    stackStates: {StackState.singleWorkStack: StackState(stack: StackState.singleWorkStack, tasks: tasks)},
    meta: meta,
    archivedAt: archivedAt,
  );

  const assess = AssessWorkStage();

  test('планирование: есть proposal, нет design, specs и tasks — '
      'следующий артефакт specs, первый готовый в порядке схемы', () {
    write('proposal.md', '## Why\n');

    expect(assess(change(), _specDriven), const PlanningStage('specs'));
  });

  test('в работе: все артефакты написаны, закрыты 3 задачи из 7', () {
    write('proposal.md', '## Why\n');
    write('specs/auth/spec.md', '## ADDED Requirements\n');
    write('design.md', '## Context\n');
    write('tasks.md', '## 1\n');
    final tasks = [for (var index = 1; index <= 7; index++) TaskItem('1.$index', 'Шаг', index <= 3)];

    expect(assess(change(tasks: tasks), _specDriven), const InProgressStage(3, 7));
  });

  test('сделано: все артефакты написаны и все задачи закрыты', () {
    write('proposal.md', '## Why\n');
    write('specs/auth/spec.md', '## ADDED Requirements\n');
    write('design.md', '## Context\n');
    write('tasks.md', '## 1\n');
    final tasks = const [TaskItem('1.1', 'Шаг', true), TaskItem('1.2', 'Шаг', true)];

    expect(assess(change(tasks: tasks), _specDriven), WorkStage.done);
  });

  test('пропущенные спецификации не мешают: proposal, design, tasks '
      'при skip_specs — готов к реализации', () {
    write('proposal.md', '## Why\n');
    write('design.md', '## Context\n');
    write('tasks.md', '## 1\n');
    final unit = change(tasks: const [TaskItem('1.1', 'Шаг', false)], meta: const ChangeMetadata(skipSpecs: true));

    expect(assess(unit, _specDriven), WorkStage.readyToApply);
  });

  test('ни одной задачи не закрыто — готов к реализации, а не в работе', () {
    write('proposal.md', '## Why\n');
    write('specs/auth/spec.md', '## ADDED Requirements\n');
    write('design.md', '## Context\n');
    write('tasks.md', '## 1\n');

    expect(assess(change(), _specDriven), WorkStage.readyToApply);
  });

  test('архив решает всё: даже с открытыми задачами стадия — в архиве', () {
    final unit = change(tasks: const [TaskItem('1.1', 'Шаг', false)], archivedAt: DateTime(2026, 9, 1));

    expect(assess(unit, _specDriven), WorkStage.archived);
  });

  test('два артефакта готовы одновременно — берётся первый по схеме', () {
    // design объявлен раньше specs, и оба требуют только proposal.
    const schema = SpecSchema(
      name: 's',
      artifacts: [
        SchemaArtifact(id: 'proposal', generates: 'proposal.md'),
        SchemaArtifact(id: 'design', generates: 'design.md', requires: ['proposal']),
        SchemaArtifact(id: 'specs', generates: 'specs/**/*.md', requires: ['proposal']),
      ],
    );
    write('proposal.md', '## Why\n');

    expect(assess(change(), schema), const PlanningStage('design'));
  });

  test('артефакт, который ждёт предшественника, планированием не считается', () {
    // Ничего не написано: tasks ждёт specs и design, они ждут proposal —
    // следующий шаг proposal, а не tasks.
    expect(assess(change(), _specDriven), const PlanningStage('proposal'));
  });

  group('стеки', () {
    const stacked = SpecSchema(
      name: 'two',
      artifacts: [
        SchemaArtifact(id: 'proposal', generates: 'proposal.md'),
        SchemaArtifact(id: 'tasks-backend', generates: 'tasks_backend.md', requires: ['proposal']),
        SchemaArtifact(id: 'tasks-mobile', generates: 'tasks_mobile.md', requires: ['proposal']),
      ],
    );

    test('change одного стека: файл задач другого стека не ждём', () {
      write('proposal.md', '# A\n');
      write('tasks_backend.md', '- [x] 1.1\n- [ ] 1.2\n');
      final unit = ChangeUnit(
        id: 'a',
        title: 'A',
        dir: root.path,
        stackStates: {
          'backend': StackState(
            stack: 'backend',
            tasks: const [TaskItem('1.1', 'Шаг', true), TaskItem('1.2', 'Шаг', false)],
          ),
        },
      );

      expect(assess(unit, stacked), const InProgressStage(1, 2));
      expect(assess(unit, stacked, stack: 'backend', tasks: unit.stack('backend')!.tasks), const InProgressStage(1, 2));
    });

    test('файлов задач нет вовсе — планирование первого стека', () {
      write('proposal.md', '# A\n');
      final unit = ChangeUnit(id: 'a', title: 'A', dir: root.path);

      expect(assess(unit, stacked), const PlanningStage('tasks-backend'));
    });
  });

  test('порядок стадий — по ходу работы', () {
    expect(
      [
        WorkStage.archived,
        WorkStage.done,
        const InProgressStage(1, 2),
        WorkStage.readyToApply,
        const PlanningStage('specs'),
      ].map((stage) => stage.rank),
      [4, 3, 2, 1, 0],
    );
  });
}
