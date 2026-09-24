import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/platform/app_paths.dart';
import '../../domain/entities/secret_backend.dart';
import 'executable_locator.dart';

/// Системное хранилище секретов: токены и пароли спеки не должны лежать
/// открытым текстом ни в репозитории, ни в конфиге приложения.
///
/// `.env` в клоне остаётся, но становится производным файлом: его
/// пересобирает [EnvMaterializer] из значений этого хранилища. Источник
/// правды — здесь.
///
/// Хранилища может не быть вовсе: на Linux без keyring-демона `secret-tool`
/// либо отсутствует, либо падает при первой же записи. Тогда работаем
/// файлом с правами `0600` и не делаем вид, что секреты в связке ключей, —
/// [backend] возвращает [SecretBackend.file], и экран это показывает.
class SecretStore {
  /// Имя службы в связке ключей: под ним человек находит наши записи
  /// в Keychain Access.
  static const service = 'Spok';

  final Directory _fallbackDir;

  SecretBackend? _backend;

  SecretStore({Directory? fallbackDir})
      : _fallbackDir = fallbackDir ?? _defaultFallbackDir();

  /// Хранилище заведомо файловое. Нужно тестам: писать в настоящую связку
  /// ключей машины они не имеют права — записи останутся там после прогона.
  SecretStore.inFile(Directory fallbackDir) : _fallbackDir = fallbackDir {
    _backend = SecretBackend.file;
  }

  static Directory _defaultFallbackDir() => AppPaths.data();

  /// Учётная запись в связке: секреты разных спек не должны сливаться
  /// в одну запись — у каждой спеки свой токен к одному и тому же GitLab.
  static String account(String projectPath, String key) {
    final slug = p.basename(projectPath).trim();
    return slug.isEmpty ? key : '$slug:$key';
  }

  /// Какое хранилище используется. Проверяется один раз за запуск:
  /// связка ключей не появляется и не исчезает посреди работы.
  Future<SecretBackend> backend() async =>
      _backend ??= await _detectBackend();

  Future<SecretBackend> _detectBackend() async {
    if (Platform.isMacOS && ExecutableLocator.locate('security') != null) {
      return SecretBackend.keychain;
    }
    if (Platform.isLinux && ExecutableLocator.locate('secret-tool') != null) {
      // Бинарник есть, но без запущенного демона он падает на первой же
      // операции — проверяем чтением, оно безобидно.
      final probe = await _run('secret-tool',
          ['lookup', 'service', service, 'account', '__probe__']);
      // 1 — «не найдено», это рабочий ответ. Иначе демона нет.
      if (probe != null && (probe.exitCode == 0 || probe.exitCode == 1)) {
        return SecretBackend.libsecret;
      }
    }
    return SecretBackend.file;
  }

  /// Значение секрета; null — такого ключа в хранилище нет.
  Future<String?> read(String account) async =>
      switch (await backend()) {
        SecretBackend.keychain => await _keychainRead(account),
        SecretBackend.libsecret => await _libsecretRead(account),
        SecretBackend.file => _fileRead(account),
      };

  /// Пишет секрет. Пустое значение удаляет запись: «ключ не заполнен» —
  /// это отсутствие записи, а не пустая строка в хранилище.
  Future<void> write(String account, String value) async {
    if (value.isEmpty) return delete(account);
    final stored = switch (await backend()) {
      SecretBackend.keychain => await _keychainWrite(account, value),
      SecretBackend.libsecret => await _libsecretWrite(account, value),
      SecretBackend.file => false,
    };
    // Хранилище отказало посреди работы — значение не теряем, но и
    // молчать нельзя: дальше backend() честно отвечает «файл».
    if (!stored) {
      _backend = SecretBackend.file;
      _fileWrite(account, value);
    }
  }

  Future<void> delete(String account) async {
    switch (await backend()) {
      case SecretBackend.keychain:
        await _run('security', [
          'delete-generic-password',
          '-s', service,
          '-a', account,
        ]);
      case SecretBackend.libsecret:
        await _run('secret-tool',
            ['clear', 'service', service, 'account', account]);
      case SecretBackend.file:
        break;
    }
    // Файл чистим всегда: в нём могли остаться значения с тех пор,
    // когда хранилища ещё не было.
    _fileWrite(account, '');
  }

  // ─── macOS Keychain ────────────────────────────────────────────────────

  Future<String?> _keychainRead(String account) async {
    final result = await _run('security', [
      'find-generic-password',
      '-s', service,
      '-a', account,
      '-w',
    ]);
    // 44 — записи нет; остальные ненулевые коды тоже значат «нечего отдать».
    if (result == null || result.exitCode != 0) return null;
    final value = (result.stdout as String).trimRight();
    return value.isEmpty ? null : value;
  }

