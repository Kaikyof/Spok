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
    test('объём и скорость берутся так, как их напечатал git', () {
      final progress = GitCloneSource.applyProgressLine(
        CloneProgress.idle,
        'Receiving objects:  45% (1215/2700), 12.34 MiB | 3.20 MiB/s',
      );

      expect(progress.phase, ClonePhase.receiving);
      expect(progress.volume, '12.34 MiB');
      expect(progress.speed, '3.20 MiB/s');
    });

    test('процент — от всей работы, а не от этапа', () {
      final progress = GitCloneSource.applyProgressLine(CloneProgress.idle,
          'Receiving objects:  50% (1350/2700), 12.34 MiB | 3.20 MiB/s');

      // Скачивание занимает участок 0.20–0.85: половина скачанного — это
      // примерно половина всей работы, а не половина полосы с нуля.
      expect(progress.fraction, closeTo(0.525, 0.01));
    });

    test('полоса только растёт, как бы git ни переключал этапы', () {
      final lines = [
        'remote: Enumerating objects: 2700, done.',
        'remote: Counting objects:  50% (1350/2700)',
        'remote: Counting objects: 100% (2700/2700), done.',
        'remote: Compressing objects:  60% (900/1500)',
        'Receiving objects:   1% (27/2700), 240.00 KiB | 1.10 MiB/s',
        'Receiving objects:  99% (2673/2700), 39.00 MiB | 3.20 MiB/s',
        'Receiving objects: 100% (2700/2700), 40.00 MiB | 3.20 MiB/s',
        'Resolving deltas:  12% (150/1200)',
        'Resolving deltas: 100% (1200/1200), done.',
        'Updating files:  40% (800/2000)',
        'Updating files: 100% (2000/2000), done.',
      ];

      var progress = CloneProgress.idle;
      var previous = 0.0;
      for (final line in lines) {
        progress = GitCloneSource.applyProgressLine(progress, line);
        final fraction = progress.fraction ?? 0;
        expect(fraction, greaterThanOrEqualTo(previous),
            reason: 'полоса поехала назад на строке: $line');
        previous = fraction;
      }
      expect(progress.phase, ClonePhase.checkout);
      expect(previous, closeTo(1, 0.001));
    });

    test('строка не про этап не сбивает ни этап, ни полосу', () {
      var progress = GitCloneSource.applyProgressLine(CloneProgress.idle,
          'Receiving objects:  50% (1350/2700), 12.34 MiB | 3.20 MiB/s');
      final before = progress.fraction;

      progress = GitCloneSource.applyProgressLine(
          progress, 'Cloning into \'avelacom-platform\'...');

      expect(progress.phase, ClonePhase.receiving);
      expect(progress.fraction, before);
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

    test('прогресс по-настоящему движется и доходит до конца', () async {
      // `file://` заставляет git работать обычным транспортом, а не
      // хардлинками: только так в выводе появляются проценты скачивания,
      // ради которых прогресс и сделан.
      final events = await GitCloneSource(root: root)
          .clone('file://${origin.path}')
          .toList();

      final fractions = [for (final event in events) ?event.fraction];
      expect(fractions, isNotEmpty,
          reason: 'git не дал ни одного процента: ${events.last.line}');
      // Ни одного шага назад за всё клонирование.
      for (var index = 1; index < fractions.length; index++) {
        expect(fractions[index], greaterThanOrEqualTo(fractions[index - 1]));
      }
      expect(events.last.isDone, isTrue, reason: events.last.failureDetail);
      expect(events.last.fraction, 1);
      expect(events.any((event) => event.phase == ClonePhase.receiving), isTrue);
    });

    test('обновление уже склонированной спеки помечено как обновление',
        () async {
      final source = GitCloneSource(root: root);
      await source.clone(origin.path).toList();

      final events = await source.clone(origin.path).toList();

      expect(events.last.updating, isTrue);
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
