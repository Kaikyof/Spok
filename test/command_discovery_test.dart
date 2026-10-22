import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spok/data/sources/platform_files_source.dart';
import 'package:spok/domain/entities/slash_command.dart';

/// Откуда берутся команды спеки, как называется вызов, как склеиваются дубли
/// и где команда показывается (change `support-upstream-commands`).
void main() {
  late Directory root;

  void write(String relativePath, String content) {
    final file = File(p.join(root.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  String command(String name, String description, {String body = ''}) => '''
---
name: $name
description: $description
---

$body
''';

  List<SlashCommand> load() => PlatformFilesSource(root).loadSlashCommands();

  SlashCommand byId(String id) =>
      load().singleWhere((command) => command.id == id);

  setUp(() {
    root = Directory.systemTemp.createTempSync('command-discovery');
    write('openspec/config.yaml', 'schema: spec-driven\n');
  });

  tearDown(() => root.deleteSync(recursive: true));

  group('имя вызова', () {
    test('name: /opsx-apply у спеки команды — вызов тот же', () {
      write('.claude/commands/opsx-apply.md',
          command('/opsx-apply', 'Implement a change'));
      expect(load().single.invocation, '/opsx-apply');
    });

    test('name: OPSX: Propose — заголовок, вызов из пути', () {
      write('.claude/commands/opsx/propose.md',
          command('"OPSX: Propose"', 'Propose a new change'));
      expect(load().single.invocation, '/opsx:propose');
    });

    test('команда Cursor без .claude — вызов из имени файла', () {
      write('.cursor/commands/opsx-apply.md',
          command('/opsx-apply', 'Implement a change'));
      final apply = load().single;
      expect(apply.invocation, '/opsx-apply');
      expect(apply.source, CommandSource.mirror);
    });

    test('вызовом считается имя с / или без пробелов и заглавных', () {
      expect(PlatformFilesSource.looksLikeInvocation('/opsx-apply'), isTrue);
      expect(
          PlatformFilesSource.looksLikeInvocation('openspec-propose'), isTrue);
      expect(PlatformFilesSource.looksLikeInvocation('OPSX: Propose'), isFalse);
      expect(PlatformFilesSource.looksLikeInvocation(''), isFalse);
    });
  });

  group('дубли', () {
    const proposeSkill = 'Propose a new OpenSpec change. Also use when the '
        'user says "openspec propose" or "opsx propose".';

    test('пара скилл и команда — одна строка палитры', () {
      write('.claude/commands/opsx/propose.md',
          command('"OPSX: Propose"', 'Propose a new change'));
      write('.claude/skills/openspec-propose/SKILL.md',
          command('openspec-propose', '"$proposeSkill"'));
      final propose = load().single;
      expect(propose.invocation, '/opsx:propose');
      expect(propose.sources, [CommandSource.claude, CommandSource.skill]);
    });

    test('только скиллы — каждый остаётся командой', () {
      write('.claude/skills/openspec-propose/SKILL.md',
          command('openspec-propose', '"$proposeSkill"'));
      write(
          '.claude/skills/openspec-apply-change/SKILL.md',
          command('openspec-apply-change',
              '"Implement tasks. Also use when the user says "opsx apply"."'));
      // Справочник рядом со SKILL.md — не команда.
      write('.claude/skills/openspec-propose/references/notes.md',
          command('notes', 'Reference notes'));
      expect(load().map((command) => command.invocation),
          ['/openspec-apply-change', '/openspec-propose']);
    });

    test('проект для трёх инструментов — каждая команда один раз', () {
      for (final id in ['apply', 'propose']) {
        write('.claude/commands/opsx/$id.md',
            command('"OPSX: ${id.toUpperCase()}"', 'Run $id'));
        write('.cursor/commands/opsx-$id.md', command('/opsx-$id', 'Run $id'));
        write('.opencode/commands/opsx-$id.md', command('opsx-$id', 'Run $id'));
        write('.github/prompts/opsx-$id.prompt.md',
            command('opsx-$id', 'Run $id'));
      }
      write('.gemini/commands/opsx/apply.toml', 'description = "Run apply"\n');
      final commands = load();
      expect(commands.map((command) => command.invocation),
          ['/opsx:apply', '/opsx:propose']);
      // Источник — первый по приоритету каталог.
      expect(commands.map((command) => command.source).toSet(),
          {CommandSource.claude});
    });

    test('Copilot без других инструментов — .prompt.md читается как .md', () {
      write('.github/prompts/opsx-apply.prompt.md',
          command('opsx-apply', 'Run apply'));
      expect(load().single.invocation, '/opsx-apply');
    });

    test('спека команды: число и имена команд прежние', () {
      // Раскладка avtoto: канон в схеме, копии в .claude и .agents/skills,
      // свои скиллы в .claude/skills.
      write('openspec/config.yaml', 'schema: spec-driven-redmine\n');
      write('openspec/schemas/spec-driven-redmine/schema.yaml',
          'name: spec-driven-redmine\nartifacts: []\n');
      for (final id in ['apply', 'archive', 'propose', 'sprint']) {
        final body = command('/opsx-$id', 'Run $id');
        write('openspec/schemas/spec-driven-redmine/commands/opsx-$id.md',
            body);
        write('.claude/commands/opsx-$id.md', body);
        write('.agents/skills/opsx-$id/SKILL.md',
            command('opsx-$id', 'Run $id'));
      }
      for (final id in ['openspec-redmine-archive', 'openspec-spec-review']) {
        final body = command(id, 'Skill $id');
        write('.claude/skills/$id/SKILL.md', body);
        write('.agents/skills/$id/SKILL.md', body);
      }
      expect(load().map((command) => command.id), [
        'openspec-redmine-archive',
        'openspec-spec-review',
        'opsx-apply',
        'opsx-archive',
        'opsx-propose',
        'opsx-sprint',
      ]);
    });
  });

  group('применимость без argument-hint', () {
    test('команда создания change\'а — общее меню, не карточка', () {
      write(
          '.claude/commands/opsx/propose.md',
          command('"OPSX: Propose"', 'Propose a new change',
              body: '**Input**: The user\'s request should include a change '
                  'name (kebab-case) OR a description of what to build.'));
      final propose = load().single;
      expect(propose.argumentHint, isEmpty);
      expect(propose.scope, CommandScope.general);
    });

    test('команда реализации — карточка change\'а по роли', () {
      write(
          '.claude/commands/opsx/apply.md',
          command('"OPSX: Apply"', 'Implement tasks',
              body: '**Input**: Optionally specify a change name '
                  '(e.g., `/opsx:apply add-auth`).'));
      final apply = load().single;
      expect(apply.argumentHint, isEmpty);
      expect(apply.scope, CommandScope.change);
      expect(resolveCommandRoles([apply])[CommandRole.apply], apply);
    });

    test('строка вызова в кавычках и сигнатура скилла дают слоты', () {
      write(
          '.claude/commands/opsx-qa.md',
          command('/opsx-qa', 'QA',
              body: '**Input**: `/opsx:qa <change> <stack> testing|pass`'));
      write(
          '.claude/skills/openspec-redmine-sprint/SKILL.md',
          command('openspec-redmine-sprint', 'Sprint',
              body: '**Input**: `<sprint> <action>` where change\'s state '
                  'is read from Redmine.'));
      expect(byId('opsx-qa').argumentHint, '[change]');
      expect(byId('openspec-redmine-sprint').argumentHint, '[sprint]');
    });

    test('проза без строки вызова — только палитра', () {
      write(
          '.claude/commands/opsx/explore.md',
          command('"OPSX: Explore"', 'Explore',
              body: '**Input**: Whatever the user wants to think about, '
                  'or a change name.'));
      expect(load().single.scope, CommandScope.paletteOnly);
    });
  });

  group('роль архивирования', () {
    test('archive распознаётся, скилл уступает команде', () {
      const skill = SlashCommand(
          id: 'openspec-redmine-archive',
          description: 'Archive in Redmine',
          sources: [CommandSource.skill]);
      const archive = SlashCommand(id: 'opsx:archive', description: 'Archive');
      final roles = resolveCommandRoles([skill, archive]);
      expect(roles[CommandRole.archive], archive);
      expect(archive.scope, CommandScope.change);
    });

    test('sync роли не получает', () {
      const sync = SlashCommand(id: 'opsx:sync', description: 'Sync');
      expect(sync.role, isNull);
      expect(sync.scope, CommandScope.paletteOnly);
    });
  });
}
