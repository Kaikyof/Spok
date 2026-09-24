import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/platform/app_paths.dart';

/// Поиск внешних утилит по абсолютному пути.
///
/// Приложение, запущенное из Finder (.app из DMG), наследует урезанный
/// PATH — `/usr/bin:/bin:/usr/sbin:/sbin`. Homebrew, nvm и volta в него
/// не входят, поэтому `Process.run('node', …)` падает с
/// «ProcessException: No such file or directory». Ищем бинарник сами:
/// сначала в PATH процесса, затем в типовых местах установки.
class ExecutableLocator {
  static final _cache = <String, String?>{};

  /// Типовые места установки, которых может не быть в PATH процесса.
  /// Homebrew — и по пути Apple Silicon, и по старому Intel'овому;
  /// `/opt/local/bin` — MacPorts; остальное общее для macOS и Linux.
  static const _extraDirectories = [
    '/opt/homebrew/bin',
    '/usr/local/bin',
    '/usr/bin',
    '/bin',
    '/opt/local/bin',
    '/snap/bin',
  ];

  /// Абсолютный путь к [name] или null, если утилита не найдена.
  static String? locate(String name) =>
      _cache.putIfAbsent(name, () => _search(name));

  /// Путь к [name]; если не нашли — само имя, чтобы ошибка запуска
  /// осталась прежней и её было видно в журнале команд.
  static String resolve(String name) => locate(name) ?? name;

  static String? _search(String name) {
    for (final directory in _searchPath()) {
      if (directory.isEmpty) continue;
      final candidate = p.join(directory, name);
      if (_isExecutable(candidate)) return candidate;
    }
    return null;
  }

  static Iterable<String> _searchPath() sync* {
    // Разделитель PATH у Windows свой; каталоги ниже — unix'овые,
    // на Windows их просто не окажется на диске.
    yield* (Platform.environment['PATH'] ?? '')
        .split(Platform.isWindows ? ';' : ':');
    yield* _extraDirectories;
    final home = AppPaths.home();
    if (home.isEmpty) return;
    yield p.join(home, '.local', 'bin');
    yield p.join(home, '.volta', 'bin');
    yield p.join(home, '.bun', 'bin');
    // nvm и fnm держат по каталогу на версию — берём самые свежие.
    yield* _versionedBins(p.join(home, '.nvm', 'versions', 'node'));
    // fnm: каталог версий у macOS и Linux разный.
    yield* _versionedBins(
        p.join(home, 'Library', 'Application Support', 'fnm', 'node-versions'));
    yield* _versionedBins(
        p.join(home, '.local', 'share', 'fnm', 'node-versions'));
  }

  /// Каталоги `bin` версионных менеджеров, от новой версии к старой.
  static Iterable<String> _versionedBins(String root) {
    final directory = Directory(root);
    if (!directory.existsSync()) return const [];
    final versions = directory
        .listSync()
        .whereType<Directory>()
        .map((entry) => entry.path)
        .toList()
      ..sort(_compareVersions);
    return versions.reversed.expand(
        (path) => [p.join(path, 'bin'), p.join(path, 'installation', 'bin')]);
  }

  /// Сравнение `v24.15.0` по числам, а не по алфавиту: иначе v9 > v24.
  static int _compareVersions(String left, String right) {
    final numbers = RegExp(r'\d+');
    final a = numbers.allMatches(p.basename(left)).map((m) => m.group(0)!);
    final b = numbers.allMatches(p.basename(right)).map((m) => m.group(0)!);
    final pairs = [
      ...a.map(int.parse),
      ...List.filled((b.length - a.length).clamp(0, 9), 0),
    ];
    final other = [
      ...b.map(int.parse),
      ...List.filled((a.length - b.length).clamp(0, 9), 0),
    ];
    for (var index = 0; index < pairs.length; index++) {
      final diff = pairs[index].compareTo(other[index]);
      if (diff != 0) return diff;
    }
    return 0;
  }

  static bool _isExecutable(String path) {
    final file = File(path);
    if (!file.existsSync()) return false;
    return FileStat.statSync(path).mode & 0x49 != 0; // любой бит x
  }
}
