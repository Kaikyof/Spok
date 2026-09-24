import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/entities/clone_progress.dart';
import '../../domain/entities/operation_progress.dart';
import 'executable_locator.dart';

/// Клонирование спеки по git-URL.
///
/// Человек получает ссылку на спеку своей команды и должен начать работать,
/// не открывая терминал (сводный документ, 4.1). Клонируем его же git —
/// значит, работают его ssh-ключи, его `~/.gitconfig` и его credential
/// helper, и ничего из этого приложение у него не спрашивает.
class GitCloneSource {
  /// Куда складываются клоны спек. Каталог тот же, где лежит конфиг
  /// приложения: одно место на все данные Spok.
  static Directory defaultRoot() {
    final home = Platform.environment['HOME'] ?? '';
    return Directory(
        p.join(home, 'Library', 'Application Support', 'Spok', 'specs'));
  }

  final Directory root;

  Process? _process;

  /// Каталог, созданный этим клоном: при отмене и ошибке его надо убрать,
  /// иначе следующая попытка упрётся в «каталог занят» нашими же обломками.
  Directory? _created;

  var _cancelled = false;

  GitCloneSource({Directory? root}) : root = root ?? defaultRoot();

  /// Имя каталога из адреса: `git@host:team/avelacom-platform.git` →
  /// `avelacom-platform`.
  static String slugOf(String url) {
    final trimmed = url.trim().replaceAll(RegExp(r'[/\s]+$'), '');
    final tail = trimmed.split(RegExp(r'[/:]')).lastOrNull ?? '';
    final slug = tail.replaceAll(RegExp(r'\.git$'), '');
    return slug.isEmpty ? 'spec' : slug;
  }

  /// Похоже ли это на git-адрес, а не на локальный путь.
  static bool looksLikeUrl(String value) {
    final trimmed = value.trim();
    return RegExp(r'^(https?|ssh|git)://').hasMatch(trimmed) ||
        RegExp(r'^[^/\s]+@[^/\s]+:').hasMatch(trimmed);
  }

  /// Клонирует [url] и отдаёт ход работы событиями.
  ///
  /// Каталог уже занят нашим же клоном того же адреса — обновляем его
  /// вместо повторного клонирования: чаще всего человек подключает спеку,
  /// которая у него уже есть.
  Stream<CloneProgress> clone(String url, {String? ref}) async* {
    _cancelled = false;
    final git = ExecutableLocator.locate('git');
    if (git == null) {
      yield const CloneProgress(
          stage: OperationStage.failed, failure: CloneFailure.gitMissing);
      return;
    }
    final target = Directory(p.join(root.path, slugOf(url)));
    final existing = await _existingClone(git, target, url);
    if (existing != null) {
      yield* existing ? _pull(git, target) : _occupied(target);
      return;
    }

    root.createSync(recursive: true);
    _created = target;
    yield const CloneProgress(
        stage: OperationStage.running, phase: ClonePhase.starting);
    yield* _run(
      git,
      [
        'clone',
        '--progress',
        if (ref != null && ref.isNotEmpty) ...['--branch', ref],
        url,
        target.path,
      ],
      target: target,
    );
  }

  /// Обновляет уже склонированную спеку.
  Stream<CloneProgress> _pull(String git, Directory target) {
    // Каталог не наш — удалять его при ошибке нельзя.
    _created = null;
    return _run(git, ['-C', target.path, 'pull', '--progress', '--ff-only'],
        target: target, updating: true);
  }

  Stream<CloneProgress> _occupied(Directory target) async* {
    yield CloneProgress(
      stage: OperationStage.failed,
      failure: CloneFailure.directoryInUse,
      failureDetail: target.path,
    );
  }

  /// `true` — в каталоге наш клон того же адреса, `false` — каталог занят
  /// чем-то чужим, `null` — каталога нет и можно клонировать.
  Future<bool?> _existingClone(
      String git, Directory target, String url) async {
    if (!target.existsSync()) return null;
    if (target.listSync().isEmpty) {
      // Пустой каталог клонированию не мешает, но git ругается — уберём.
      target.deleteSync();
      return null;
    }
    try {
      final remote = await Process.run(
          git, ['-C', target.path, 'remote', 'get-url', 'origin']);
      if (remote.exitCode != 0) return false;
      return _sameRemote((remote.stdout as String).trim(), url);
    } catch (_) {
      return false;
    }
  }

