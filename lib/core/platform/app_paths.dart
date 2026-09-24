import 'dart:io';

import 'package:path/path.dart' as p;

/// Где приложение держит свои файлы: конфиг, клоны спек, запасное
/// хранилище секретов.
///
/// Раскладка у каждой системы своя, и подставлять macOS-путь на Linux
/// нельзя: `~/Library/Application Support` там просто чужой каталог,
/// который не видит ни бэкап, ни файловый менеджер. Поэтому место
/// выбирается один раз здесь, а источники (`AppConfigSource`,
/// `SecretStore`, `GitCloneSource`) спрашивают его, а не собирают путь
/// сами.
///
/// Разделение конфига и данных — требование XDG: настройки уезжают
/// в бэкап и в dotfiles, клоны спек на гигабайты — нет. На macOS обе
/// роли исполняет `Application Support`: своего каталога настроек там нет.
///
/// Система и окружение — поля, а не обращения к `Platform` по месту:
/// раскладку всех трёх систем надо проверять на одной, иначе Linux-путь
/// увидят только на Linux, то есть никогда.
class AppPaths {
  /// Имя каталога в системах, где каталоги приложений называются
  /// по-человечески (macOS, Windows).
  static const appDirName = 'Spok';

  /// Имя каталога в XDG-раскладке: соседи по `~/.config` — в нижнем
  /// регистре, выделяться незачем.
  static const unixDirName = 'spok';

  /// Каталог конфига до переименования приложения: конфиг оттуда
  /// переносится при первом обращении (см. `AppConfigSource`).
  static const legacyAppDirName = 'PlatformConsole';

  /// Полная подмена корня — одной переменной на всё: конфиг, секреты
  /// и клоны уезжают внутрь неё. Нужна прогонам на чужой машине, где
  /// портить настоящие настройки нельзя.
  static const homeOverrideKey = 'SPOK_HOME';

  /// Значения `Platform.operatingSystem`: `macos`, `linux`, `windows`.
  final String operatingSystem;
  final Map<String, String> environment;

  const AppPaths({required this.operatingSystem, required this.environment});

  /// Раскладка машины, на которой приложение запущено.
  AppPaths.host()
      : operatingSystem = Platform.operatingSystem,
        environment = Platform.environment;

  bool get _isMac => operatingSystem == 'macos';
  bool get _isWindows => operatingSystem == 'windows';

  /// Настройки: `.env` приложения.
  Directory get configDir {
    final override = _override();
    if (override != null) return Directory(p.join(override, 'config'));
    if (_isMac) return _macSupport(appDirName);
    if (_isWindows) return _windows('APPDATA', appDirName);
    return Directory(p.join(_xdg('XDG_CONFIG_HOME', ['.config']), unixDirName));
  }

  /// Данные: клоны спек и запасной файл секретов.
  Directory get dataDir {
    final override = _override();
    if (override != null) return Directory(p.join(override, 'data'));
    if (_isMac) return _macSupport(appDirName);
    if (_isWindows) return _windows('LOCALAPPDATA', appDirName);
    return Directory(
        p.join(_xdg('XDG_DATA_HOME', ['.local', 'share']), unixDirName));
  }

  /// Куда складываются клоны спек.
  Directory get specsDir => Directory(p.join(dataDir.path, 'specs'));

  /// Конфиг прежней версии приложения — там же, где нынешний, но под
  /// старым именем. null, когда корень подменён: переносить нечего.
  Directory? get legacyConfigDir {
    if (_override() != null) return null;
    if (_isMac) return _macSupport(legacyAppDirName);
    if (_isWindows) return _windows('APPDATA', legacyAppDirName);
    return Directory(
        p.join(_xdg('XDG_CONFIG_HOME', ['.config']), legacyAppDirName));
  }

  /// Домашний каталог. Пустая строка вместо исключения: путь всё равно
  /// сложится, а ошибку человек увидит на записи файла — с именем файла,
  /// а не с трассировкой из глубины.
  String get homeDir =>
      environment['HOME'] ?? environment['USERPROFILE'] ?? '';

  String? _override() {
    final value = environment[homeOverrideKey];
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  Directory _macSupport(String name) =>
      Directory(p.join(homeDir, 'Library', 'Application Support', name));

  /// `%APPDATA%` есть у всякого сеанса Windows; если переменной нет
  /// (служба, урезанное окружение) — собираем путь от дома сами.
  Directory _windows(String variable, String name) {
    final base = environment[variable];
    if (base != null && base.isNotEmpty) return Directory(p.join(base, name));
    final roaming = variable == 'APPDATA' ? 'Roaming' : 'Local';
    return Directory(p.join(homeDir, 'AppData', roaming, name));
  }

  /// XDG-каталог: переменная, если задана абсолютным путём, иначе
  /// значение по умолчанию от дома. Относительный путь в XDG-переменной
  /// спецификацией не определён — игнорируем, как это делают
  /// остальные приложения.
  String _xdg(String variable, List<String> fallback) {
    final value = environment[variable];
    if (value != null && p.isAbsolute(value)) return value;
    return p.joinAll([homeDir, ...fallback]);
  }

  /// Раскладка этой машины — короткие обращения для источников.
  static Directory config() => AppPaths.host().configDir;

  static Directory data() => AppPaths.host().dataDir;

  static Directory specs() => AppPaths.host().specsDir;

  static Directory? legacyConfig() => AppPaths.host().legacyConfigDir;

  static String home() => AppPaths.host().homeDir;
}
