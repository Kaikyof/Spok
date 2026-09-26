import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spok/data/sources/platform_files_source.dart';
import 'package:spok/domain/entities/stack_state.dart';

/// Файл задач и отметки — по правилам upstream. Сценарии — из
/// спецификации `task-tracking` change'а `resolve-schema-like-upstream`.
void main() {
  late Directory root;

  void write(String relativePath, String content) {
    final file = File(p.join(root.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  setUp(() {
    root = Directory.systemTemp.createTempSync('task-tracking');
    write('openspec/config.yaml', 'schema: spec-driven\n');
  });

  tearDown(() => root.deleteSync(recursive: true));

  StackState singleStack() {
    final change = PlatformFilesSource(root).loadChanges().single;
    return change.stack(StackState.singleWorkStack)!;
  }

  test('проект на схеме spec-driven: одна единица работы 2/3 без трекера', () {
    write('openspec/changes/a/proposal.md', '## Why\n');
    write('openspec/changes/a/tasks.md', '''
- [x] 1.1 Первая
- [x] 1.2 Вторая
- [ ] 1.3 Третья
''');
    final stack = singleStack();
    expect(stack.doneCount, 2);
    expect(stack.tasks.length, 3);
    expect(stack.issueId, isNull);
    expect(stack.redmineStatus, isNull);
  });

  test('список через звёздочку, вложенность, чужая отметка, ссылка', () {
    write('openspec/changes/a/tasks.md', '''
* [X] Первая
  - [ ] 1.2 Вторая
- [~] Третья
- [Документ](./doc.md)
- [Ссылка][ref]
''');
    final tasks = singleStack().tasks;
    expect(tasks.map((task) => task.title), ['Первая', 'Вторая', 'Третья']);
    expect(tasks.map((task) => task.done), [true, false, false]);
    // Номер из текста, иначе порядковый по файлу.
    expect(tasks.map((task) => task.number), ['1', '1.2', '3']);
  });

  test('формы отметок: [ x], [], [x]без пробела, нумерованный список', () {
    write('openspec/changes/a/tasks.md', '''
- [ x] Отступ внутри — сделано
- [] Пустые скобки — не сделано
- [x]сразу текст
1. [X] 2.1 Нумерованный маркер
2) [ ] 2.2 Скобка-маркер
+ [x] Плюс
''');
    final tasks = singleStack().tasks;
    expect(tasks.length, 6);
    expect(tasks.map((task) => task.done), [
      true,
      false,
      true,
      true,
      false,
      true,
    ]);
    expect(tasks[3].number, '2.1');
    expect(tasks[3].title, 'Нумерованный маркер');
  });

  test('номер с буквой ревизии — тоже номер, не порядковый', () {
    write('openspec/changes/a/tasks.md', '''
- [x] 2.3 Основная
- [x] 2.3a (ревизия заказчика) Дополнение
- [ ] 2.3b Ещё одно
''');
    final tasks = singleStack().tasks;
    expect(tasks.map((task) => task.number), ['2.3', '2.3a', '2.3b']);
    expect(tasks[1].title, '(ревизия заказчика) Дополнение');
  });

  test('CRLF: задачи посчитаны, текст без \\r', () {
    write(
      'openspec/changes/a/tasks.md',
      '- [x] 1.1 Первая\r\n- [ ] 1.2 Вторая\r\n',
    );
    final tasks = singleStack().tasks;
    expect(tasks.length, 2);
    expect(tasks.last.title, 'Вторая');
  });

  test('пустой tasks.md — единица работы есть, задач 0', () {
    write('openspec/changes/a/tasks.md', '# Tasks\n');
    final stack = singleStack();
    expect(stack.tasks, isEmpty);
  });

  test('спека без конфига и с tasks_ios.md — запасная маска работает', () {
    File(p.join(root.path, 'openspec/config.yaml')).deleteSync();
    write('openspec/changes/a/tasks_ios.md', '- [ ] 1.1 Экран\n');
    final change = PlatformFilesSource(root).loadChanges().single;
    expect(change.stacks.single.stack, 'ios');
  });

  test('стеки схемы читаются как прежде', () {
    write('openspec/config.yaml', 'schema: two\n');
    write('openspec/schemas/two/schema.yaml', '''
name: two
artifacts:
  - id: tasks-ios
    generates: tasks_ios.md
  - id: tasks-android
    generates: tasks_android.md
''');
    write('openspec/changes/a/tasks_ios.md', '- [ ] 1.1 Экран\n');
    write('openspec/changes/a/tasks_android.md', '- [x] 1.1 Экран\n');
    final change = PlatformFilesSource(root).loadChanges().single;
    expect(change.stacks.map((stack) => stack.stack), ['ios', 'android']);
  });
}
