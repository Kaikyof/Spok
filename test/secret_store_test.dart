import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spok/data/sources/secret_store.dart';
import 'package:spok/domain/entities/secret_backend.dart';

/// Связку ключей машины тесты не трогают: записи остались бы в ней после
/// прогона. Проверяем файловый вариант — тот самый, что достаётся Linux
/// без keyring-демона.
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('spok-secrets'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('значение возвращается тем же, каким записано', () async {
    final store = SecretStore.inFile(dir);
    await store.write('avtoto:GITLAB_TOKEN', 'glpat-XyZ-123');

    expect(await store.read('avtoto:GITLAB_TOKEN'), 'glpat-XyZ-123');
    expect(await store.backend(), SecretBackend.file);
  });

  test('секреты разных спек не сливаются в одну запись', () async {
    final store = SecretStore.inFile(dir);
    await store.write(SecretStore.account('/work/avtoto', 'GITLAB_TOKEN'), 'a');
    await store.write(SecretStore.account('/work/avelacom', 'GITLAB_TOKEN'), 'b');

    expect(await store.read(SecretStore.account('/work/avtoto', 'GITLAB_TOKEN')),
        'a');
    expect(
        await store.read(SecretStore.account('/work/avelacom', 'GITLAB_TOKEN')),
        'b');
  });

  test('пустое значение убирает запись: «ключ не заполнен» — это отсутствие',
      () async {
    final store = SecretStore.inFile(dir);
    await store.write('REDMINE_API_KEY', 'key');
    await store.write('REDMINE_API_KEY', '');

    expect(await store.read('REDMINE_API_KEY'), isNull);
  });

  test('значение не лежит в файле открытым текстом', () async {
    final store = SecretStore.inFile(dir);
    await store.write('GITLAB_TOKEN', 'glpat-secret-value');

    final content =
        File(p.join(dir.path, 'secrets.env')).readAsStringSync();
    expect(content, isNot(contains('glpat-secret-value')));
  });

  test('перенос строки внутри значения не ломает файл', () async {
    final store = SecretStore.inFile(dir);
    await store.write('SSH_PRIVATE_KEY', 'line one\nline two');
    await store.write('OTHER_TOKEN', 'plain');

    expect(await store.read('SSH_PRIVATE_KEY'), 'line one\nline two');
    expect(await store.read('OTHER_TOKEN'), 'plain');
  });

  test('запись переживает пересоздание хранилища', () async {
    await SecretStore.inFile(dir).write('REDMINE_API_KEY', 'abc');

    expect(await SecretStore.inFile(dir).read('REDMINE_API_KEY'), 'abc');
  });
}
