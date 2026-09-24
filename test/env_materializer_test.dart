import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spok/data/sources/env_materializer.dart';
import 'package:spok/data/sources/platform_files_source.dart';
import 'package:spok/data/sources/secret_store.dart';

/// `.env` в клоне — производный файл: секреты живут в хранилище, а файл
/// собирается из них. Клон можно снести и склонировать заново.
void main() {
  late Directory spec;
  late Directory secretsDir;

  PlatformFilesSource source() => PlatformFilesSource(spec);

  EnvMaterializer materializer() =>
      EnvMaterializer(source(), secrets: SecretStore.inFile(secretsDir));

  void write(String relativePath, String content) {
    final file = File(p.join(spec.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  String envFile() {
    final file = File(p.join(spec.path, '.env'));
    return file.existsSync() ? file.readAsStringSync() : '';
  }

  setUp(() {
    spec = Directory.systemTemp.createTempSync('spok-spec');
    secretsDir = Directory.systemTemp.createTempSync('spok-secrets');
    write('.env.example', '''
REDMINE_URL=https://redmine.example.com
REDMINE_API_KEY=
GITLAB_TOKEN=
''');
  });

  tearDown(() {
    spec.deleteSync(recursive: true);
    secretsDir.deleteSync(recursive: true);
  });

  test('секреты из формы уходят в хранилище, несекретные — только в файл',
      () async {
    await materializer().save({
      'REDMINE_URL': 'https://redmine.example.com',
      'REDMINE_API_KEY': 'rm-key',
    });

    final store = SecretStore.inFile(secretsDir);
    expect(await store.read(SecretStore.account(spec.path, 'REDMINE_API_KEY')),
        'rm-key');
    expect(await store.read(SecretStore.account(spec.path, 'REDMINE_URL')),
        isNull);
    // Файл нужен скриптам спеки — секрет в нём тоже есть.
    expect(envFile(), contains('REDMINE_API_KEY=rm-key'));
    expect(envFile(), contains('REDMINE_URL=https://redmine.example.com'));
  });

  test('потерянный .env восстанавливается из хранилища', () async {
    await materializer().save({'GITLAB_TOKEN': 'glpat-1'});
    File(p.join(spec.path, '.env')).deleteSync();

    final result = await materializer().materialize();

    expect(envFile(), contains('GITLAB_TOKEN=glpat-1'));
    expect(result.restored, 1);
  });

  test('ключи, введённые до появления хранилища, переносятся в него', () async {
    write('.env', 'REDMINE_URL=https://redmine.example.com\n'
        'GITLAB_TOKEN=glpat-old\n');

    final result = await materializer().materialize();

    expect(result.imported, 1);
    expect(
        await SecretStore.inFile(secretsDir)
            .read(SecretStore.account(spec.path, 'GITLAB_TOKEN')),
        'glpat-old');
  });

  test('сборка не трогает чужие строки .env', () async {
    write('.env', '# комментарий спеки\n'
        'CUSTOM_FLAG=1\n'
        'GITLAB_TOKEN=\n');
    await materializer().save({'GITLAB_TOKEN': 'glpat-2'});

    expect(envFile(), contains('# комментарий спеки'));
    expect(envFile(), contains('CUSTOM_FLAG=1'));
    expect(envFile(), contains('GITLAB_TOKEN=glpat-2'));
  });

  test('forget убирает секреты спеки из хранилища', () async {
    await materializer().save({'GITLAB_TOKEN': 'glpat-3'});

    await materializer().forget();

    expect(
        await SecretStore.inFile(secretsDir)
            .read(SecretStore.account(spec.path, 'GITLAB_TOKEN')),
        isNull);
  });

  test('ключ, которого спека не объявила, тоже попадает в хранилище',
      () async {
    write('.env', 'MATTERMOST_BOT_TOKEN=bot-token\n');

    final result = await materializer().materialize();

    expect(result.imported, 1);
    expect(
        await SecretStore.inFile(secretsDir)
            .read(SecretStore.account(spec.path, 'MATTERMOST_BOT_TOKEN')),
        'bot-token');
  });
}
