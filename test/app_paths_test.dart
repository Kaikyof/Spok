import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spok/core/platform/app_paths.dart';

/// Раскладку каждой системы проверяем на любой: `AppPaths` берёт систему
/// и окружение полями, а не спрашивает `Platform` по месту, — иначе
/// Linux-путь увидели бы только на Linux.
void main() {
  AppPaths paths(String os, Map<String, String> environment) =>
      AppPaths(operatingSystem: os, environment: environment);

  group('macOS', () {
    final mac = paths('macos', {'HOME': '/Users/ann'});
    const support = '/Users/ann/Library/Application Support';

    test('настройки и данные — в Application Support', () {
      expect(mac.configDir.path, '$support/Spok');
      expect(mac.dataDir.path, '$support/Spok');
      expect(mac.specsDir.path, '$support/Spok/specs');
    });

    test('прежний конфиг — рядом, под старым именем', () {
      expect(mac.legacyConfigDir!.path, '$support/PlatformConsole');
    });
  });

  group('Linux', () {
    test('по умолчанию XDG: настройки в .config, клоны в .local/share', () {
      final linux = paths('linux', {'HOME': '/home/ann'});
      expect(linux.configDir.path, '/home/ann/.config/spok');
      expect(linux.dataDir.path, '/home/ann/.local/share/spok');
      expect(linux.specsDir.path, '/home/ann/.local/share/spok/specs');
    });

    test('XDG-переменные перекрывают путь по умолчанию', () {
      final linux = paths('linux', {
        'HOME': '/home/ann',
        'XDG_CONFIG_HOME': '/mnt/cfg',
        'XDG_DATA_HOME': '/mnt/data',
      });
      expect(linux.configDir.path, '/mnt/cfg/spok');
      expect(linux.dataDir.path, '/mnt/data/spok');
    });

    test('относительный XDG-путь игнорируется: спецификация его не знает',
        () {
      final linux =
          paths('linux', {'HOME': '/home/ann', 'XDG_CONFIG_HOME': '../cfg'});
      expect(linux.configDir.path, '/home/ann/.config/spok');
    });
  });

  group('Windows', () {
    test('настройки в Roaming, данные в Local', () {
      final windows = paths('windows', {
        'USERPROFILE': r'C:\Users\ann',
        'APPDATA': r'C:\Users\ann\AppData\Roaming',
        'LOCALAPPDATA': r'C:\Users\ann\AppData\Local',
      });
      expect(windows.configDir.path, endsWith('Roaming${p.separator}Spok'));
      expect(windows.dataDir.path, endsWith('Local${p.separator}Spok'));
    });

    test('без %APPDATA% путь собирается от дома, а не падает', () {
      final windows = paths('windows', {'USERPROFILE': '/Users/ann'});
      expect(windows.configDir.path, '/Users/ann/AppData/Roaming/Spok');
      expect(windows.dataDir.path, '/Users/ann/AppData/Local/Spok');
    });
  });

  test('SPOK_HOME уводит внутрь себя и конфиг, и данные, и клоны', () {
    final overridden = paths('linux', {
      'HOME': '/home/ann',
      AppPaths.homeOverrideKey: '/tmp/spok-run',
    });
    expect(overridden.configDir.path, '/tmp/spok-run/config');
    expect(overridden.dataDir.path, '/tmp/spok-run/data');
    expect(overridden.specsDir.path, '/tmp/spok-run/data/specs');
    // Прежнего конфига у подменённого корня нет: переносить нечего.
    expect(overridden.legacyConfigDir, isNull);
  });

  test('без дома путь всё равно складывается: ошибку покажет запись файла',
      () {
    expect(paths('linux', {}).configDir.path, '.config/spok');
  });
}
