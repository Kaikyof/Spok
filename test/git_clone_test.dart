import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spok/data/sources/git_clone_source.dart';
import 'package:spok/domain/entities/clone_progress.dart';

/// Клонирование проверяется на локальном репозитории: сеть в тесте не
/// нужна, а весь путь — запуск git, чтение его вывода, разбор ошибок
/// и уборка за собой — тот же самый.
Directory _sourceRepo() {
  final dir = Directory.systemTemp.createTempSync('spok-origin');
  void git(List<String> arguments) {
    final result = Process.runSync('git', [
      '-c', 'user.email=test@example.com',
      '-c', 'user.name=Test',
      '-C', dir.path,
      ...arguments,
    ]);
    if (result.exitCode != 0) {
      throw StateError('git ${arguments.first}: ${result.stderr}');
    }
  }

  git(['init', '--quiet']);
  File(p.join(dir.path, 'workspace.yaml')).writeAsStringSync('services: []\n');
  git(['add', '.']);
  git(['commit', '--quiet', '-m', 'первый коммит']);
  return dir;
}

void main() {
  group('Адрес спеки', () {
    test('git-адрес отличается от локального пути', () {
      expect(
          GitCloneSource.looksLikeUrl('git@gitlab.example.com:team/spec.git'),
          isTrue);
      expect(GitCloneSource.looksLikeUrl('https://gitlab.example.com/t/s.git'),
          isTrue);
      expect(GitCloneSource.looksLikeUrl('ssh://git@host/team/spec'), isTrue);
      expect(GitCloneSource.looksLikeUrl('/Users/me/avelacom-platform'),
          isFalse);
      expect(GitCloneSource.looksLikeUrl('  ~/specs/avtoto  '), isFalse);
    });

    test('имя каталога берётся из адреса', () {
      expect(GitCloneSource.slugOf('git@host:team/avelacom-platform.git'),
          'avelacom-platform');
      expect(GitCloneSource.slugOf('https://host/team/avtoto-platform/'),
          'avtoto-platform');
    });
  });

  group('Разбор ошибок git', () {
    test('нет ssh-ключа', () {
      expect(
          GitCloneSource.classify(
              'git@gitlab.example.com: Permission denied (publickey).'),
          CloneFailure.accessDenied);
    });

    test('логин или токен не приняты', () {
      expect(
          GitCloneSource.classify(
              "fatal: Authentication failed for 'https://host/t/s.git/'"),
          CloneFailure.authFailed);
    });

    test('каталог занят', () {
      expect(
          GitCloneSource.classify("fatal: destination path 'spec' already "
              'exists and is not an empty directory.'),
          CloneFailure.directoryInUse);
    });

    test('репозитория нет', () {
      expect(GitCloneSource.classify('remote: Repository not found.'),
          CloneFailure.repoNotFound);
    });

    test('сети нет', () {
      expect(
          GitCloneSource.classify(
              'fatal: unable to access: Could not resolve host: gitlab.example.com'),
          CloneFailure.networkUnreachable);
    });

    test('незнакомая ошибка остаётся незнакомой, а не выдаётся за чужую', () {
      expect(GitCloneSource.classify('fatal: странная беда'),
          CloneFailure.unknown);
    });
  });

  group('Разбор строк прогресса', () {
    test('проценты и объём берутся у скачивания', () {
      final progress = GitCloneSource.applyProgressLine(
        CloneProgress.idle,
        'Receiving objects:  45% (1215/2700), 12.34 MiB | 3.20 MiB/s',
      );

      expect(progress.phase, ClonePhase.receiving);
      expect(progress.fraction, closeTo(0.45, 0.001));
      expect(progress.volume, '12.34 MiB');
      expect(progress.speed, '3.20 MiB/s');
    });

    test('у остальных этапов своя шкала — полоса не скачет назад', () {
      var progress = GitCloneSource.applyProgressLine(CloneProgress.idle,
          'Receiving objects: 100% (2700/2700), 40.00 MiB | 3.20 MiB/s');
      progress = GitCloneSource.applyProgressLine(
          progress, 'Resolving deltas:  12% (150/1200)');

      expect(progress.phase, ClonePhase.resolving);
      // Процент дельт не подменяет процент скачивания.
      expect(progress.fraction, isNull);
    });
  });

  group('Клонирование', () {
    late Directory origin;
    late Directory root;

    setUp(() {
      origin = _sourceRepo();
      root = Directory.systemTemp.createTempSync('spok-clones');
    });

    tearDown(() {
      origin.deleteSync(recursive: true);
      if (root.existsSync()) root.deleteSync(recursive: true);
    });

    test('спека клонируется, путь отдаётся последним событием', () async {
      final source = GitCloneSource(root: root);

      final events = await source.clone(origin.path).toList();

      final last = events.last;
      expect(last.isDone, isTrue, reason: last.failureDetail);
      expect(Directory(p.join(last.path, '.git')).existsSync(), isTrue);
      expect(File(p.join(last.path, 'workspace.yaml')).existsSync(), isTrue);
    });

    test('уже склонированная спека того же адреса обновляется, '
        'а не клонируется заново', () async {
      final source = GitCloneSource(root: root);
      final first = (await source.clone(origin.path).toList()).last;

      final second = (await source.clone(origin.path).toList()).last;

      expect(second.isDone, isTrue, reason: second.failureDetail);
      expect(second.path, first.path);
    });

    test('каталог занят чужим содержимым — не трогаем его', () async {
      final occupied =
          Directory(p.join(root.path, GitCloneSource.slugOf(origin.path)))
            ..createSync(recursive: true);
      File(p.join(occupied.path, 'чужое.txt')).writeAsStringSync('не моё');

      final events =
          await GitCloneSource(root: root).clone(origin.path).toList();

      expect(events.last.failure, CloneFailure.directoryInUse);
      // Чужой файл на месте: молча сносить каталог нельзя.
      expect(File(p.join(occupied.path, 'чужое.txt')).existsSync(), isTrue);
    });

    test('адреса нет — ошибка разобрана, обломков не осталось', () async {
      final missing = p.join(origin.parent.path, 'нет-такого-репозитория');

      final events =
          await GitCloneSource(root: root).clone(missing).toList();

      expect(events.last.isFailed, isTrue);
      expect(events.last.failureDetail, isNotEmpty);
      // Недокачанный каталог убран — вторая попытка не упрётся в «занят».
      expect(
          Directory(p.join(root.path, GitCloneSource.slugOf(missing)))
              .existsSync(),
          isFalse);
    });
  });
}