  Future<bool> _keychainWrite(String account, String value) async {
    // `-w` без значения заставляет security прочитать секрет со stdin:
    // в argv секрет виден в `ps` любому процессу того же пользователя.
    // Значение отправляем дважды — утилита может спросить подтверждение;
    // лишняя строка, если подтверждения нет, никуда не уходит.
    final piped = await _run(
      'security',
      ['add-generic-password', '-U', '-s', service, '-a', account, '-w'],
      stdin: '$value\n$value\n',
    );
    if (piped != null && piped.exitCode == 0) return true;
    // Старые сборки security stdin не читают — тогда остаётся argv.
    final direct = await _run('security', [
      'add-generic-password',
      '-U',
      '-s', service,
      '-a', account,
      '-w', value,
    ]);
    return direct != null && direct.exitCode == 0;
  }

  // ─── Linux Secret Service ──────────────────────────────────────────────

  Future<String?> _libsecretRead(String account) async {
    final result = await _run(
        'secret-tool', ['lookup', 'service', service, 'account', account]);
    if (result == null || result.exitCode != 0) return null;
    final value = (result.stdout as String).trimRight();
    return value.isEmpty ? null : value;
  }

  Future<bool> _libsecretWrite(String account, String value) async {
    final result = await _run(
      'secret-tool',
      [
        'store',
        '--label=$service · $account',
        'service', service,
        'account', account,
      ],
      stdin: value,
    );
    return result != null && result.exitCode == 0;
  }

  // ─── Файловый запасной вариант ─────────────────────────────────────────

  File get _fallbackFile => File(p.join(_fallbackDir.path, 'secrets.env'));

  Map<String, String> _fileValues() {
    final file = _fallbackFile;
    if (!file.existsSync()) return {};
    final pattern = RegExp(r'^([^=]+)=(.*)$');
    return {
      for (final line in file.readAsLinesSync())
        if (pattern.firstMatch(line.trim()) case final match?)
          match.group(1)!: _decode(match.group(2)!),
    };
  }

  String? _fileRead(String account) {
    final value = _fileValues()[account];
    return (value == null || value.isEmpty) ? null : value;
  }

  void _fileWrite(String account, String value) {
    final values = _fileValues();
    if (value.isEmpty) {
      if (!values.containsKey(account)) return;
      values.remove(account);
    } else {
      values[account] = value;
    }
    final file = _fallbackFile;
    file.parent.createSync(recursive: true);
    final lines = [
      '# Секреты спек. Файл — запасной вариант: связки ключей на этой',
      '# машине нет. Значения закодированы base64, это не шифрование.',
      for (final entry in values.entries)
        '${entry.key}=${_encode(entry.value)}',
    ];
    // Пишем через временный файл: оборванная запись не оставит человека
    // без ключей посреди рабочего дня.
    final temporary = File('${file.path}.tmp');
    temporary.writeAsStringSync('${lines.join('\n')}\n', flush: true);
    temporary.renameSync(file.path);
    _restrictAccess(file);
  }

  /// Права `0600`: файл с токенами не должен читаться остальными
  /// пользователями машины.
  void _restrictAccess(File file) {
    if (Platform.isWindows) return;
    try {
      Process.runSync(ExecutableLocator.resolve('chmod'), ['600', file.path]);
    } catch (_) {
      // Не вышло — значение всё равно записано; честность про хранилище
      // обеспечивает backend(), а не права файла.
    }
  }

  /// base64 прячет секрет от случайного взгляда в редакторе и спасает
  /// от переносов строк внутри значения. Защитой это не считается.
  static String _encode(String value) => base64.encode(utf8.encode(value));

  static String _decode(String value) {
    try {
      return utf8.decode(base64.decode(value));
    } catch (_) {
      return value; // строка из тех времён, когда кодирования не было
    }
  }

  Future<ProcessResult?> _run(String executable, List<String> arguments,
      {String? stdin}) async {
    final path = ExecutableLocator.locate(executable);
    if (path == null) return null;
    try {
      if (stdin == null) return await Process.run(path, arguments);
      final process = await Process.start(path, arguments);
      process.stdin.write(stdin);
      await process.stdin.flush();
      await process.stdin.close();
      final out = await process.stdout.transform(utf8.decoder).join();
      final err = await process.stderr.transform(utf8.decoder).join();
      return ProcessResult(process.pid, await process.exitCode, out, err);
    } catch (_) {
      return null; // утилиты нет или её нечем запустить
    }
  }
}
