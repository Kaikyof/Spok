import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spok/data/sources/platform_files_source.dart';
import 'package:spok/data/repositories/platform_repository_impl.dart';
import 'package:spok/domain/entities/feature_gate.dart';
import 'package:spok/domain/entities/group.dart';
import 'package:spok/domain/entities/project_profile.dart';

/// Спека в стиле avelacom: схема со стеком backend, мастер-спека вместо
/// спринтов, redmine.yaml версии 3 с закэшированным статусом.
Directory _buildSpec() {
  final root = Directory.systemTemp.createTempSync('spec-discovery');
  void write(String relativePath, String content) {
    final file = File(p.join(root.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  write('workspace.yaml', '''
services:
  - name: odoo
    repo: git@gitlab.example.com:team/odoo.git
    ref: develop
''');
  write('.env.example', '''
# Redmine
REDMINE_URL=https://redmine.example.com
REDMINE_API_KEY=
REDMINE_PROJECT_ID=
# blob URL для ссылок
# OPENSPEC_REPO_URL=
''');
  write('openspec/config.yaml', 'schema: spec-driven-redmine\n');
  write('openspec/schemas/spec-driven-redmine/schema.yaml', '''
name: spec-driven-redmine
artifacts:
  - id: proposal
    generates: proposal.md
    requires: []
  - id: specs
    generates: "specs/**/*.md"
    requires:
      - proposal
  - id: tasks-backend
    generates: tasks_backend.md
    requires:
      - specs
  - id: tasks-mobile
    generates: tasks_mobile.md
    requires:
      - specs
apply:
  instruction: |
    3. Branches: `git fetch && git checkout -B features/<change-name>`
''');
  write('openspec/redmine.yaml', '''
sync:
  on_dev_start_status_id: 2
  on_mr_open_status_id: 12
  on_change_complete_status_id: 16
statuses:
  - id: 2
    name: В работе
    closing: false
    completes_task: false
  - id: 11
    name: Ожидает тестирования
    closing: false
    completes_task: false
  - id: 12
    name: На ревью
    closing: false
    completes_task: false
  - id: 16
    name: Выполнено
    closing: true
    completes_task: true
''');
  write('openspec/doc/master-block.md',
      '# master-block — Большой блок: master-spec\n\nchanges: `alpha-change`\n');
  write('openspec/changes/alpha-change/proposal.md', '# Альфа\n');
  write('openspec/changes/alpha-change/tasks_backend.md', '''
- [x] 1.1 Первая
- [ ] 1.2 Вторая
''');
  write('openspec/changes/alpha-change/redmine.yaml', '''
version: 3
change: alpha-change
stacks:
  root:
    issue_id: null
  backend:
    issue_id: 63637
    status_id: 12
    status_name: На ревью
group:
  members:
    - alpha-change
  parent_issue_id: 63368
  issue_id: 63637
''');
  return root;
}

void main() {
  late Directory root;
  late PlatformFilesSource source;

  setUp(() {
    root = _buildSpec();
    source = PlatformFilesSource(root);
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('стеки и имена файлов берутся из схемы, а не из ios/android', () {
    expect(source.loadSchema().stacks, ['backend', 'mobile']);
    expect(source.loadSchema().tasksFileFor('backend'), 'tasks_backend.md');
  });

  test('имя ветки change’а читается из apply.instruction схемы', () {
    expect(source.loadSchema().branchFor('alpha-change'),
        'features/alpha-change');
  });

  test('change получает стек из схемы и статус из кэша redmine.yaml', () {
    final change = source.loadChanges().single;
    final backend = change.stack('backend')!;
    expect(change.stacks.map((stack) => stack.stack), ['backend']);
    expect(backend.issueId, 63637);
    expect(backend.redmineStatus, 'На ревью');
    expect(backend.statusFromCache, isTrue);
    expect(backend.doneCount, 1);
    expect(backend.tasks.length, 2);
    expect(change.formatWarning, isEmpty);
  });

  test('мастер-спека становится группой, change виден по упоминанию в тексте',
      () {
    final groups = source.loadGroups(source.loadChanges());
    expect(groups.single.kind, GroupingKind.masterDoc);
    expect(groups.single.id, 'master-block');
    expect(groups.single.title, 'Большой блок');
    expect(groups.single.changeIds, ['alpha-change']);
  });

  test('семантика статусов читается из openspec/redmine.yaml', () {
    final semantics = source.loadStatusSemantics();
    expect(semantics.workingStatuses, contains('В работе'));
    expect(semantics.handoffStatus, 'Ожидает тестирования');
    expect(semantics.completeStatus, 'Выполнено');
    expect(semantics.closingStatuses, {'Выполнено'});
  });

  test('ключи окружения берутся из .env.example целиком', () {
    final keys = source.loadEnvExampleKeys();
    expect(keys.map((key) => key.key),
        ['REDMINE_URL', 'REDMINE_API_KEY', 'REDMINE_PROJECT_ID',
         'OPENSPEC_REPO_URL']);
    // Закомментированный ключ — необязательный, а не отсутствующий.
    expect(keys.last.optional, isTrue);
    expect(keys.first.hint, 'Redmine');
  });

  test('.env пишется поверх, сохраняя чужие строки и комментарии', () async {
    File(p.join(root.path, '.env')).writeAsStringSync('''
# личные ключи
REDMINE_URL=https://old.example.com
CUSTOM_KEY=оставить
REDMINE_PROJECT_ID=319
''');
    await source.writeEnv({
      'REDMINE_URL': 'https://new.example.com',
      'REDMINE_API_KEY': 'секрет',
      // Пустое значение убирает ключ, а не пишет «KEY=».
      'REDMINE_PROJECT_ID': '',
    });
    final lines = File(p.join(root.path, '.env')).readAsLinesSync();
    expect(lines, contains('# личные ключи'));
    expect(lines, contains('REDMINE_URL=https://new.example.com'));
    expect(lines, contains('CUSTOM_KEY=оставить'));
    expect(lines, contains('REDMINE_API_KEY=секрет'));
    expect(lines.where((line) => line.startsWith('REDMINE_PROJECT_ID')),
        isEmpty);
    expect(source.loadEnv()['REDMINE_URL'], 'https://new.example.com');
  });

  test('требования фич собираются явно: что есть, чего нет и где искали',
      () async {
    final snapshot = await PlatformRepositoryImpl(source).load();
    final profile = snapshot.profile;

    // Передача: группировка и статусы есть, а команды передачи у спеки
    // нет — передавать нечем, и фича выключена с объяснением.
    final handoff = profile.gate(SpecFeature.handoff);
    expect(handoff.available, isFalse);
    expect(handoff.blocker?.id, RequirementId.handoverCommand);
    expect(handoff.blocker?.scope, RequirementScope.spec);
    expect(handoff.unmetCount, 3);
    // Сборки и получатели — необязательные: без них шаги гаснут, но
    // передача остаётся возможной.
    expect(
        handoff.optional
            .where((requirement) => !requirement.satisfied)
            .map((requirement) => requirement.id),
        containsAll([
          RequirementId.buildsFile,
          RequirementId.recipientsScript,
        ]));
    expect(profile.handoverCommand, isNull);

    // MR: спека не объявила GITLAB_TOKEN — это нехватка на стороне спеки,
    // а не «не настроено у меня».
    final mr = profile.gate(SpecFeature.mergeRequests);
    expect(mr.available, isFalse);
    expect(mr.blocker?.id, RequirementId.gitlabTokenDeclared);
    expect(mr.blocker?.scope, RequirementScope.spec);
    expect(mr.blocker?.lookedIn, contains('.env.example'));
  });

  test('команда передачи в спеке включает передачу и попадает в профиль',
      () async {
    final file = File(p.join(root.path, '.claude/commands/opsx-sprint.md'));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('''
---
id: opsx-sprint
description: Sprint level — status, batch handover to the tester
argument-hint: [sprint] [status|build|handover|finish] [--stack backend]
---
''');
    final profile = (await PlatformRepositoryImpl(source).load()).profile;

    expect(profile.gate(SpecFeature.handoff).available, isTrue);
    expect(profile.handoverCommand?.id, 'opsx-sprint');
  });

  test('заполненный ключ переводит нехватку из «у спеки» в «у меня»',
      () async {
    File(p.join(root.path, '.env.example'))
        .writeAsStringSync('GITLAB_TOKEN=\nREDMINE_URL=\n');
    final profile = (await PlatformRepositoryImpl(source).load()).profile;
    final mr = profile.gate(SpecFeature.mergeRequests);
    expect(mr.blocker?.id, RequirementId.gitlabTokenFilled);
    expect(mr.blocker?.scope, RequirementScope.personal);
  });

  test('неизвестная версия redmine.yaml помечается, а не молчит', () {
    File(p.join(root.path, 'openspec/changes/alpha-change/redmine.yaml'))
        .writeAsStringSync('version: 9\nstacks: {}\n');
    expect(source.loadChanges().single.formatWarning, contains('version 9'));
  });
}
