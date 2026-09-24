import '../../domain/entities/env_field.dart';
import '../../domain/entities/secret_backend.dart';
import 'platform_files_source.dart';
import 'secret_store.dart';

/// Итог сборки `.env`: что именно произошло с секретами спеки.
class EnvMaterialization {
  /// Где лежат секреты — связка ключей или файл.
  final SecretBackend backend;

  /// `.env` попадает под .gitignore спеки.
  final bool ignoredByGit;

  /// Сколько секретов подставлено в файл из хранилища.
  final int restored;

  /// Сколько секретов перенесено из `.env` в хранилище при этом запуске.
  final int imported;

  const EnvMaterialization({
    required this.backend,
    required this.ignoredByGit,
    this.restored = 0,
    this.imported = 0,
  });
}

/// Собирает `.env` в клоне спеки.
///
/// Файл нужен скриптам спеки и агентным сессиям — убрать его нельзя.
/// Но источником правды он быть перестаёт: секреты живут в [SecretStore],
/// а `.env` пересобирается из них при открытии проекта и после сохранения
/// формы ключей. Клон можно удалить и склонировать заново — ключи
/// вернутся на место сами.
class EnvMaterializer {
  final PlatformFilesSource files;
  final SecretStore secrets;

  EnvMaterializer(this.files, {SecretStore? secrets})
      : secrets = secrets ?? SecretStore();

  String get _projectPath => files.path;

  /// Пересобирает `.env` спеки из хранилища секретов.
  ///
  /// Заодно переносит в хранилище секреты, которые лежат в файле, а в нём
  /// ещё не сохранены: у людей, работавших до появления хранилища, ключи
  /// уже введены, и повторно спрашивать их незачем.
  Future<EnvMaterialization> materialize() async {
    final env = files.loadEnv();
    final declared = files.loadEnvExampleKeys().map((key) => key.key);
    // Ключи из файла тоже берём: спека могла объявить не всё, что нужно.
    final keys = {...declared, ...env.keys}.where(EnvField.isSecretKey);

    var restored = 0;
    var imported = 0;
    final values = <String, String>{};
    for (final key in keys) {
      final account = SecretStore.account(_projectPath, key);
      final stored = await secrets.read(account);
      final inFile = env[key] ?? '';
      if (stored != null && stored.isNotEmpty) {
        if (stored != inFile) {
          values[key] = stored;
          restored++;
        }
        continue;
      }
      if (inFile.isNotEmpty) {
        await secrets.write(account, inFile);
        imported++;
      }
    }
    if (values.isNotEmpty) await files.writeEnv(values);
    return EnvMaterialization(
      backend: await secrets.backend(),
      ignoredByGit: await files.envIgnoredByGit(),
      restored: restored,
      imported: imported,
    );
  }

  /// Сохраняет форму ключей: секреты — в хранилище, остальное — в `.env`,
  /// затем собирает файл целиком.
  ///
  /// Секреты пишутся и в файл тоже: скрипты спеки читают только его.
  /// Разница в том, что файл теперь производный — его потеря не стоит
  /// человеку повторного похода за токенами.
  Future<EnvMaterialization> save(Map<String, String> values) async {
    for (final entry in values.entries) {
      if (!EnvField.isSecretKey(entry.key)) continue;
      await secrets.write(
          SecretStore.account(_projectPath, entry.key), entry.value.trim());
    }
    await files.writeEnv(values);
    return EnvMaterialization(
      backend: await secrets.backend(),
      ignoredByGit: await files.envIgnoredByGit(),
    );
  }

  /// Забывает секреты спеки — нужно при удалении проекта вместе с клоном.
  Future<void> forget() async {
    final keys = {
      ...files.loadEnvExampleKeys().map((key) => key.key),
      ...files.loadEnv().keys,
    }.where(EnvField.isSecretKey);
    for (final key in keys) {
      await secrets.delete(SecretStore.account(_projectPath, key));
    }
  }
}
