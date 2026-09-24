import 'package:flutter_test/flutter_test.dart';
import 'package:spok/data/sources/env_file.dart';
import 'package:spok/domain/entities/env_task.dart';
import 'package:spok/domain/entities/slash_command.dart';
import 'package:spok/domain/usecases/find_env_commands.dart';

void main() {
  group('Разбор .env', () {
    test('ключи и значения берутся построчно, комментарии пропускаются', () {
      final values = EnvFile.parse('''
# Redmine
REDMINE_URL=https://r.webant.ru
REDMINE_API_KEY=abc123

# OPENSPEC_REPO_URL=https://example.com
''');

      expect(values, {
        'REDMINE_URL': 'https://r.webant.ru',
        'REDMINE_API_KEY': 'abc123',
      });
    });

    test('кавычки снимаются, а решётка внутри них остаётся частью пароля',
        () {
      final values = EnvFile.parse('''
A="значение с пробелом"
B='pa#ss'
C=plain # это примечание
''');

      expect(values['A'], 'значение с пробелом');
      expect(values['B'], 'pa#ss');
      expect(values['C'], 'plain');
    });

    test('строка с export — тот же ключ, а мусор пропускается молча', () {
      final values = EnvFile.parse('export TOKEN=xyz\nпросто текст\n');

      expect(values, {'TOKEN': 'xyz'});
    });
  });

  group('Команда спеки для раздела окружения', () {
    const find = FindEnvCommands();

    SlashCommand script(String id, String runLine) => SlashCommand(
        id: id,
        description: '',
        source: CommandSource.packageScript,
        runLine: runLine);

    test('репозитории лечит команда инициализации workspace', () {
      final found = find([
        script('workspace:init', 'pnpm workspace:init'),
        script('workspace:verify', 'pnpm workspace:verify'),
      ]);

      expect(found[EnvTask.repos]?.id, 'workspace:init');
      expect(found[EnvTask.systems]?.id, 'workspace:verify');
    });

    test('в разделе ключей workspace-init не предлагается: он о другом', () {
      final found = find([script('workspace:init', 'pnpm workspace:init')]);

      expect(found[EnvTask.keys], isNull);
    });

    test('команда про env попадает именно в раздел ключей', () {
      final found = find([
        script('env:sync', 'pnpm env:sync'),
        script('workspace:init', 'pnpm workspace:init'),
      ]);

      expect(found[EnvTask.keys]?.id, 'env:sync');
      expect(found[EnvTask.repos]?.id, 'workspace:init');
    });

    test('спека без таких команд не получает ни одной кнопки', () {
      final found = find(const [
        SlashCommand(id: 'opsx-propose', description: '', argumentHint: '[change]'),
      ]);

      expect(found, isEmpty);
    });

    test('выполнимая цель Makefile выигрывает у агентной команды', () {
      final found = find(const [
        SlashCommand(
            id: 'opsx-workspace-init',
            description: '',
            argumentHint: '[group]'),
        SlashCommand(
            id: 'workspace-init',
            description: '',
            source: CommandSource.makeTarget,
            runLine: 'make workspace-init'),
      ]);

      expect(found[EnvTask.repos]?.runLine, 'make workspace-init');
    });
  });
}