  /// Один и тот же репозиторий, записанный по-разному: ssh и https формы
  /// одного адреса — это не повод клонировать его второй раз.
  static bool _sameRemote(String left, String right) {
    String normalize(String url) => url
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'^(https?|ssh|git)://'), '')
        .replaceAll(RegExp(r'^[^/@\s]+@'), '')
        .replaceAll(':', '/')
        .replaceAll(RegExp(r'\.git$'), '')
        .replaceAll(RegExp(r'/+$'), '');
    return normalize(left) == normalize(right);
  }

  Stream<CloneProgress> _run(String git, List<String> arguments,
      {required Directory target, bool updating = false}) async* {
    var current = CloneProgress(
        stage: OperationStage.running, updating: updating);
    final errors = <String>[];
    final Process process;
    try {
      process = await Process.start(git, arguments,
          environment: const {
            // Пароль спрашивать некому: приложение не терминал, и
            // интерактивный запрос git просто повесил бы клонирование.
            'GIT_TERMINAL_PROMPT': '0',
          },
          includeParentEnvironment: true);
    } on ProcessException catch (error) {
      _cleanUp();
      yield CloneProgress(
        stage: OperationStage.failed,
        failure: CloneFailure.gitMissing,
        failureDetail: error.message,
        updating: updating,
      );
      return;
    }
    _process = process;
    // stdout не нужен, но и оставлять его непрочитанным нельзя: полный
    // буфер остановил бы сам git.
    final stdoutDrained = process.stdout.drain<void>();

    // git пишет прогресс в stderr и перерисовывает строку через `\r` —
    // режем по обоим переводам, иначе проценты придут одним куском
    // в самом конце.
    final lines = process.stderr
        .transform(utf8.decoder)
        .transform(const _LineSplitter());
    await for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (_looksLikeError(trimmed)) errors.add(trimmed);
      current = applyProgressLine(current, trimmed);
      yield current;
    }

    final exitCode = await process.exitCode;
    await stdoutDrained;
    _process = null;

    if (_cancelled) {
      _cleanUp();
      yield current.copyWith(
          stage: OperationStage.failed,
          failure: () => CloneFailure.cancelled,
          failureDetail: '');
      return;
    }
    if (exitCode != 0) {
      _cleanUp();
      final detail = errors.join('\n');
      yield current.copyWith(
        stage: OperationStage.failed,
        failure: () => classify(detail),
        failureDetail: detail,
      );
      return;
    }
    _created = null;
    yield current.copyWith(
        stage: OperationStage.done,
        phase: ClonePhase.done,
        fraction: () => 1,
        path: target.path);
  }

  /// Отменяет клонирование: процесс убиваем, недокачанный каталог убираем.
  void cancel() {
    _cancelled = true;
    _process?.kill();
  }

  /// Недоделанный клон не оставляем: иначе следующая попытка упрётся
  /// в «каталог занят» нашими же обломками.
  void _cleanUp() {
    final created = _created;
    _created = null;
    if (created == null || !created.existsSync()) return;
    try {
      created.deleteSync(recursive: true);
    } catch (_) {
      // Не вышло — каталог останется, и это честнее, чем стереть лишнее.
    }
  }

  /// Участки общей полосы по этапам git. Проценты у каждого этапа свои,
  /// поэтому каждый занимает свой отрезок: без этого полоса доходила
  /// до конца на «Counting objects» и уезжала назад на «Receiving».
  ///
  /// Границы взяты по тому, сколько этап занимает по времени на обычной
  /// спеке: скачивание — почти всё, остальное по краям.
  static const _bands = <ClonePhase, (double, double)>{
    ClonePhase.starting: (0, 0),
    ClonePhase.counting: (0, 0.08),
    ClonePhase.compressing: (0.08, 0.20),
    ClonePhase.receiving: (0.20, 0.85),
    ClonePhase.resolving: (0.85, 0.95),
    ClonePhase.checkout: (0.95, 1),
    ClonePhase.done: (1, 1),
  };

  /// Разбор строки прогресса git. Открыт для теста: формат этих строк —
  /// внешний контракт, и проверять его надо напрямую.
  static CloneProgress applyProgressLine(CloneProgress current, String line) {
    final percent = RegExp(r'(\d{1,3})%').firstMatch(line);
    final volume = RegExp(r'(\d+[.,]?\d*\s*[KMG]i?B)(?!/s)').firstMatch(line);
    final speed = RegExp(r'(\d+[.,]?\d*\s*[KMG]i?B/s)').firstMatch(line);
    final phase = _phaseOf(line) ?? current.phase;
    final (from, to) = _bands[phase]!;
    // Внутри своего участка двигаемся по проценту этапа; процентов нет —
    // стоим на его начале.
    final withinPhase =
        percent == null ? 0.0 : int.parse(percent.group(1)!) / 100;
    final overall = from + (to - from) * withinPhase.clamp(0.0, 1.0);
    return current.copyWith(
      phase: phase,
      // Полоса только растёт: git иногда возвращается к более раннему
      // этапу (например, доснимает объекты), и рывок назад читался бы
      // как сбой.
      fraction: () => overall < (current.fraction ?? 0)
          ? current.fraction
          : overall,
      volume: volume?.group(1) ?? current.volume,
      speed: speed?.group(1) ?? current.speed,
      line: line,
    );
  }

  /// Этап по строке git; null — строка не про этап (её причина другая).
  static ClonePhase? _phaseOf(String line) {
    final text = line.replaceFirst(RegExp(r'^remote:\s*'), '');
    return switch (text) {
      _ when text.startsWith('Receiving objects') => ClonePhase.receiving,
      _ when text.startsWith('Resolving deltas') => ClonePhase.resolving,
      _ when text.startsWith('Compressing objects') => ClonePhase.compressing,
      _ when text.startsWith('Counting objects') ||
              text.startsWith('Enumerating objects') =>
        ClonePhase.counting,
      _ when text.startsWith('Updating files') ||
              text.startsWith('Checking out files') =>
        ClonePhase.checkout,
      _ => null,
    };
  }

  /// Строки прогресса ошибками не считаем: git пишет в stderr и то и другое.
  static bool _looksLikeError(String line) =>
      !RegExp(r'^(remote:\s*)?(Receiving|Resolving|Counting|Compressing|'
              r'Cloning into|Enumerating|Updating files|Total|From |Already up)')
          .hasMatch(line) &&
      !line.startsWith('Note:');

  /// Причина отказа по выводу git. Тексты git стабильнее, чем коды выхода:
  /// код у него всегда 128.
  static CloneFailure classify(String output) {
    final text = output.toLowerCase();
    if (text.contains('permission denied') && text.contains('publickey')) {
      return CloneFailure.accessDenied;
    }
    if (text.contains('authentication failed') ||
        text.contains('invalid username or password') ||
        text.contains('terminal prompts disabled')) {
      return CloneFailure.authFailed;
    }
    if (text.contains('already exists and is not an empty directory')) {
      return CloneFailure.directoryInUse;
    }
    if (text.contains('repository not found') ||
        text.contains('does not appear to be a git repository') ||
        text.contains('not found')) {
      return CloneFailure.repoNotFound;
    }
    if (text.contains('could not resolve host') ||
        text.contains('connection timed out') ||
        text.contains('network is unreachable') ||
        text.contains('connection refused')) {
      return CloneFailure.networkUnreachable;
    }
    if (text.contains('permission denied')) return CloneFailure.accessDenied;
    return CloneFailure.unknown;
  }
}

/// Разбиение вывода git на строки по `\n` и `\r`: прогресс он перерисовывает
/// возвратом каретки, и обычный `LineSplitter` отдал бы его одним куском.
class _LineSplitter extends StreamTransformerBase<String, String> {
  const _LineSplitter();

  @override
  Stream<String> bind(Stream<String> stream) async* {
    var buffer = '';
    await for (final chunk in stream) {
      buffer += chunk;
      final parts = buffer.split(RegExp(r'[\r\n]'));
      buffer = parts.removeLast();
      yield* Stream.fromIterable(parts);
    }
    if (buffer.isNotEmpty) yield buffer;
  }
}
